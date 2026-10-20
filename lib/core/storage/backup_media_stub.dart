Future<Map<String, String>> packMedia(Iterable<String> paths) async => {
  for (final path in paths)
    if (path.startsWith('data:image/'))
      path: path.substring(path.indexOf(',') + 1),
};
Future<Map<String, String>> unpackMedia(Map<String, String> media) async => {
  for (final entry in media.entries)
    entry.key: 'data:image/png;base64,${entry.value}',
};
