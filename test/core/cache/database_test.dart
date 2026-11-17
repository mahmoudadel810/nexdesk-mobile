import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/cache/database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('stores, replaces and wipes cached documents', () async {
    final now = DateTime.utc(2026, 11, 18, 9);
    await database.put('session', '{"user":"maya"}', now);
    await database.put('session', '{"user":"tom"}', now.add(const Duration(minutes: 1)));

    final stored = await database.read('session');
    expect(stored?.json, '{"user":"tom"}');
    expect(stored!.storedAt.isAtSameMomentAs(now.add(const Duration(minutes: 1))), isTrue);

    await database.wipe();
    expect(await database.read('session'), isNull);
  });
}
