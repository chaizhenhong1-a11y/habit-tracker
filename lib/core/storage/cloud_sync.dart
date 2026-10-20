import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_store.dart';
import 'data_changes.dart';
import 'cloud_media.dart';
import 'points_ledger.dart';

enum SyncStatus { idle, syncing, synced, offline, conflict, tooLarge }

/// Versioned writes prevent a second device from silently replacing newer data.
class CloudSync extends ChangeNotifier {
  CloudSync({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;
  static final instance = CloudSync();
  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _debounce;
  Timer? _retry;
  BackupStore? _store;
  String? _uid;
  int _revision = 0;
  int _generation = 0;
  bool _dirty = false;
  bool _applying = false;
  bool _pushing = false;
  Completer<void>? _pushDone;
  Future<void>? _pullTask;
  DocumentSnapshot<Map<String, dynamic>>? _pendingRemote;
  bool _stopping = false;
  bool _active = false;
  int viewRevision = 0;
  SyncStatus status = SyncStatus.idle;
  String? get uid => _uid;
  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.doc('users/$_uid/state/main');
  String get _cacheKey => 'account_cache_$_uid';

  Future<void> enterGuest() async {
    await stop();
    final prefs = await SharedPreferences.getInstance();
    _store = BackupStore(prefs);
    final owner = prefs.getString('local_data_owner');
    if (owner != null && owner != 'guest') {
      final unclaimedGuest = prefs.getString('guest_cache_v1');
      await _store!.restore(
        unclaimedGuest == null
            ? _store!.empty()
            : _store!.validate(jsonDecode(unclaimedGuest)),
      );
    }
    await prefs.setString('local_data_owner', 'guest');
    status = SyncStatus.idle;
    viewRevision++;
    notifyListeners();
  }

  Future<bool> hasGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_data_owner') == 'guest' &&
        (Hive.box<dynamic>('habits').isNotEmpty ||
            PointsLedger.opened().totalEarned > 0 ||
            BackupStore.listKeys.any(
              (key) => (prefs.getStringList(key) ?? []).isNotEmpty,
            ));
  }

  Future<bool> needsGuestConfirmation(String targetUid) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString('last_signed_in_uid');
    return previous != null && previous != targetUid && await hasGuestData();
  }

  Future<void> start(User user, {bool importGuest = false}) async {
    await stop();
    final prefs = await SharedPreferences.getInstance();
    _store = BackupStore(prefs);
    final owner = prefs.getString('local_data_owner');
    final oldData = _store!.capture();
    if (owner == 'guest') {
      await prefs.setString('guest_cache_v1', jsonEncode(oldData));
    }
    if (owner == null) {
      // Keep a recovery copy regardless of whether the user elects to import it.
      if (!prefs.containsKey('legacy_data_backup_v1')) {
        await prefs.setString('legacy_data_backup_v1', jsonEncode(oldData));
      }
    }
    _uid = user.uid;
    final cacheText = prefs.getString(_cacheKey);
    final cache = cacheText == null ? null : jsonDecode(cacheText) as Map;
    Map<String, dynamic> data;
    _dirty = cache?['dirty'] == true;
    _revision = cache?['revision'] as int? ?? 0;
    status = SyncStatus.syncing;
    if (cache != null) {
      // Check-ins are durable in Hive even if the process ended before its
      // separate cloud queue checkpoint finished writing.
      data = owner == user.uid
          ? oldData
          : _store!.validate(jsonDecode(cache['payload'] as String));
      if (owner == user.uid && jsonEncode(oldData) != cache['payload']) {
        _dirty = true;
      }
    } else {
      try {
        final remote = await _document
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
        final content = remote.data();
        data = content == null
            ? _store!.empty()
            : await CloudMedia(user.uid, firestore: _firestore).download(
                _store!.validate(jsonDecode(content['payload'] as String)),
              );
        _revision = content?['revision'] as int? ?? 0;
        _dirty = content == null;
      } catch (_) {
        _uid = null;
        status = SyncStatus.offline;
        rethrow;
      }
    }
    if (owner == 'guest' && importGuest) {
      data = _store!.mergeGuest(data, oldData);
      _dirty = true;
    }
    _applying = true;
    try {
      await _store!.restore(data);
      await prefs.setString('local_data_owner', user.uid);
      // Credentials now belong exclusively to Firebase Authentication.
      await prefs.remove('registered_password');
      await prefs.remove('registered_username');
      await _saveCache();
      await prefs.setString('last_signed_in_uid', user.uid);
      if (owner == 'guest' && importGuest) await prefs.remove('guest_cache_v1');
    } finally {
      _applying = false;
    }
    _active = true;
    _subscriptions.add(
      Hive.box<dynamic>('habits').watch().listen((_) => changed()),
    );
    _subscriptions.add(
      Hive.box<dynamic>('points').watch().listen((_) => changed()),
    );
    _subscriptions.add(DataChanges.stream.listen((_) => changed()));
    _subscriptions.add(
      _document.snapshots().listen(
        _queueRemote,
        onError: (_) {
          status = SyncStatus.offline;
          notifyListeners();
        },
      ),
    );
    _retry = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    if (status != SyncStatus.conflict && status != SyncStatus.offline) {
      status = _dirty ? SyncStatus.syncing : SyncStatus.synced;
    }
    viewRevision++;
    notifyListeners();
    if (_dirty && status != SyncStatus.conflict) unawaited(flush());
  }

  void changed() {
    if (!_active || _applying) return;
    _dirty = true;
    _generation++;
    unawaited(_saveCache());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), flush);
  }

  Future<void> _saveCache() async {
    if (_store == null || _uid == null) return;
    final saved = await _store!.preferences.setString(
      _cacheKey,
      jsonEncode({
        'revision': _revision,
        'dirty': _dirty,
        'payload': jsonEncode(_store!.capture()),
      }),
    );
    if (!saved) throw StateError('Could not save account cache');
  }

  Future<void> flush() async {
    if (_pushing) {
      await _pushDone?.future;
      return;
    }
    if (!_active ||
        !_dirty ||
        _pushing ||
        _applying ||
        status == SyncStatus.conflict) {
      return;
    }
    final generation = _generation;
    final localData = _store!.capture();
    _pushing = true;
    _pushDone = Completer<void>();
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      final payload = jsonEncode(
        await CloudMedia(
          _uid!,
          firestore: _firestore,
        ).upload(localData).timeout(const Duration(seconds: 35)),
      );
      if (utf8.encode(payload).length > 800000) {
        status = SyncStatus.tooLarge;
        return;
      }
      final expected = _revision;
      await _firestore.runTransaction(
        (transaction) async {
          final remote = await transaction.get(_document);
          final current = remote.data()?['revision'] as int? ?? 0;
          if (current != expected) throw StateError('sync-conflict');
          transaction.set(_document, {
            'revision': expected + 1,
            'payload': payload,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
        timeout: const Duration(seconds: 15),
        maxAttempts: 3,
      );
      _revision = expected + 1;
      _dirty = generation != _generation;
      status = SyncStatus.synced;
      await _saveCache();
    } catch (error) {
      status = error is StateError && error.message == 'sync-conflict'
          ? SyncStatus.conflict
          : SyncStatus.offline;
    } finally {
      _pushing = false;
      _pushDone?.complete();
      _pushDone = null;
      notifyListeners();
    }
  }

  void _queueRemote(DocumentSnapshot<Map<String, dynamic>> remote) {
    if (_stopping || !_active) return;
    if (_pullTask != null) {
      _pendingRemote = remote;
      return;
    }
    _pullTask = _remoteChanged(remote);
    unawaited(
      _pullTask!.whenComplete(() {
        _pullTask = null;
        final pending = _pendingRemote;
        _pendingRemote = null;
        if (pending != null && !_stopping) _queueRemote(pending);
      }),
    );
  }

  Future<void> _remoteChanged(
    DocumentSnapshot<Map<String, dynamic>> remote,
  ) async {
    if (!_active ||
        _applying ||
        _pushing ||
        remote.metadata.hasPendingWrites ||
        remote.metadata.isFromCache) {
      return;
    }
    final data = remote.data();
    if (data == null) return;
    final revision = data['revision'] as int? ?? 0;
    if (revision <= _revision) return;
    if (_dirty) {
      status = SyncStatus.conflict;
      notifyListeners();
      return;
    }
    try {
      final owner = _uid;
      final downloaded = await CloudMedia(
        owner!,
        firestore: _firestore,
      ).download(_store!.validate(jsonDecode(data['payload'] as String)));
      if (!_active || _uid != owner) return;
      if (_dirty) {
        status = SyncStatus.conflict;
        notifyListeners();
        return;
      }
      await replaceLocal(downloaded, upload: false);
      _revision = revision;
      await _saveCache();
      status = SyncStatus.synced;
      notifyListeners();
    } catch (_) {
      status = SyncStatus.offline;
      notifyListeners();
    }
  }

  Future<void> replaceLocal(
    Map<String, dynamic> data, {
    bool upload = true,
  }) async {
    _applying = true;
    try {
      await _store!.restore(data);
      viewRevision++;
    } finally {
      _applying = false;
    }
    if (upload) changed();
    notifyListeners();
  }

  Future<void> useCloudVersion() async {
    if (_pushing) return;
    final remote = await _document.get(const GetOptions(source: Source.server));
    final data = remote.data();
    if (data == null) throw StateError('No cloud backup');
    await _store!.preferences.setString(
      'conflict_backup_$_uid',
      jsonEncode(_store!.capture()),
    );
    await replaceLocal(
      await CloudMedia(
        _uid!,
        firestore: _firestore,
      ).download(_store!.validate(jsonDecode(data['payload'] as String))),
      upload: false,
    );
    _revision = data['revision'] as int;
    _dirty = false;
    status = SyncStatus.synced;
    await _saveCache();
    notifyListeners();
  }

  Future<void> stop({bool signingOut = false}) async {
    _stopping = true;
    _debounce?.cancel();
    _retry?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _pullTask;
    _pendingRemote = null;
    await _pushDone?.future;
    if (_active) {
      await flush();
      await _saveCache();
      if (signingOut && !_dirty) await _store!.preferences.remove(_cacheKey);
    }
    _active = false;
    _uid = null;
    _dirty = false;
    _stopping = false;
  }
}
