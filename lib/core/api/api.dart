import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../auth/session.dart';
import '../auth/session_controller.dart';
import '../errors/app_error.dart';
import 'generated/nex_desk_api.dart';

/// `mobile/<version>+<build> (<platform>)`, logged by the API to help support. Set once at launch.
final clientHeaderProvider = Provider<String>((ref) => 'mobile/dev (unknown)');

String clientHeader(String version, String build) {
  String platform;
  try {
    platform = Platform.operatingSystem;
  } on Object {
    platform = 'unknown';
  }
  return 'mobile/$version+$build ($platform)';
}

Dio _dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      // The hosted API sleeps when idle and takes up to a minute to wake.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-NexDesk-Client': ref.watch(clientHeaderProvider)},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}

/// For signing in and refreshing: no bearer token, and no refresh on 401 (that would loop).
final authApiProvider = Provider<NexDeskApi>((ref) => NexDeskApi(_dio(ref)));

/// Everything else: the bearer token, one refresh-and-retry on 401, and a polite retry on 429.
final dioProvider = Provider<Dio>((ref) {
  final dio = _dio(ref);
  dio.interceptors.add(AuthInterceptor(dio, ref.read(sessionProvider.notifier)));
  return dio;
});

final apiProvider = Provider<NexDeskApi>((ref) => NexDeskApi(ref.watch(dioProvider)));

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._session);

  static const _retried = 'nexdesk.retried';
  static const _backedOff = 'nexdesk.backed-off';

  final Dio _dio;
  final SessionController _session;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      options.headers['Authorization'] = 'Bearer ${await _session.accessToken()}';
      handler.next(options);
    } on Object catch (error) {
      handler.reject(DioException(requestOptions: options, error: AppError.from(error)));
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final options = error.requestOptions;
    final status = error.response?.statusCode;

    if (status == 401 && options.extra[_retried] != true) {
      try {
        final session = await _session.refresh();
        handler.resolve(await _replay(options, session, {_retried: true}));
      } on Object catch (refreshError) {
        handler.next(error.copyWith(error: AppError.from(refreshError)));
      }
      return;
    }

    if (status == 401) {
      // The new token was refused too: the sign-in is no good any more.
      await _session.signOut();
      handler.next(error);
      return;
    }

    // Reads are retried once after the wait the API asks for; writes are not, so nothing happens twice.
    if (status == 429 && options.method == 'GET' && options.extra[_backedOff] != true) {
      final wait = AppError.from(error).retryAfter ?? const Duration(seconds: 2);
      await Future<void>.delayed(wait > const Duration(seconds: 10) ? const Duration(seconds: 10) : wait);
      try {
        handler.resolve(
          await _dio.fetch<Object?>(options.copyWith(extra: {...options.extra, _backedOff: true})),
        );
      } on DioException catch (retryError) {
        handler.next(retryError);
      }
      return;
    }

    handler.next(error);
  }

  Future<Response<Object?>> _replay(RequestOptions options, Session session, Map<String, Object?> extra) =>
      _dio.fetch<Object?>(
        options.copyWith(
          headers: {...options.headers, 'Authorization': 'Bearer ${session.accessToken}'},
          extra: {...options.extra, ...extra},
        ),
      );
}
