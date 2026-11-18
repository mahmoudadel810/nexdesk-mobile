import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api.dart';
import '../../core/api/generated/nex_desk_api.dart';
import '../../core/cache/file_cache.dart';
import '../../core/errors/app_error.dart';
import 'attachment_rules.dart';
import 'device_files.dart';

/// Uploading and downloading attachments. The generated client offers neither upload progress nor the
/// downloaded bytes, so this talks to Dio directly, through the same interceptors (bearer token, refresh).
class AttachmentRepository {
  AttachmentRepository(this._dio, this._cache);

  final Dio _dio;
  final FileCache _cache;

  /// Uploads one file. [onProgress] gets 0 to 1. Cancelling throws an [AppError] whose [AppError.code] is
  /// [AttachmentCodes.cancelled].
  Future<AttachmentDto> upload(
    PickedFile file, {
    void Function(double)? onProgress,
    CancelToken? cancel,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: DioMediaType.parse(contentTypeOf(file.name)),
      ),
    });
    try {
      final response = await _dio.post<Map<String, Object?>>(
        '/api/v1/attachments',
        data: form,
        cancelToken: cancel,
        onSendProgress: onProgress == null || file.sizeBytes <= 0
            ? null
            : (sent, total) => onProgress((sent / (total > 0 ? total : file.sizeBytes)).clamp(0, 1)),
      );
      return AttachmentDto.fromJson(response.data!);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw const AppError(kind: AppErrorKind.unexpected, code: AttachmentCodes.cancelled);
      }
      throw AppError.from(error);
    }
  }

  /// The file on the phone, downloading it first unless it is already in the cache.
  Future<File> download(AttachmentDto attachment) async {
    final folder = await _cache.folder('attachments/${attachment.id}');
    final file = File('${folder.path}/${_safeName(attachment.fileName)}');
    if (file.existsSync() && file.lengthSync() == attachment.sizeBytes) return file;
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/attachments/${Uri.encodeComponent(attachment.id)}',
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data!, flush: true);
      return file;
    } on DioException catch (error) {
      // The body of a failed download is bytes, not a problem document, so the code is read from the status.
      if (error.response?.statusCode == 404) {
        throw const AppError(kind: AppErrorKind.problem, status: 404, code: AttachmentCodes.notFound);
      }
      throw AppError.from(error);
    }
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}

abstract final class AttachmentCodes {
  static const notFound = 'attachment-not-found';
  static const tooLarge = 'file-too-large';
  static const blocked = 'file-type-blocked';
  static const invalid = 'invalid-attachment';

  /// The person cancelled the upload. Never shown.
  static const cancelled = 'upload-cancelled';
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(dioProvider), ref.watch(fileCacheProvider)),
);
