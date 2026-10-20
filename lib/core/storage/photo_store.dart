import 'backup_media_stub.dart'
    if (dart.library.io) 'backup_media_io.dart'
    as media;

Future<String> persistPhoto(String path) async {
  final packed = await media.packMedia([path]);
  return (await media.unpackMedia(packed))[path] ?? path;
}
