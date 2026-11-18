import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/app/startup.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/auth/session.dart';

import '../fakes.dart';

void main() {
  final signedIn = SignedIn(Session.from(MobileAuthResponse.fromJson(authBody(access: 'a', refresh: 'r'))));

  test('each session state has its place', () {
    expect(redirectFor(const SessionLoading(), Uri.parse('/app/tickets')), Routes.splash);
    expect(redirectFor(const Blocked(BlockedReason.tenantSuspended), Uri.parse('/login')), Routes.blocked);
    expect(redirectFor(const SignedOut(), Uri.parse('/')), Routes.signIn);
    expect(redirectFor(const SignedOut(), Uri.parse('/login')), isNull);
    expect(redirectFor(signedIn, Uri.parse('/login')), Routes.inbox);
    expect(redirectFor(signedIn, Uri.parse('/')), Routes.inbox);
    expect(redirectFor(signedIn, Uri.parse('/app/profile')), isNull);
  });

  test('a link opened while signed out is followed after sign-in, but only inside the app', () {
    final kept = redirectFor(const SignedOut(), Uri.parse('/app/tickets/42'))!;
    expect(kept, '/login?from=%2Fapp%2Ftickets%2F42');
    expect(redirectFor(signedIn, Uri.parse(kept)), '/app/tickets/42');
    expect(redirectFor(signedIn, Uri.parse('/login?from=https://evil.example')), Routes.inbox);
  });

  test('brand colours are read from the help centre setting', () {
    expect(parseHexColor('#1e6091'), const Color(0xFF1E6091));
    expect(parseHexColor(' #00796B '), const Color(0xFF00796B));
    expect(parseHexColor('red'), isNull);
    expect(parseHexColor(null), isNull);
  });
}
