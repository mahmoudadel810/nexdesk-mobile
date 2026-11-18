import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../auth/session.dart';
import '../auth/session_controller.dart';
import 'live_hub.dart';

enum LiveStatus { off, connecting, connected }

final liveHubProvider = Provider<LiveHub>((ref) {
  final hub = SignalRLiveHub(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    token: () => ref.read(sessionProvider.notifier).accessToken(),
  );
  ref.onDispose(() => unawaited(hub.stop()));
  return hub;
});

/// Everything the live connection delivers. Screens listen and reload what they show.
final liveEventsProvider = Provider<Stream<LiveEvent>>((ref) => ref.watch(liveHubProvider).events);

/// Keeps the live connection open while someone is signed in and the app is in the foreground. Phones close
/// background sockets anyway, so 30 seconds after the app leaves the screen the connection is closed, and it
/// opens again on return. A first connect that fails is retried with the same back-off as reconnects.
class RealtimeController extends Notifier<LiveStatus> {
  static const closeAfter = Duration(seconds: 30);

  bool _foreground = true;
  int _attempt = 0;
  Timer? _closing;
  Timer? _retry;

  LiveHub get _hub => ref.read(liveHubProvider);

  bool get _signedIn => ref.read(sessionProvider) is SignedIn;

  bool get _wanted => _signedIn && _foreground;

  @override
  LiveStatus build() {
    final hub = ref.watch(liveHubProvider);
    final events = hub.events.listen(_onEvent);
    ref.listen(sessionProvider, (_, _) => _sync());
    ref.onDispose(() {
      unawaited(events.cancel());
      _closing?.cancel();
      _retry?.cancel();
      unawaited(hub.stop());
    });
    Future.microtask(_sync);
    return LiveStatus.off;
  }

  void appResumed() {
    _foreground = true;
    _closing?.cancel();
    _closing = null;
    _sync();
  }

  void appPaused() {
    _foreground = false;
    _closing?.cancel();
    _closing = Timer(closeAfter, _disconnect);
  }

  void _sync() {
    if (_wanted && state == LiveStatus.off) unawaited(_connect());
    if (!_signedIn) _disconnect();
  }

  Future<void> _connect() async {
    _retry?.cancel();
    state = LiveStatus.connecting;
    final connected = await _hub.start();
    if (!ref.mounted) return;
    if (connected) {
      _attempt = 0;
      state = LiveStatus.connected;
      return;
    }
    if (!_wanted) {
      state = LiveStatus.off;
      return;
    }
    final delay = ForeverRetry.delays[_attempt.clamp(0, ForeverRetry.delays.length - 1)];
    _attempt++;
    _retry = Timer(Duration(milliseconds: delay), () {
      if (_wanted && state != LiveStatus.connected) unawaited(_connect());
    });
  }

  void _disconnect() {
    _retry?.cancel();
    _attempt = 0;
    if (state == LiveStatus.off) return;
    state = LiveStatus.off;
    unawaited(_hub.stop());
  }

  void _onEvent(LiveEvent event) {
    if (state == LiveStatus.off) return;
    switch (event) {
      case LiveConnected():
        state = LiveStatus.connected;
      // In the background the phone cuts the network within seconds; retrying there only drains the battery,
      // so the connection is ended and opened fresh on return.
      case LiveDisconnected() when !_foreground:
        _disconnect();
      case LiveDisconnected():
        state = LiveStatus.connecting;
      case TicketChanged() || NotificationArrived():
        break;
    }
  }
}

final realtimeProvider = NotifierProvider<RealtimeController, LiveStatus>(RealtimeController.new);
