import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/features/attachments/attachment_rules.dart';

const mb = 1024 * 1024;

void main() {
  test('up to 10 MB is accepted, one byte more is refused, as on the API', () {
    expect(checkAttachment('report.pdf', 10 * mb), isNull);
    expect(checkAttachment('report.pdf', 10 * mb + 1), AttachmentProblem.tooLarge);
    expect(checkAttachment('scan.pdf', 15 * mb), AttachmentProblem.tooLarge);
  });

  test('an empty file is refused, as on the API', () {
    expect(checkAttachment('empty.txt', 0), AttachmentProblem.tooLarge);
  });

  test('scripts and executables are refused whatever the case of the extension', () {
    expect(checkAttachment('deploy.sh', 200), AttachmentProblem.blockedType);
    expect(checkAttachment('SETUP.EXE', 200), AttachmentProblem.blockedType);
    expect(checkAttachment('archive.tar.jar', 200), AttachmentProblem.blockedType);
  });

  test('only the last extension counts, and a name without one is fine', () {
    expect(checkAttachment('deploy.sh.txt', 200), isNull);
    expect(checkAttachment('README', 200), isNull);
    expect(checkAttachment('.sh', 200), AttachmentProblem.blockedType);
  });

  test('photos are recognised by extension, HEIC included', () {
    expect(isPhoto('IMG_0001.HEIC'), isTrue);
    expect(isPhoto('photo.jpeg'), isTrue);
    expect(isPhoto('invoice.pdf'), isFalse);
  });

  test('content types follow the extension, with a safe default', () {
    expect(contentTypeOf('photo.JPG'), 'image/jpeg');
    expect(contentTypeOf('invoice.pdf'), 'application/pdf');
    expect(contentTypeOf('data.bin'), 'application/octet-stream');
  });

  test('sizes read as KB below a megabyte and MB above', () {
    expect(fileSizeText(1500), '2 KB');
    expect(fileSizeText((2.4 * mb).round()), '2.4 MB');
    expect(fileSizeText(10 * mb), '10 MB');
  });
}
