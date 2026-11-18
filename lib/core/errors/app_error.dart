import 'package:dio/dio.dart';

enum AppErrorKind {
  /// The API answered with a problem: [AppError.code] says which.
  problem,

  /// No answer: offline, a timeout, or the hosted API still waking up.
  network,

  /// Something the app did not expect.
  unexpected,
}

/// Every failure the app shows. Screens decide what to do by [code], never by message text; the codes are the
/// API's ProblemDetails `code` extension.
class AppError implements Exception {
  const AppError({
    required this.kind,
    this.status,
    this.code,
    this.title,
    this.fieldErrors = const {},
    this.requestId,
    this.retryAfter,
  });

  /// Turns anything thrown by a request into an [AppError].
  factory AppError.from(Object error) {
    if (error is AppError) return error;
    if (error is! DioException) {
      return const AppError(kind: AppErrorKind.unexpected);
    }

    final response = error.response;
    if (response == null) {
      return const AppError(kind: AppErrorKind.network);
    }

    final body = response.data;
    final problem = body is Map<String, Object?> ? body : const <String, Object?>{};
    final errors = problem['errors'];
    final retryAfter = int.tryParse(response.headers.value('retry-after') ?? '');
    return AppError(
      kind: AppErrorKind.problem,
      status: response.statusCode,
      code: problem['code'] as String? ?? (response.statusCode == 429 ? 'too-many-requests' : null),
      title: problem['title'] as String?,
      fieldErrors: errors is Map<String, Object?>
          ? {
              for (final entry in errors.entries)
                entry.key: [for (final message in (entry.value as List<Object?>? ?? const [])) '$message'],
            }
          : const {},
      requestId: problem['correlationId'] as String? ?? problem['traceId'] as String?,
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
  }

  final AppErrorKind kind;
  final int? status;
  final String? code;
  final String? title;

  /// Validation messages by field name, as the API sends them (camelCase).
  final Map<String, List<String>> fieldErrors;

  /// Shown with "Something went wrong" so the problem can be reported.
  final String? requestId;
  final Duration? retryAfter;

  bool get isNetwork => kind == AppErrorKind.network;

  @override
  String toString() => 'AppError($kind, $status, $code)';
}

/// The codes the session code reacts to.
abstract final class ErrorCodes {
  static const invalidCredentials = 'invalid-credentials';
  static const invalidRefreshToken = 'invalid-refresh-token';
  static const accountLocked = 'account-locked';
  static const accountDisabled = 'account-disabled';
  static const emailNotVerified = 'email-not-verified';
  static const tenantSuspended = 'tenant-suspended';
  static const tooManyRequests = 'too-many-requests';
}
