import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

Future<Map<String, String>> packMedia(Iterable<String> paths) async {
  final result = <String, String>{};
  for (final path in paths.toSet()) {
    if (path.startsWith('data:image/')) {
      result[path] = path.substring(path.indexOf(',') + 1);
      continue;
    }
    if (path.isEmpty || path.startsWith('assets/') || path.startsWith('http')) {
      continue;
    }
    final bytes = await File(path).readAsBytes();
    result[path] = base64Encode(bytes);
  }
  return result;
}

Future<Map<String, String>> unpackMedia(Map<String, String> media) async {
  if (media.isEmpty) return {};
  final root = await getApplicationSupportDirectory();
  final directory = Directory('${root.path}/restored_media');
  await directory.create(recursive: true);
  final result = <String, String>{};
  for (final entry in media.entries) {
    final bytes = base64Decode(entry.value);
    final name = sha256.convert(bytes).toString();
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    result[entry.key] = file.path;
  }
  return result;
}
