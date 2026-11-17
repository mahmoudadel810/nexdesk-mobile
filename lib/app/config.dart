import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Flavor { dev, prod }

/// What differs between builds: which API the app talks to.
class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  /// Development builds talk to `docker compose` on the host machine. The Android emulator reaches the host at
  /// 10.0.2.2; override with `--dart-define=API_BASE_URL=...` for a phone on the same network.
  static const dev = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080'),
  );

  /// The hosted API, called directly: Vercel's rewrites do not carry WebSockets.
  static const prod = AppConfig(
    flavor: Flavor.prod,
    apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'https://nexdesk-api.onrender.com'),
  );

  final Flavor flavor;
  final String apiBaseUrl;
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.dev);
