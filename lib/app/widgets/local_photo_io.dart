import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider<Object>? localPhotoProvider(String path) =>
    File(path).existsSync() ? FileImage(File(path)) : null;
