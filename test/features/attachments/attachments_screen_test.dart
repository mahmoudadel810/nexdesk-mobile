import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/errors/app_error.dart';
import 'package:nexdesk_mobile/features/attachments/attachment_repository.dart';
import 'package:nexdesk_mobile/features/attachments/device_files.dart';

import '../../fakes.dart';
import '../ticket/ticket_helpers.dart';

/// Hands out a prepared file instead of opening the camera or the file browser.
class FakeDeviceFiles implements DeviceFiles {
  FakeDeviceFiles([this.next]);

  PickedFile? next;
  final opened = <File>[];

  /// Thrown by [open], like a viewer plugin or the file system failing.
  Object? openError;

  @override
  Future<PickedFile?> takePhoto() async => next;

  @override
  Future<PickedFile?> choosePhoto() async => next;

  @override
  Future<PickedFile?> chooseFile() async => next;

  @override
  Future<bool> open(File file) async {
    if (openError case final error?) throw error;
    opened.add(file);
    return true;
  }
}

/// The repository's own I/O is covered in attachment_repository_test.dart; here uploads and downloads are
/// scripted so the tests are about what the screen shows.
class FakeAttachments implements AttachmentRepository {
  Future<AttachmentDto> Function(PickedFile file, void Function(double)? onProgress)? onUpload;
  final downloads = <String, File>{};

  @override
  Future<AttachmentDto> upload(PickedFile file, {void Function(double)? onProgress, CancelToken? cancel}) =>
      onUpload!(file, onProgress);

  @override
  Future<File> download(AttachmentDto attachment) async =>
      downloads[attachment.id] ??
      (throw const AppError(kind: AppErrorKind.problem, status: 404, code: AttachmentCodes.notFound));
}

PickedFile picked(String name, int sizeBytes) =>
    PickedFile(path: '/phone/$name', name: name, sizeBytes: sizeBytes);

AttachmentDto uploaded(String name, int size) =>
    AttachmentDto.fromJson({'id': 'att-1', 'fileName': name, 'contentType': 'image/jpeg', 'sizeBytes': size});

Future<void> attachFrom(WidgetTester tester, String source) async {
  await tester.tap(find.byKey(const Key('attach')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(source)));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('an upload shows its progress, holds back sending, and the reply carries the file', (
    tester,
  ) async {
    final api = ticketApi(permissions: agent);
    String? sent;
    api.routes['POST $ticketPath/messages'] = (request) {
      sent = request.data as String;
      return json(200, ticket);
    };
    final release = Completer<void>();
    final attachments = FakeAttachments()
      ..onUpload = (file, onProgress) async {
        onProgress?.call(0.4);
        await release.future;
        return uploaded(file.name, file.sizeBytes);
      };
    await openTicket(
      tester,
      api,
      overrides: [
        deviceFilesProvider.overrideWithValue(FakeDeviceFiles(picked('photo.jpg', 4000))),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await tester.enterText(find.byKey(const Key('composer')), 'Here is the screenshot');
    await attachFrom(tester, 'attach-gallery');

    final progress = find.descendant(
      of: find.byKey(const Key('upload-progress')),
      matching: find.byType(CircularProgressIndicator),
    );
    expect(tester.widget<CircularProgressIndicator>(progress).value, 0.4);
    expect(tester.widget<IconButton>(find.byKey(const Key('send'))).onPressed, isNull);

    release.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('upload-progress')), findsNothing);
    expect(find.textContaining('photo.jpg · 4 KB'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();

    expect((jsonDecode(sent!) as Map<String, Object?>)['attachmentIds'], ['att-1']);
    expect(find.byKey(const Key('outgoing-photo.jpg')), findsNothing);
  });

  testWidgets('removing an uploading file takes it off the reply', (tester) async {
    final attachments = FakeAttachments()..onUpload = (file, _) => Completer<AttachmentDto>().future;
    await openTicket(
      tester,
      ticketApi(permissions: agent),
      overrides: [
        deviceFilesProvider.overrideWithValue(FakeDeviceFiles(picked('photo.jpg', 4000))),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await attachFrom(tester, 'attach-camera');
    await tester.tap(find.byTooltip('Remove photo.jpg'));
    await tester.pump();

    expect(find.byKey(const Key('outgoing-photo.jpg')), findsNothing);
    expect(tester.widget<IconButton>(find.byKey(const Key('send'))).onPressed, isNotNull);
  });

  testWidgets('a script is refused on the phone with the reason, and nothing is uploaded', (tester) async {
    var uploads = 0;
    final attachments = FakeAttachments()
      ..onUpload = (file, _) async {
        uploads++;
        return uploaded(file.name, file.sizeBytes);
      };
    await openTicket(
      tester,
      ticketApi(permissions: agent),
      overrides: [
        deviceFilesProvider.overrideWithValue(FakeDeviceFiles(picked('deploy.sh', 300))),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await attachFrom(tester, 'attach-file');
    await tester.pumpAndSettle();

    expect(find.textContaining("This type of file can't be sent"), findsOneWidget);
    expect(uploads, 0);
  });

  testWidgets('a 15 MB file is refused before upload, showing the 10 MB limit', (tester) async {
    final attachments = FakeAttachments()..onUpload = (file, _) => throw StateError('uploaded');
    await openTicket(
      tester,
      ticketApi(permissions: agent),
      overrides: [
        deviceFilesProvider.overrideWithValue(FakeDeviceFiles(picked('scan.pdf', 15 * 1024 * 1024))),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await attachFrom(tester, 'attach-file');
    await tester.pumpAndSettle();

    expect(find.textContaining('Over the 10 MB limit'), findsOneWidget);
  });

  testWidgets('an upload the API refuses shows its reason on the file', (tester) async {
    final attachments = FakeAttachments()
      ..onUpload = (file, _) async =>
          throw const AppError(kind: AppErrorKind.problem, status: 400, code: AttachmentCodes.blocked);
    await openTicket(
      tester,
      ticketApi(permissions: agent),
      overrides: [
        deviceFilesProvider.overrideWithValue(FakeDeviceFiles(picked('macro.txt', 300))),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await attachFrom(tester, 'attach-file');
    await tester.pumpAndSettle();

    expect(find.textContaining("This type of file can't be sent"), findsOneWidget);
  });

  testWidgets('a timeline file opens in the viewer, and a deleted one says it is no longer available', (
    tester,
  ) async {
    final withFiles = [
      {
        ...timeline[0]! as Map<String, Object?>,
        'attachments': [
          {'id': 'att-ok', 'fileName': 'invoice.pdf', 'contentType': 'application/pdf', 'sizeBytes': 3},
          {'id': 'att-gone', 'fileName': 'old.png', 'contentType': 'image/png', 'sizeBytes': 9},
        ],
      },
    ];
    final api = ticketApi(permissions: agent);
    api.routes['GET $ticketPath/timeline'] = (_) => json(200, withFiles);
    final files = FakeDeviceFiles();
    final attachments = FakeAttachments()..downloads['att-ok'] = File('/cache/invoice.pdf');
    await openTicket(
      tester,
      api,
      overrides: [
        deviceFilesProvider.overrideWithValue(files),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    expect(find.textContaining('invoice.pdf · 1 KB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('attachment-att-ok')));
    await tester.pumpAndSettle();
    expect(files.opened.single.path, '/cache/invoice.pdf');

    await tester.tap(find.byKey(const Key('attachment-att-gone')));
    await tester.pumpAndSettle();
    expect(find.textContaining('File no longer available'), findsWidgets);
    expect(tester.widget<ActionChip>(find.byKey(const Key('attachment-att-gone'))).onPressed, isNull);
  });

  testWidgets('a file the phone fails to save or open says so and can be tried again', (tester) async {
    final withFile = [
      {
        ...timeline[0]! as Map<String, Object?>,
        'attachments': [
          {'id': 'att-ok', 'fileName': 'invoice.pdf', 'contentType': 'application/pdf', 'sizeBytes': 3},
        ],
      },
    ];
    final api = ticketApi(permissions: agent);
    api.routes['GET $ticketPath/timeline'] = (_) => json(200, withFile);
    final files = FakeDeviceFiles()..openError = const FileSystemException('No space left on device');
    final attachments = FakeAttachments()..downloads['att-ok'] = File('/cache/invoice.pdf');
    await openTicket(
      tester,
      api,
      overrides: [
        deviceFilesProvider.overrideWithValue(files),
        attachmentRepositoryProvider.overrideWithValue(attachments),
      ],
    );

    await tester.tap(find.byKey(const Key('attachment-att-ok')));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(tester.widget<ActionChip>(find.byKey(const Key('attachment-att-ok'))).onPressed, isNotNull);
  });
}
