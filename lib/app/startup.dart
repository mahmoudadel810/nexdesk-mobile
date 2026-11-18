import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api/api.dart';
import '../core/auth/session.dart';
import '../core/auth/session_controller.dart';
import 'preferences.dart';
import 'theme.dart';

/// This build's number, compared with the API's minimum. Set at launch from the package info.
final buildNumberProvider = Provider<int>((ref) => 1);

/// The web app's address, from /mobile/config, for the pages the app leaves to the web.
class WebBaseUrl extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? url) => state = url;
}

final webBaseUrlProvider = NotifierProvider<WebBaseUrl, String?>(WebBaseUrl.new);

/// Runs once at launch: refuse builds the API no longer supports, then pick up a stored sign-in.
final startupProvider = FutureProvider<void>((ref) async {
  final session = ref.read(sessionProvider.notifier);
  try {
    final config = await ref.read(authApiProvider).mobile.getMobileConfig();
    ref.read(webBaseUrlProvider.notifier).set(config.webBaseUrl);
    final minimum = _isIos() ? config.minimumBuild.ios : config.minimumBuild.android;
    if (ref.read(buildNumberProvider) < minimum) {
      session.block(BlockedReason.updateRequired);
      return;
    }
  } on Object {
    // Offline or the server is waking: the check runs again on the next launch.
  }

  await session.restore();
});

bool _isIos() {
  try {
    return Platform.isIOS;
  } on Object {
    return false;
  }
}

/// Things that follow the account rather than the phone: the interface language and the workspace's colour.
final accountEffectsProvider = Provider<void>((ref) {
  ref.listen<SessionState>(sessionProvider, (previous, next) async {
    switch (next) {
      case SignedIn(:final session):
        final firstTime = previous is! SignedIn || previous.session.user.id != session.user.id;
        if (!firstTime) return;
        await ref.read(languageProvider.notifier).set(session.user.language);
        await _loadBrand(ref, session);
      case SignedOut():
      case Blocked():
        ref.read(brandColorProvider.notifier).set(null);
      case SessionLoading():
        break;
    }
  });
});

Future<void> _loadBrand(Ref ref, Session session) async {
  final slug = session.tenant?.slug;
  if (slug == null) return;
  final preferences = ref.read(sharedPreferencesProvider);
  final cacheKey = 'nexdesk.brand.$slug';

  // The last known colour first, so the app does not flash NexDesk blue on every launch.
  ref.read(brandColorProvider.notifier).set(parseHexColor(preferences.getString(cacheKey)));
  try {
    final info = await ref.read(authApiProvider).customerPortal.getPortalInfo(slug: slug);
    ref.read(brandColorProvider.notifier).set(parseHexColor(info.brandColor));
    if (info.brandColor == null) {
      await preferences.remove(cacheKey);
    } else {
      await preferences.setString(cacheKey, info.brandColor!);
    }
  } on Object {
    // Keep the cached colour.
  }
}

/// `#1e6091` → Color; anything else → null (NexDesk's default).
Color? parseHexColor(String? hex) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex?.trim() ?? '');
  return match == null ? null : Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}
