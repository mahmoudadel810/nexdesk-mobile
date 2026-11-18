import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

/// Small JSON documents the app shows before the network answers, keyed by what they hold
/// (for example `session`, `tickets:mine:1`). Later steps add typed tables where lists need queries.
class CachedDocuments extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get storedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [CachedDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device file, in app-private storage.
  factory AppDatabase.onDevice() => AppDatabase(driftDatabase(name: 'nexdesk'));

  @override
  int get schemaVersion => 1;

  Future<void> put(String key, String json, DateTime now) =>
      into(cachedDocuments)
          .insertOnConflictUpdate(CachedDocumentsCompanion.insert(key: key, json: json, storedAt: now));

  Future<CachedDocument?> read(String key) =>
      (select(cachedDocuments)..where((d) => d.key.equals(key))).getSingleOrNull();

  Future<void> remove(String key) => (delete(cachedDocuments)..where((d) => d.key.equals(key))).go();

  /// Keeps the [count] most recently stored documents whose key starts with [prefix].
  Future<void> keepNewest(String prefix, int count) async {
    final keep =
        await (selectOnly(cachedDocuments)
              ..addColumns([cachedDocuments.key])
              ..where(cachedDocuments.key.like('$prefix%'))
              ..orderBy([OrderingTerm.desc(cachedDocuments.storedAt)])
              ..limit(count))
            .map((row) => row.read(cachedDocuments.key)!)
            .get();
    await (delete(cachedDocuments)..where((d) => d.key.like('$prefix%') & d.key.isNotIn(keep))).go();
  }

  /// Everything goes on sign-out, so the next person on this phone sees nothing of the last one.
  Future<void> wipe() => delete(cachedDocuments).go();
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.onDevice();
  ref.onDispose(database.close);
  return database;
});
