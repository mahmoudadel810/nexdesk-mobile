import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Files kept on the phone (downloaded attachments, shrunk photos) in the OS cache directory, which the system
/// may clear when space runs low. Never in SQLite. Signing out deletes all of it.
class FileCache {
  FileCache(this._root);

  final Future<Directory> Function() _root;

  Future<Directory> folder(String name) async {
    final folder = Directory('${(await _root()).path}/nexdesk/$name');
    return folder.create(recursive: true);
  }

  Future<void> wipe() async {
    final all = Directory('${(await _root()).path}/nexdesk');
    if (all.existsSync()) await all.delete(recursive: true);
  }
}

final fileCacheProvider = Provider<FileCache>((ref) => FileCache(getApplicationCacheDirectory));
