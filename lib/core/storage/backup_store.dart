import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/diary/domain/entities/diary_entry.dart';
import '../../features/habits/domain/entities/habit.dart';
import '../../features/plans/domain/entities/plan_item.dart';
import '../../features/wishes/domain/entities/redeem_record.dart';
import '../../features/wishes/domain/entities/reward.dart';
import 'points_ledger.dart';
import 'backup_media_stub.dart'
    if (dart.library.io) 'backup_media_io.dart'
    as media;

class BackupStore {
  BackupStore(this.preferences);
  final SharedPreferences preferences;
  static const listKeys = [
    'diary_entries',
    'plans',
    'custom_rewards',
    'redeem_history',
  ];
  static const profileKeys = ['username', 'avatar_url', 'avatar_local_path'];
  static const _journalKey = 'restore_journal_v1';

  Map<String, dynamic> mergeGuest(
    Map<String, dynamic> account,
    Map<String, dynamic> guest,
  ) {
    final result = validate(account);
    final incoming = validate(guest);
    for (final key in ['habits', 'diary_entries', 'plans']) {
      final combined = <String, dynamic>{};
      for (final item in result[key] as List) {
        combined[item['id'] as String] = item;
      }
      for (final item in incoming[key] as List) {
        final id = item['id'] as String;
        final existing = combined[id];
        if (existing == null) {
          combined[id] = item;
        } else if (key == 'habits') {
          existing['completedDates'] = <String>{
            ...List<String>.from(existing['completedDates'] as List),
            ...List<String>.from(item['completedDates'] as List),
          }.toList();
          final progress = Map<String, dynamic>.from(
            existing['progressByDate'] as Map,
          );
          for (final entry in (item['progressByDate'] as Map).entries) {
            progress[entry.key as String] = math.max(
              (progress[entry.key] as num? ?? 0),
              entry.value as num,
            );
          }
          existing['progressByDate'] = progress;
        } else if (jsonEncode(existing) != jsonEncode(item)) {
          final copyId =
              'guest-$id-${sha256.convert(utf8.encode(jsonEncode(item))).toString().substring(0, 12)}';
          combined.putIfAbsent(copyId, () => {...item as Map, 'id': copyId});
        }
      }
      result[key] = combined.values.toList();
    }
    for (final key in ['custom_rewards', 'redeem_history']) {
      final unique = <String, dynamic>{};
      for (final item in [...result[key] as List, ...incoming[key] as List]) {
        unique[jsonEncode(item)] = item;
      }
      result[key] = unique.values.toList();
    }
    final awards = <String>{
      ...List<String>.from((result['ledger'] as Map)['awarded'] as List),
      ...List<String>.from((incoming['ledger'] as Map)['awarded'] as List),
    };
    final historySpent = (result['redeem_history'] as List).fold<int>(
      0,
      (n, v) => n + (v['cost'] as int),
    );
    final spent = math.max(
      historySpent,
      math.max(result['spentPoints'] as int, incoming['spentPoints'] as int),
    );
    final credit = math.max(
      (result['ledger'] as Map)['migrationCredit'] as int,
      (incoming['ledger'] as Map)['migrationCredit'] as int,
    );
    result['spentPoints'] = spent;
    result['ledger'] = {
      'awarded': awards.toList(),
      'migrationCredit': math.max(credit, spent - awards.length),
    };
    final profile = result['profile'] as Map;
    final guestProfile = incoming['profile'] as Map;
    for (final key in profileKeys) {
      if ((profile[key] as String).isEmpty) profile[key] = guestProfile[key];
    }
    return validate(result);
  }

  Future<String> exportPortable() async {
    final data = capture();
    final paths = <String>[
      for (final entry in data['diary_entries'] as List)
        if (entry['imagePath'] is String) entry['imagePath'] as String,
      (data['profile'] as Map)['avatar_local_path'] as String,
    ];
    data['media'] = await media.packMedia(paths);
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<Map<String, dynamic>> preparePortable(String text) async {
    final raw = jsonDecode(text) as Map;
    final data = validate(raw);
    final packed = Map<String, String>.from(raw['media'] as Map? ?? {});
    // Decode everything before changing any business data.
    for (final encoded in packed.values) {
      base64Decode(encoded);
    }
    final restored = await media.unpackMedia(packed);
    for (final entry in data['diary_entries'] as List) {
      final path = entry['imagePath'];
      if (path is String && path.isNotEmpty) {
        entry['imagePath'] = restored[path];
      }
    }
    final profile = data['profile'] as Map;
    profile['avatar_local_path'] = restored[profile['avatar_local_path']] ?? '';
    return data;
  }

  Map<String, dynamic> capture() => {
    'format': 'habittracker',
    'version': 1,
    'habits': Hive.box<dynamic>(
      'habits',
    ).values.map((v) => Map<String, dynamic>.from(v as Map)).toList(),
    'ledger': PointsLedger.opened().snapshot,
    'spentPoints': preferences.getInt('spent_points') ?? 0,
    for (final key in listKeys)
      key: (preferences.getStringList(key) ?? <String>[])
          .map(jsonDecode)
          .toList(),
    'profile': {
      for (final key in profileKeys) key: preferences.getString(key) ?? '',
    },
  };

  Map<String, dynamic> validate(Object? input) {
    try {
      final data = Map<String, dynamic>.from(input as Map);
      if (data['format'] != 'habittracker' || data['version'] != 1) {
        throw const FormatException('Unsupported backup');
      }
      final habits = (data['habits'] as List)
          .map((v) => Habit.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList();
      if (habits.any(
            (h) =>
                h.id.isEmpty ||
                h.name.trim().isEmpty ||
                !h.targetValue.isFinite ||
                h.targetValue <= 0,
          ) ||
          habits.map((h) => h.id).toSet().length != habits.length) {
        throw const FormatException('Invalid habits');
      }
      final diaries = (data['diary_entries'] as List)
          .map((v) => DiaryEntry.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      final plans = (data['plans'] as List)
          .map((v) => PlanItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      if (diaries.map((v) => v.id).toSet().length != diaries.length ||
          plans.map((v) => v.id).toSet().length != plans.length) {
        throw const FormatException('Duplicate IDs');
      }
      final rewards = (data['custom_rewards'] as List)
          .map((v) => Reward.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      final history = (data['redeem_history'] as List)
          .map(
            (v) => RedeemRecord.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      final ledger = Map<String, dynamic>.from(data['ledger'] as Map);
      final awarded = List<String>.from(ledger['awarded'] as List);
      for (final event in awarded) {
        final pair = List<String>.from(jsonDecode(event) as List);
        if (pair.length != 2 ||
            pair.first.isEmpty ||
            DateTime.tryParse(pair.last) == null) {
          throw const FormatException('Invalid award');
        }
      }
      final credit = ledger['migrationCredit'] as int;
      final spent = data['spentPoints'] as int;
      if (credit < 0 ||
          spent < 0 ||
          spent > awarded.length + credit ||
          awarded.toSet().length != awarded.length ||
          rewards.any((v) => v.cost <= 0) ||
          history.any((v) => v.cost <= 0)) {
        throw const FormatException('Invalid points');
      }
      final profile = Map<String, dynamic>.from(data['profile'] as Map);
      for (final key in profileKeys) {
        if (profile[key] is! String) {
          throw const FormatException('Invalid profile');
        }
      }
      return {
        'format': 'habittracker',
        'version': 1,
        'habits': habits.map((v) => v.toMap()).toList(),
        'diary_entries': diaries.map((v) => v.toJson()).toList(),
        'plans': plans.map((v) => v.toJson()).toList(),
        'custom_rewards': rewards.map((v) => v.toJson()).toList(),
        'redeem_history': history.map((v) => v.toJson()).toList(),
        'ledger': {'awarded': awarded, 'migrationCredit': credit},
        'spentPoints': spent,
        'profile': {for (final key in profileKeys) key: profile[key]},
      };
    } catch (_) {
      throw const FormatException('Invalid backup');
    }
  }

  Future<void> recoverInterruptedRestore() async {
    final journal = preferences.getString(_journalKey);
    if (journal == null) return;
    await _apply(validate(jsonDecode(journal)));
    await _checked(preferences.remove(_journalKey));
  }

  Future<void> restore(Map<String, dynamic> input) async {
    final data = validate(input);
    final previous = capture();
    await _checked(preferences.setString(_journalKey, jsonEncode(previous)));
    try {
      await _apply(data);
      await _checked(preferences.remove(_journalKey));
    } catch (_) {
      await _apply(previous);
      await _checked(preferences.remove(_journalKey));
      rethrow;
    }
  }

  Future<void> _apply(Map<String, dynamic> data) async {
    final box = Hive.box<dynamic>('habits');
    await box.clear();
    await box.putAll({
      for (final h in data['habits'] as List) h['id'] as String: h,
    });
    await Hive.box<dynamic>('points').put('ledger', data['ledger']);
    for (final key in listKeys) {
      await _checked(
        preferences.setStringList(
          key,
          (data[key] as List).map(jsonEncode).toList(),
        ),
      );
    }
    await _checked(
      preferences.setInt('spent_points', data['spentPoints'] as int),
    );
    for (final key in profileKeys) {
      await _checked(
        preferences.setString(key, (data['profile'] as Map)[key] as String),
      );
    }
  }

  Future<void> _checked(Future<bool> operation) async {
    if (!await operation) throw StateError('Could not save data');
  }

  Map<String, dynamic> empty() => {
    'format': 'habittracker',
    'version': 1,
    'habits': <dynamic>[],
    for (final key in listKeys) key: <dynamic>[],
    'ledger': {'awarded': <String>[], 'migrationCredit': 0},
    'spentPoints': 0,
    'profile': {for (final key in profileKeys) key: ''},
  };
}
