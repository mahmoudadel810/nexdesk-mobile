import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/errors/app_error.dart';
import 'package:nexdesk_mobile/features/attachments/attachment_repository.dart';
import 'package:nexdesk_mobile/features/attachments/device_files.dart';

import '../../fakes.dart';

PickedFile tempFile(String name, int sizeBytes) {
  final file = File('${testCacheDirectory.path}/$name')..writeAsBytesSync(List.filled(sizeBytes, 7));
  return PickedFile(path: file.path, name: name, sizeBytes: sizeBytes);
}

AttachmentDto attachment(String id, String name, int size) =>
    AttachmentDto.fromJson({'id': id, 'fileName': name, 'contentType': 'text/plain', 'sizeBytes': size});

FakeApi signedInApi() {
  final api = FakeApi();
  api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, authBody(access: 'a', refresh: 'r2'));
  return api;
}

void main() {
  test('an upload sends the file as multipart with its content type, and reports progress', () async {
    final api = signedInApi();
    api.routes['POST /api/v1/attachments'] = (_) =>
        json(201, {'id': 'att-1', 'fileName': 'photo.jpg', 'contentType': 'image/jpeg', 'sizeBytes': 5000});
    final container = fakeContainer(api, tokens: MemoryTokenStore('r1'));
    addTearDown(container.dispose);
    final progress = <double>[];

    final uploaded = await container
        .read(attachmentRepositoryProvider)
        .upload(tempFile('photo.jpg', 5000), onProgress: progress.add);

    expect(uploaded.id, 'att-1');
    expect(progress.last, 1);
    final request = api.calls.singleWhere((c) => c.path == '/api/v1/attachments');
    expect(request.headers['content-type'], startsWith('multipart/form-data'));
  });

  test('a refused upload becomes an error with the API code', () async {
    final api = signedInApi();
    api.routes['POST /api/v1/attachments'] = (_) => problem(400, 'file-type-blocked');
    final container = fakeContainer(api, tokens: MemoryTokenStore('r1'));
    addTearDown(container.dispose);

    await expectLater(
      container.read(attachmentRepositoryProvider).upload(tempFile('notes.txt', 10)),
      throwsA(isA<AppError>().having((e) => e.code, 'code', AttachmentCodes.blocked)),
    );
  });

  test('a download is cached, so the second open reads the phone and not the API', () async {
    final api = signedInApi();
    api.routes['GET /api/v1/attachments/att-1'] = (_) => json(200, 'abc');
    final container = fakeContainer(api, tokens: MemoryTokenStore('r1'));
    addTearDown(container.dispose);
    final attachments = container.read(attachmentRepositoryProvider);
    final file = attachment('att-1', 'a/b.txt', 5);

    final first = await attachments.download(file);
    final second = await attachments.download(file);

    expect(first.path, second.path);
    expect(first.path, endsWith('/attachments/att-1/a_b.txt'));
    expect(api.count('GET /api/v1/attachments/att-1'), 1);
  });

  test('a deleted attachment is reported as not found', () async {
    final api = signedInApi();
    api.routes['GET /api/v1/attachments/gone'] = (_) => problem(404, 'attachment-not-found');
    final container = fakeContainer(api, tokens: MemoryTokenStore('r1'));
    addTearDown(container.dispose);

    await expectLater(
      container.read(attachmentRepositoryProvider).download(attachment('gone', 'x.png', 1)),
      throwsA(isA<AppError>().having((e) => e.code, 'code', AttachmentCodes.notFound)),
    );
  });
}
