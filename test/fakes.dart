import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexdesk_mobile/core/api/api.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/cache/database.dart';
import 'package:nexdesk_mobile/core/cache/file_cache.dart';
import 'package:nexdesk_mobile/core/realtime/live_hub.dart';
import 'package:nexdesk_mobile/core/realtime/realtime_controller.dart';

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
    // Reading the body is what moves Dio's upload progress.
    await requestStream?.drain<void>();
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
  String userId = 'user-maya',
}) => {
  'accessToken': access,
  'expiresAt': (expiresAt ?? DateTime.now().toUtc().add(const Duration(minutes: 15))).toIso8601String(),
  'refreshToken': refresh,
  'refreshTokenExpiresAt': DateTime.now().toUtc().add(const Duration(days: 14)).toIso8601String(),
  'session': {
    'user': {
      'id': userId,
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

/// Stands in for the live connection: records starts and stops, and lets a test push events.
class FakeLiveHub implements LiveHub {
  final _events = StreamController<LiveEvent>.broadcast(sync: true);

  /// What the next start answers.
  bool connects = true;
  int starts = 0;
  int stops = 0;

  /// Holds the next start open until completed, like a slow network.
  Completer<void>? holdStart;

  void emit(LiveEvent event) => _events.add(event);

  @override
  Stream<LiveEvent> get events => _events.stream;

  @override
  Future<bool> start() async {
    starts++;
    final hold = holdStart;
    holdStart = null;
    if (hold != null) await hold.future;
    if (connects) emit(const LiveConnected());
    return connects;
  }

  @override
  Future<void> stop() async => stops++;
}

/// Stands in for the OS cache directory, which path_provider cannot reach in tests.
final testCacheDirectory = Directory.systemTemp.createTempSync('nexdesk-test-cache');

Dio fakeDio(FakeApi api) => Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = api;

/// A container wired to the fake API, an in-memory token store and an in-memory database.
ProviderContainer fakeContainer(
  FakeApi api, {
  MemoryTokenStore? tokens,
  FakeLiveHub? hub,
  List<Object> extra = const [],
}) {
  final database = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
      databaseProvider.overrideWithValue(database),
      fileCacheProvider.overrideWithValue(FileCache(() async => testCacheDirectory)),
      liveHubProvider.overrideWithValue(hub ?? FakeLiveHub()),
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

/// One ticket as the list endpoint returns it.
Map<String, Object?> ticketJson(
  int number, {
  String status = 'Open',
  String priority = 'Normal',
  String? assignee = 'Maya Chen',
  DateTime? lastActivity,
  DateTime? resolutionDue,
  bool paused = false,
  bool breached = false,
}) => {
  'id': 'ticket-$number',
  'number': number,
  'subject': 'Subject $number',
  'status': status,
  'priority': priority,
  'type': 'Question',
  'channel': 'Email',
  'requester': {'id': 'c$number', 'name': 'Casey Morgan', 'email': 'casey@customers.demo'},
  'assignee': assignee == null ? null : {'id': 'user-maya', 'name': assignee, 'email': null},
  'team': null,
  'tags': <String>[],
  'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
  'lastActivityAt': (lastActivity ?? DateTime.utc(2026, 11, 18, 8)).toIso8601String(),
  'sla': {
    'firstResponseDueAt': null,
    'firstResponseBreached': false,
    'firstResponseMet': true,
    'resolutionDueAt': resolutionDue?.toIso8601String(),
    'resolutionBreached': breached,
    'isPaused': paused,
    'isEscalated': false,
  },
};

Map<String, Object?> pageJson(List<Map<String, Object?>> items, {int page = 1, int? total}) => {
  'items': items,
  'page': page,
  'pageSize': 25,
  'totalCount': total ?? items.length,
};
