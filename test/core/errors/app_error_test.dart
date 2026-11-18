import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/errors/app_error.dart';
import 'package:nexdesk_mobile/core/errors/error_messages.dart';
import 'package:nexdesk_mobile/core/l10n/generated/app_localizations_ar.dart';
import 'package:nexdesk_mobile/core/l10n/generated/app_localizations_en.dart';

DioException _response(int status, Object? body, {Map<String, List<String>> headers = const {}}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    response: Response<Object?>(
      requestOptions: request,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    ),
  );
}

void main() {
  test('reads the code, title, field errors, request id and Retry-After from a problem', () {
    final error = AppError.from(
      _response(
        400,
        {
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'code': 'validation',
          'errors': {
            'email': ['Enter a valid email address.'],
          },
          'correlationId': 'abc123',
        },
        headers: {
          'retry-after': ['30'],
        },
      ),
    );

    expect(error.kind, AppErrorKind.problem);
    expect(error.status, 400);
    expect(error.code, 'validation');
    expect(error.fieldErrors, {
      'email': ['Enter a valid email address.'],
    });
    expect(error.requestId, 'abc123');
    expect(error.retryAfter, const Duration(seconds: 30));
  });

  test('no response means the network, and a bare 429 still gets its code', () {
    expect(AppError.from(DioException(requestOptions: RequestOptions(path: '/x'))).isNetwork, isTrue);
    expect(AppError.from(_response(429, null)).code, ErrorCodes.tooManyRequests);
    expect(AppError.from(StateError('x')).kind, AppErrorKind.unexpected);
  });

  test('each sign-in code has its own message in both languages', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();
    AppError coded(String code) => AppError(kind: AppErrorKind.problem, status: 403, code: code);

    for (final code in [
      ErrorCodes.invalidCredentials,
      ErrorCodes.accountLocked,
      ErrorCodes.emailNotVerified,
      ErrorCodes.invalidRefreshToken,
      ErrorCodes.tenantSuspended,
      ErrorCodes.accountDisabled,
    ]) {
      expect(messageFor(coded(code), en), isNot(code));
      expect(messageFor(coded(code), ar), isNot(messageFor(coded(code), en)));
    }

    expect(messageFor(coded(ErrorCodes.invalidCredentials), en), 'The email or password is incorrect.');
    expect(messageFor(const AppError(kind: AppErrorKind.network), ar), ar.errorNetwork);
    expect(
      messageFor(const AppError(kind: AppErrorKind.problem, status: 500, requestId: 'r-9'), en),
      'Something went wrong. Try again. Reference: r-9',
    );
    expect(
      messageFor(const AppError(kind: AppErrorKind.problem, status: 409, title: 'Server says'), en),
      'Server says',
    );
  });
}
