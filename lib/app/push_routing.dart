import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/push/push_service.dart';
import 'router.dart';

/// Opens the screen of a tapped notification: the one that started the app (cold) and any tapped while it runs
/// (warm). The router's redirect takes care of the rest: signed out, the link waits until after sign-in.
final pushRoutingProvider = Provider<void>((ref) {
  final push = ref.watch(pushServiceProvider);
  final router = ref.read(routerProvider);
  final taps = push.taps.listen(router.go);
  ref.onDispose(() => unawaited(taps.cancel()));
  unawaited(
    push.initialTap().then((link) {
      if (link != null) router.go(link);
    }),
  );
});
