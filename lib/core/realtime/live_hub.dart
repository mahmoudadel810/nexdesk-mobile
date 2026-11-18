import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../api/generated/nex_desk_api.dart';

/// What the API pushes over the live connection, plus the connection's own ups and downs.
sealed class LiveEvent {
  const LiveEvent();
}

/// Someone changed a ticket in this workspace: `created`, `updated` or `message`.
class TicketChanged extends LiveEvent {
  const TicketChanged(this.ticketId, this.change);

  final String ticketId;
  final String change;
}

class NotificationArrived extends LiveEvent {
  const NotificationArrived(this.notification);

  final NotificationDto notification;
}

/// Connected, the first time or again after a drop. Anything sent in between is lost (SignalR does not
/// replay), so listeners reload what they show.
class LiveConnected extends LiveEvent {
  const LiveConnected();
}

class LiveDisconnected extends LiveEvent {
  const LiveDisconnected();
}

/// The live connection. Widget and unit tests replace it with a fake.
abstract interface class LiveHub {
  Stream<LiveEvent> get events;

  /// Connects, and says whether it worked. Failing is not an error the person sees: the app works without
  /// live updates.
  Future<bool> start();

  Future<void> stop();
}

/// Back-off between reconnect attempts: 0, 2, 5, 10 and 30 seconds, then every 30 seconds while the app is in
/// the foreground.
class ForeverRetry implements IRetryPolicy {
  static const delays = [0, 2000, 5000, 10000, 30000];

  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) =>
      delays[retryContext.previousRetryCount.clamp(0, delays.length - 1)];
}

/// `/hubs/notifications` over WebSockets. The token goes in the query string; [token] is asked on every
/// (re)connect, so it is refreshed when it is about to expire. A stopped connection does not start again
/// reliably in this library, so every start builds a new one.
class SignalRLiveHub implements LiveHub {
  SignalRLiveHub({required this.baseUrl, required this.token});

  final String baseUrl;
  final Future<String> Function() token;
  final _events = StreamController<LiveEvent>.broadcast();
  HubConnection? _connection;

  @override
  Stream<LiveEvent> get events => _events.stream;

  HubConnection _build() {
    final connection = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/hubs/notifications',
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
            accessTokenFactory: token,
            requestTimeout: 30000,
          ),
        )
        .withAutomaticReconnect(reconnectPolicy: ForeverRetry())
        .build();
    // Callbacks from a connection that has since been replaced are ignored.
    void emit(LiveEvent event) {
      if (identical(_connection, connection)) _events.add(event);
    }

    connection.on('ticketChanged', (arguments) {
      final message = arguments?.firstOrNull;
      if (message is Map) emit(TicketChanged('${message['ticketId']}', '${message['change']}'));
    });
    connection.on('notification', (arguments) {
      final message = arguments?.firstOrNull;
      if (message is Map) {
        emit(NotificationArrived(NotificationDto.fromJson(message.cast<String, Object?>())));
      }
    });
    connection.onreconnected(({connectionId}) => emit(const LiveConnected()));
    connection.onreconnecting(({error}) => emit(const LiveDisconnected()));
    connection.onclose(({error}) => emit(const LiveDisconnected()));
    return connection;
  }

  @override
  Future<bool> start() async {
    if (_connection?.state == HubConnectionState.Connected) return true;
    await stop();
    final connection = _connection = _build();
    try {
      await connection.start();
      _events.add(const LiveConnected());
      return true;
    } on Object catch (error) {
      debugPrint('Live connection failed: $error');
      if (identical(_connection, connection)) _connection = null;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    if (connection == null || connection.state == HubConnectionState.Disconnected) return;
    try {
      await connection.stop();
    } on Object {
      // Already gone.
    }
  }
}
