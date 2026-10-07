import '../../l10n/app_l10n.dart';
import 'program_catalog.dart';

/// Katalog yapısının metinleri (CONVENTIONS §5b — metin l10n'da).
extension ProgramLabels on AppL10n {
  String programLevel(ProgramLevel v) => switch (v) {
        ProgramLevel.beginner => exLevelBeginner,
        ProgramLevel.intermediate => exLevelIntermediate,
        ProgramLevel.advanced => exLevelAdvanced,
      };

  String programLevelDesc(ProgramLevel v) => switch (v) {
        ProgramLevel.beginner => exLevelBeginnerDesc,
        ProgramLevel.intermediate => exLevelIntermediateDesc,
        ProgramLevel.advanced => exLevelAdvancedDesc,
      };

  String programSplit(ProgramSplit v) => switch (v) {
        ProgramSplit.fullBody => exSplitFullBody,
        ProgramSplit.upperLower => exSplitUpperLower,
        ProgramSplit.ppl => exSplitPpl,
      };

  String programSplitDesc(ProgramSplit v) => switch (v) {
        ProgramSplit.fullBody => exSplitFullBodyDesc,
        ProgramSplit.upperLower => exSplitUpperLowerDesc,
        ProgramSplit.ppl => exSplitPplDesc,
      };

  String programTitle(CatalogProgram p) =>
      exProgramTitle(programSplit(p.split), programLevel(p.level));

  String catalogRoutineName(CatalogRoutineName n) => switch (n) {
        CatalogRoutineName.fullBodyA => exRoutineFullBodyA,
        CatalogRoutineName.fullBodyB => exRoutineFullBodyB,
        CatalogRoutineName.fullBodyC => exRoutineFullBodyC,
        CatalogRoutineName.upper => exRoutineUpper,
        CatalogRoutineName.lower => exRoutineLower,
        CatalogRoutineName.upperA => exRoutineUpperA,
        CatalogRoutineName.lowerA => exRoutineLowerA,
        CatalogRoutineName.upperB => exRoutineUpperB,
        CatalogRoutineName.lowerB => exRoutineLowerB,
        CatalogRoutineName.upperPower => exRoutineUpperPower,
        CatalogRoutineName.lowerPower => exRoutineLowerPower,
        CatalogRoutineName.upperHypertrophy => exRoutineUpperHypertrophy,
        CatalogRoutineName.lowerHypertrophy => exRoutineLowerHypertrophy,
        CatalogRoutineName.push => exRoutinePush,
        CatalogRoutineName.pull => exRoutinePull,
        CatalogRoutineName.legs => exRoutineLegs,
      };
}
