import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/daos/workout_dao.dart';
import '../../data/providers.dart';
import '../../data/reactive.dart';
import '../../l10n/app_l10n.dart';
import 'program_catalog.dart';
import 'program_labels.dart';

/// Programı rutinlere kopyalar — rutin adları aktif dilde yazılır (kopya
/// kullanıcının verisi olur, sonradan dil değişse de adı korunur).
Future<List<int>> installCatalogProgram(
        WorkoutDao dao, AppL10n l, CatalogProgram p) =>
    dao.installProgram(
      programKey: p.key,
      routines: [
        for (final r in p.routines)
          (
            name: l.catalogRoutineName(r.name),
            items: [
              for (final e in r.exercises)
                (
                  exercise: e.name,
                  sets: e.sets,
                  repsMin: e.repsMin,
                  repsMax: e.repsMax,
                  restSec: e.restSec,
                ),
            ],
          ),
      ],
    );

/// Rutinlerde bulunan (aktif) program anahtarları — Keşfet kartında
/// "Rutinlerinde" rozeti. **Reaktif.**
final installedProgramsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.routines], () async {
    final routines = await ref.read(workoutDaoProvider).getActiveRoutines();
    return {for (final r in routines) ?r.programKey};
  });
});
