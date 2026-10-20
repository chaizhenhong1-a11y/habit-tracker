import 'dart:convert';
import 'package:flutter/material.dart';
import 'local_photo_stub.dart' if (dart.library.io) 'local_photo_io.dart';

class StoredPhoto extends StatelessWidget {
  const StoredPhoto(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? provider;
    try {
      if (path.startsWith('data:image/')) {
        provider = MemoryImage(
          base64Decode(path.substring(path.indexOf(',') + 1)),
        );
      } else if (path.startsWith('http')) {
        provider = NetworkImage(path);
      } else {
        provider = localPhotoProvider(path);
      }
    } catch (_) {
      provider = null;
    }
    Widget missing() => SizedBox(
      width: width,
      height: height ?? 80,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
    if (provider == null) return missing();
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => missing(),
    );
  }
}
