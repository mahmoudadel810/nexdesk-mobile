import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import 'generated/nex_desk_api.dart';

/// The one HTTP client. 16.5 adds the bearer token, single-flight refresh and error mapping as interceptors.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      // The hosted API sleeps when idle and takes up to a minute to wake.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-NexDesk-Client': 'mobile/${config.flavor.name}'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// The typed client generated from the API's OpenAPI document.
final apiProvider = Provider<NexDeskApi>((ref) => NexDeskApi(ref.watch(dioProvider)));
