import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';

/// Bellek-içi (in-memory) test veritabanı fabrikası.
///
/// Her test taze, izole bir DB alır — diske dokunmaz, hızlıdır.
/// Kullanım:
/// ```dart
/// late AppDatabase db;
/// setUp(() => db = newTestDatabase());
/// tearDown(() => db.close());
/// ```
AppDatabase newTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());
