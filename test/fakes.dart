import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexdesk_mobile/core/api/api.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/cache/database.dart';

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions request);

/// Stands in for the API: answers by "METHOD /path" and records every call.
class FakeApi implements HttpClientAdapter {
  final Map<String, FakeHandler> routes = {};
  final List<RequestOptions> calls = [];

  int count(String route) => calls.where((c) => '${c.method} ${c.path}' == route).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final handler = routes['${options.method} ${options.path}'];
    if (handler == null) return json(404, {'title': 'Not Found', 'status': 404});
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body, {Map<String, List<String>> headers = const {}}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
        ...headers,
      },
    );

ResponseBody problem(int status, String code) =>
    json(status, {'title': code, 'status': status, 'code': code, 'correlationId': 'corr-1'});

Map<String, Object?> authBody({
  required String access,
  required String refresh,
  DateTime? expiresAt,
  bool platformAdmin = false,
  String language = 'en',
  String slug = 'brightpath',
}) => {
  'accessToken': access,
  'expiresAt': (expiresAt ?? DateTime.now().toUtc().add(const Duration(minutes: 15))).toIso8601String(),
  'refreshToken': refresh,
  'refreshTokenExpiresAt': DateTime.now().toUtc().add(const Duration(days: 14)).toIso8601String(),
  'session': {
    'user': {
      'id': 'user-maya',
      'email': 'maya@brightpath.demo',
      'fullName': 'Maya Chen',
      'role': platformAdmin ? null : 'Agent',
      'language': language,
      'isPlatformAdmin': platformAdmin,
    },
    'tenant': platformAdmin
        ? null
        : {
            'id': 'tenant-1',
            'name': 'BrightPath Software',
            'slug': slug,
            'defaultLanguage': 'en',
            'timezone': 'Europe/London',
            'onboardingCompleted': true,
          },
    'permissions': ['tickets.view'],
  },
};

Dio fakeDio(FakeApi api) => Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = api;

/// A container wired to the fake API, an in-memory token store and an in-memory database.
ProviderContainer fakeContainer(FakeApi api, {MemoryTokenStore? tokens, List<Object> extra = const []}) {
  final database = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
      databaseProvider.overrideWithValue(database),
      authApiProvider.overrideWith((ref) => NexDeskApi(fakeDio(api))),
      dioProvider.overrideWith((ref) {
        final dio = fakeDio(api);
        dio.interceptors.add(AuthInterceptor(dio, ref.read(sessionProvider.notifier)));
        return dio;
      }),
      ...extra.cast(),
    ],
  );
  return container;
}
