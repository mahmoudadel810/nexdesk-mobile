# NexDesk Mobile

The Flutter app for **NexDesk** support teams: triage the inbox, reply and add notes with @mentions, get
pushed when something needs you, in English or Arabic. It talks to the same API as the web app
([nexdesk-api](https://github.com/mahmoudadel810/nexdesk-api)); customers keep using the web help centre
([nexdesk-web](https://github.com/mahmoudadel810/nexdesk-web)).

This is Phase 16. The plan, with every decision and the steps 16.1 to 16.12, is in
`docs/phase-16-mobile-plan.md` in the NexDesk workspace. Built so far:

| Step | What | Where |
|------|------|-------|
| 16.1 | Mobile sign-in API: refresh token in the body, `sid` claim | nexdesk-api |
| 16.2 | Devices and the Push notification channel | nexdesk-api |
| 16.3 | `GET /mobile/config`, app-link files, Push column on the web | nexdesk-api, nexdesk-web |
| 16.4 | This app's skeleton: flavors, theme, English and Arabic, generated API client, cache, tests | here |
| 16.5 | Sign-in and session: refresh token in secure storage, one refresh at a time, error messages by code, blocked screens, minimum version, workspace colour, account language, sign-out wipe | here |

### How the session works

- The refresh token is kept in the Keychain or Android Keystore; the access token only in memory.
- Every request goes through one interceptor: it adds the bearer token, refreshes a minute before expiry,
  refreshes once and replays on a `401`, signs out on a second `401`, and waits out a `429` for reads.
- Refreshes are single-flight: ten requests with an expired token make one refresh call. The API treats a
  refresh token used twice as stolen, so overlapping refreshes would sign the phone out.
- The new refresh token is saved before the new access token is used.
- `invalid-refresh-token` signs out quietly ("Your session ended"); `tenant-suspended` and
  `account-disabled` show a blocked screen; platform admins are sent to the web.
- On launch the app checks `GET /mobile/config` and asks for an update if its build is too old.
- After sign-in the interface follows the account's language, and the theme takes the workspace's
  help-centre colour (cached, so it does not flash on the next launch).
- Signing out revokes the sign-in on the server and wipes secure storage and the cache.

The Maestro flows `login_maya`, `login_wrong_password` and `login_layla_rtl` need the local API seeded with
`--seed` (demo password `NexDesk-demo-2026`).

## Stack

| Concern | Choice |
|---------|--------|
| Framework | Flutter 3.50 (pinned in `.fvmrc`) |
| State | Riverpod 3 |
| Navigation | go_router, with the web app's paths (`/app/tickets/:id`) so links open the same place |
| API | A Dio client generated from the API's OpenAPI document by swagger_parser: plain Dart, no build step |
| Cache | drift (SQLite) |
| Languages | English and Arabic through ARB files; the layout flips right to left with no restart |
| Tests | flutter_test (widget, unit, golden) and Maestro on the Android emulator |

## Getting started

You need Flutter 3.50, Java 17 and the Android SDK. The scripts look for them in `~/dev-tools`
(`flutter/`, `jdk-17/`, `android-sdk/`) and otherwise use whatever is on `PATH`.

```bash
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

The `dev` flavor (package `app.nexdesk.mobile.dev`, named "NexDesk Dev") calls the API at
`http://10.0.2.2:8080`, which is `docker compose` on your machine as seen from the Android emulator. Pass
`--dart-define=API_BASE_URL=http://<your-ip>:8080` for a phone on your network. The `prod` flavor
(`app.nexdesk.mobile`) calls `https://nexdesk-api.onrender.com` and allows HTTPS only.

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

Release builds are signed with the upload key in `~/.config/nexdesk-mobile/key.properties`; without it
they fall back to the debug key. Keys never go into the repository.

## The API client

`openapi/nexdesk-v1.json` is a committed snapshot of the API's document, and `lib/core/api/generated/` is
generated from it. After an API change, with the API running locally:

```bash
scripts/update-api.sh
```

Then commit both. `verify.sh` regenerates from the snapshot and fails if the result differs from what is
committed. Screens use repositories that wrap the generated client, never the generated types directly.

## Checks

```bash
scripts/verify.sh          # generated code, format, l10n keys, directional layout, analyze, tests
scripts/verify.sh --e2e    # plus: build the dev app and run the Maestro flows on a running emulator
```

`scripts/check-directional.sh` rejects left/right spacing and alignment in `lib/`: use
`EdgeInsetsDirectional`, `AlignmentDirectional` and `TextAlign.start`/`end`, so the Arabic layout mirrors.
`scripts/check_l10n.dart` fails when a message is missing from either language. Golden images of the
sign-in screen in both directions are in `test/goldens/`; refresh them on purpose with
`flutter test --update-goldens test/goldens`.

For the end-to-end flows, start an emulator, then:

```bash
scripts/verify.sh --e2e
```

## Layout

```
lib/
  main_dev.dart, main_prod.dart   one entry point per flavor
  app/                            app widget, config, router, theme, preferences
  core/api/                       Dio setup and the generated client
  core/cache/                     drift database
  core/l10n/                      app_en.arb, app_ar.arb (+ generated)
  features/<feature>/presentation screens and widgets
test/                             unit, widget and golden tests
e2e/                              Maestro flows
scripts/                          verify, update-api, checks
```
