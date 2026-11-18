import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences.dart';
import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/app_error.dart';

/// The signed-in person's own record, for their availability.
final myUserProvider = FutureProvider.autoDispose<UserDto>((ref) async {
  final session = ref.watch(sessionProvider.notifier).current;
  if (session == null) throw const AppError(kind: AppErrorKind.unexpected);
  try {
    return await ref.watch(apiProvider).users.getUser(id: session.user.id);
  } on Object catch (error) {
    throw AppError.from(error);
  }
});

class ProfileRepository {
  ProfileRepository(this._ref);

  final Ref _ref;

  NexDeskApi get _api => _ref.read(apiProvider);

  Future<UserDto> setAvailability(Availability availability) =>
      _guard(() => _api.users.setMyAvailability(body: SetAvailabilityRequest(availability: availability)));

  /// Saves the language on the account, so the web and emails follow it too, and switches the app at once.
  Future<void> setLanguage(String language) async {
    final session = _ref.read(sessionProvider.notifier).current;
    if (session == null) return;
    final details = await _guard(
      () => _api.users.updateMyProfile(
        body: UpdateProfileRequest(fullName: session.user.fullName, language: language),
      ),
    );
    _ref.read(sessionProvider.notifier).updateDetails(details);
    await _ref.read(languageProvider.notifier).set(language);
  }

  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Object catch (error) {
      throw AppError.from(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(ProfileRepository.new);
