import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'backup_media_stub.dart'
    if (dart.library.io) 'backup_media_io.dart'
    as media;

class CloudMedia {
  CloudMedia(this.uid, {FirebaseFirestore? firestore}) : _override = firestore;
  final String uid;
  final FirebaseFirestore? _override;
  FirebaseFirestore get _firestore => _override ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _files =>
      _firestore.collection('users/$uid/media');
  static const _prefix = 'cloud-media:';

  Iterable<String> _paths(Map<String, dynamic> data) sync* {
    for (final entry in data['diary_entries'] as List) {
      final path = entry['imagePath'];
      if (path is String && path.isNotEmpty) yield path;
    }
    final avatar = (data['profile'] as Map)['avatar_local_path'] as String;
    if (avatar.isNotEmpty) yield avatar;
  }

  Map<String, dynamic> _replace(
    Map<String, dynamic> input,
    Map<String, String> paths,
  ) {
    final data = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(input)) as Map,
    );
    for (final entry in data['diary_entries'] as List) {
      final path = entry['imagePath'];
      if (paths.containsKey(path)) entry['imagePath'] = paths[path];
    }
    final profile = data['profile'] as Map;
    final path = profile['avatar_local_path'];
    if (paths.containsKey(path)) profile['avatar_local_path'] = paths[path];
    return data;
  }

  Future<Map<String, dynamic>> upload(Map<String, dynamic> data) async {
    final packed = await media.packMedia(
      _paths(data).where((p) => !p.startsWith(_prefix)),
    );
    final replacements = <String, String>{};
    for (final entry in packed.entries) {
      final hash = sha256.convert(base64Decode(entry.value)).toString();
      final document = _files.doc(hash);
      final existing = await document.get();
      if (!existing.exists) {
        const chunkSize = 600000;
        final count = (entry.value.length / chunkSize).ceil();
        if (count > 100 || count == 0) throw StateError('Media file too large');
        final batch = _firestore.batch();
        for (var i = 0; i < count; i++) {
          final end = ((i + 1) * chunkSize).clamp(0, entry.value.length);
          batch.set(document.collection('chunks').doc('$i'), {
            'data': entry.value.substring(i * chunkSize, end),
          });
        }
        batch.set(document, {'chunks': count});
        await batch.commit().timeout(const Duration(seconds: 30));
      }
      replacements[entry.key] = '$_prefix$hash';
    }
    return _replace(data, replacements);
  }

  Future<Map<String, dynamic>> download(Map<String, dynamic> data) async {
    final packed = <String, String>{};
    for (final path in _paths(
      data,
    ).where((p) => p.startsWith(_prefix)).toSet()) {
      final hash = path.substring(_prefix.length);
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
        throw const FormatException('Invalid photo');
      }
      final document = _files.doc(hash);
      final metadata = await document.get();
      final count = metadata.data()?['chunks'] as int? ?? 0;
      if (count < 1 || count > 100) {
        throw const FormatException('Missing photo');
      }
      final result = StringBuffer();
      for (var i = 0; i < count; i++) {
        final chunk = await document.collection('chunks').doc('$i').get();
        result.write(chunk.data()?['data'] as String? ?? '');
      }
      final encoded = result.toString();
      if (sha256.convert(base64Decode(encoded)).toString() != hash) {
        throw const FormatException('Invalid photo');
      }
      packed[path] = encoded;
    }
    return _replace(data, await media.unpackMedia(packed));
  }
}
