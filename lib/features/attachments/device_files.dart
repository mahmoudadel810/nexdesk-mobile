import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/cache/file_cache.dart';
import 'attachment_rules.dart';

/// A file on the phone, ready to upload.
class PickedFile {
  const PickedFile({required this.path, required this.name, required this.sizeBytes});

  final String path;
  final String name;
  final int sizeBytes;
}

/// The camera, the photo library, the file browser and the OS file viewer. None of these run in widget tests,
/// which replace this with a fake.
abstract interface class DeviceFiles {
  Future<PickedFile?> takePhoto();

  Future<PickedFile?> choosePhoto();

  Future<PickedFile?> chooseFile();

  /// Opens a downloaded file in whatever app the phone uses for its type. Returns false when none can.
  Future<bool> open(File file);
}

/// Photos are sent as JPEG at most 2048 px on the long edge, quality 80: usually under 1 MB, and HEIC becomes
/// something every recipient can open.
const _longEdge = 2048.0;
const _quality = 80;

class PluginDeviceFiles implements DeviceFiles {
  PluginDeviceFiles(this._cache);

  final FileCache _cache;
  final _images = ImagePicker();

  @override
  Future<PickedFile?> takePhoto() => _photo(ImageSource.camera);

  @override
  Future<PickedFile?> choosePhoto() => _photo(ImageSource.gallery);

  Future<PickedFile?> _photo(ImageSource source) async {
    final picked = await _images.pickImage(
      source: source,
      maxWidth: _longEdge,
      maxHeight: _longEdge,
      imageQuality: _quality,
    );
    // The picker hands back temporary names such as "scaled_19.jpg"; recipients get one that says what it is.
    return picked == null ? null : _asJpeg(picked.path, photoName(DateTime.now()));
  }

  @override
  Future<PickedFile?> chooseFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    final file = files.single;
    final size = await file.xFile.length();
    var path = file.path;
    if (path == null) {
      // A content URI rather than a file: copy it into the cache so it can be read like one.
      final folder = await _cache.folder('outgoing');
      path = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}-${file.name}';
      await file.xFile.saveTo(path);
    }
    if (isPhoto(file.name) && size <= maxAttachmentBytes * 4) return _asJpeg(path, file.name);
    return PickedFile(path: path, name: file.name, sizeBytes: size);
  }

  Future<PickedFile> _asJpeg(String path, String name) async {
    final base = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    final jpegName = '$base.jpg';
    final ext = extensionOf(name);
    if (ext == '.jpg' || ext == '.jpeg') {
      final size = await File(path).length();
      if (size <= maxAttachmentBytes ~/ 4) return PickedFile(path: path, name: jpegName, sizeBytes: size);
    }
    final folder = await _cache.folder('outgoing');
    final target = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}-$jpegName';
    // A photo already fitted to 2048 px is not scaled again: the minimums only ever shrink.
    final converted = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      minWidth: _longEdge.toInt(),
      minHeight: _longEdge.toInt(),
      quality: _quality,
    );
    if (converted == null) {
      return PickedFile(path: path, name: name, sizeBytes: await File(path).length());
    }
    return PickedFile(path: converted.path, name: jpegName, sizeBytes: await converted.length());
  }

  @override
  Future<bool> open(File file) async => (await OpenFilex.open(file.path)).type == ResultType.done;
}

final deviceFilesProvider = Provider<DeviceFiles>((ref) => PluginDeviceFiles(ref.watch(fileCacheProvider)));
