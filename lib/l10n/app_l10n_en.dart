// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fit Pack';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get accountErrorTitle => 'Couldn\'t verify account';

  @override
  String get accountErrorBody =>
      'We couldn\'t confirm that the data on this device belongs to you. For safety you weren\'t let in — another account\'s data could have been shown. Check your connection and try again.';

  @override
  String get accountConflictTitle => 'Unsynced records on this device';

  @override
  String accountConflictBody(int count) {
    return '$count records from the previous account haven\'t been uploaded yet. Continuing with the new account deletes them.';
  }

  @override
  String get accountConflictGoBack => 'Go back to previous account';

  @override
  String get accountConflictDiscard => 'Delete records and continue';

  @override
  String get accountConflictDiscardTitle => 'Delete records?';

  @override
  String accountConflictDiscardBody(int count) {
    return '$count records will be permanently deleted. This can\'t be undone.';
  }

  @override
  String get commonInvalidNumber => 'Invalid number';

  @override
  String commonRangeHint(String min, String max) {
    return 'Range: $min – $max';
  }

  @override
  String commonRangeError(String min, String max) {
    return 'Must be between $min and $max';
  }

  @override
  String get commonSaveFailed => 'Couldn\'t save, try again';

  @override
  String get commonDeleteFailed => 'Couldn\'t delete, try again';

  @override
  String get commonUndoFailed => 'Couldn\'t undo, try again';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroCalories => 'Calories';

  @override
  String get macroProteinAbbr => 'P';

  @override
  String get macroCarbsAbbr => 'C';

  @override
  String get macroFatAbbr => 'F';

  @override
  String get commonUndo => 'Undo';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navProgress => 'Progress';

  @override
  String get homeStatWorkouts => 'workouts';

  @override
  String homeStatVolume(String unit) {
    return '$unit volume';
  }

  @override
  String get homeStart => 'Start workout';

  @override
  String get homeStartTitle => 'Start a workout';

  @override
  String get homeStartSubtitle => 'Create a routine or start an empty workout';

  @override
  String homeUpNextSubtitle(int count, int mins) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · ~$mins min';
  }

  @override
  String get homeNoRoutineTitle => 'Pick your first workout';

  @override
  String get homeNoRoutineSubtitle =>
      'Start right away with a ready-made program or build your own routine.';

  @override
  String get homePickProgram => 'Pick a program';

  @override
  String get homeBuildRoutine => 'Build your own routine';

  @override
  String get homeFirstWeekTitle => 'FIRST WEEK';

  @override
  String homeFirstWeekProgress(int done) {
    return '$done/3 done';
  }

  @override
  String get homeFirstWeekWorkout => 'Finish your first workout';

  @override
  String get homeFirstWeekMeal => 'Log your first meal';

  @override
  String get homeFirstWeekWeight => 'Log your first weight';

  @override
  String homeTodayLiftIncrease(String exercise, String weight) {
    return '$exercise: try $weight this time.';
  }

  @override
  String homeTodayLiftAddRep(String exercise, String weight) {
    return '$exercise: try +1 rep per set at $weight.';
  }

  @override
  String get homeTodayFirstMeal => 'Add your first meal.';

  @override
  String homeTodayLeftBoth(int protein, int kcal) {
    return '$protein g protein, $kcal kcal left today.';
  }

  @override
  String homeTodayLeftProtein(int protein) {
    return '$protein g protein left today.';
  }

  @override
  String homeTodayLeftKcal(int kcal) {
    return '$kcal kcal left today.';
  }

  @override
  String get homeWeekReadyKicker => 'YOUR WEEK IS READY';

  @override
  String get homeWeekReadyTitle => 'Your weekly review is ready';

  @override
  String get homeWeekReadyOpen => 'Open';

  @override
  String get homeRestTitle => 'Rest day today';

  @override
  String homeRestNext(String name) {
    return 'Next: $name';
  }

  @override
  String get homeWorkoutAnyway => 'Work out anyway';

  @override
  String get nutritionKcalLeft => 'kcal left';

  @override
  String get nutritionKcalOver => 'kcal over';

  @override
  String get commonToday => 'Today';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonMustBePositive => 'Must be greater than 0';

  @override
  String get commonNotNegative => 'Can\'t be negative';

  @override
  String get commonEnterName => 'Enter a name';

  @override
  String get nutritionPickDate => 'Pick a date';

  @override
  String get nutritionAddFood => 'Add Food';

  @override
  String get nutritionLoadError => 'Couldn\'t load nutrition logs';

  @override
  String get nutritionCopyYesterday => 'Copy yesterday\'s meals';

  @override
  String get nutritionCopyPrevDay => 'Copy the previous day\'s meals';

  @override
  String get nutritionCopyEmpty => 'No entries on the previous day';

  @override
  String nutritionCopied(int count) {
    return '$count entries copied';
  }

  @override
  String get nutritionCopyFailed => 'Couldn\'t copy — try again';

  @override
  String get nutritionMealMenu => 'Meal options';

  @override
  String get nutritionCopyFromDay => 'Copy from another day';

  @override
  String nutritionCopyMealTitle(String meal) {
    return 'Copy $meal';
  }

  @override
  String get nutritionCopyPickDay => 'Pick the day to copy from';

  @override
  String nutritionCopyNoHistory(int days) {
    return 'No entries for this meal in the last $days days';
  }

  @override
  String get nutritionCopyEditHint =>
      'Adjust the amounts, drop what you don\'t want';

  @override
  String nutritionCopyAddCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get nutritionCopyRemove => 'Remove from list';

  @override
  String get nutritionPrevDay => 'Previous day';

  @override
  String get nutritionNextDay => 'Next day';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealSnackShort => 'Snack';

  @override
  String nutritionAddTo(String meal) {
    return 'Add to $meal';
  }

  @override
  String get nutritionNoEntries => 'No entries yet';

  @override
  String get nutritionAddFailed => 'Couldn\'t add — try again';

  @override
  String get nutritionOffNoResults =>
      'No results on OpenFoodFacts. You can add it manually.';

  @override
  String get nutritionMultiAddHint => 'You can add more than one';

  @override
  String nutritionSessionAdded(int count, String name) {
    return '$count added · last: $name';
  }

  @override
  String get nutritionSearchHint => 'Search foods…';

  @override
  String get nutritionScanBarcode => 'Scan barcode';

  @override
  String get nutritionAddCustom => 'Add your own food';

  @override
  String get nutritionOffSearching => 'Searching OpenFoodFacts…';

  @override
  String nutritionOffSearchFor(String query) {
    return 'Search packaged product online: \"$query\"';
  }

  @override
  String nutritionOffHeader(String query, int count) {
    return 'OpenFoodFacts · \"$query\" ($count)';
  }

  @override
  String get nutritionNoFoods => 'No foods';

  @override
  String nutritionNotFound(String query) {
    return '\"$query\" not found';
  }

  @override
  String get nutritionNotInListHint =>
      'If it\'s not in the list, add it yourself';

  @override
  String nutritionUnitApprox(String unit, int grams) {
    return '1 $unit ≈ $grams g';
  }

  @override
  String get nutritionCustomTitle => 'Your own food';

  @override
  String get nutritionCustomHelp =>
      'Enter the values for one unit (e.g. 1 portion of \"3-Egg Omelette\"): how many grams plus that amount\'s kcal/macros. It gets converted to /100g, saved and reused. No unit? Pick \"(no unit)\".';

  @override
  String get nutritionFoodName => 'Food name';

  @override
  String get nutritionUnit => 'Unit';

  @override
  String get nutritionNoUnitOption => '(no unit — grams only)';

  @override
  String nutritionOneUnit(String unit) {
    return '1 $unit';
  }

  @override
  String get nutritionPortionGrams => 'Portion (g)';

  @override
  String nutritionUnitGramsQuestion(String unit) {
    return 'How many grams is 1 $unit?';
  }

  @override
  String get nutritionTotalKcal => 'Total kcal';

  @override
  String get nutritionAdding => 'Adding…';

  @override
  String nutritionAlreadySaved(String name) {
    return '$name (already saved)';
  }

  @override
  String get nutritionOffQuerying => 'Querying OpenFoodFacts…';

  @override
  String nutritionProductNotFound(String code) {
    return 'Product not found ($code). You can add it manually.';
  }

  @override
  String nutritionAddedFromOff(String name) {
    return '$name added (OpenFoodFacts)';
  }

  @override
  String get scanTitle => 'Scan Barcode';

  @override
  String get scanTorchOn => 'Flashlight';

  @override
  String get scanTorchOff => 'Turn off flashlight';

  @override
  String get scanPermissionDenied =>
      'Camera permission denied. Allow it in Settings or add the food manually.';

  @override
  String get scanCameraError =>
      'Camera couldn\'t start. You can add the food manually.';

  @override
  String get scanFrameHint => 'Line up the barcode in the frame';

  @override
  String get scanManualAdd => 'Add manually';

  @override
  String get foodsNew => 'New food';

  @override
  String get foodCatMeat => 'Meat, fish, eggs';

  @override
  String get foodCatDairy => 'Dairy';

  @override
  String get foodCatGrain => 'Grains & starches';

  @override
  String get foodCatLegume => 'Legumes';

  @override
  String get foodCatVegetable => 'Vegetables';

  @override
  String get foodCatFruit => 'Fruit';

  @override
  String get foodCatFat => 'Fats & nuts';

  @override
  String get foodCatDish => 'Prepared dishes';

  @override
  String get foodCatOther => 'Other';

  @override
  String foodsAdded(String name) {
    return '$name added';
  }

  @override
  String get foodsUpdated => 'Updated';

  @override
  String foodsHasLogs(String name, int count) {
    return '\"$name\" has $count log entries — delete those first';
  }

  @override
  String get foodsDeleteTitle => 'Delete food';

  @override
  String foodsDeleteMessage(String name) {
    return 'Remove \"$name\" from the food database?';
  }

  @override
  String foodsDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get foodsPer100g => 'Per 100 g';

  @override
  String get foodsReadOnlyNote =>
      'Built-in food — can\'t be edited (the database is protected).';

  @override
  String get foodsLoadError => 'Couldn\'t load foods';

  @override
  String get foodsEmptyHint => 'Add a new food from the bottom right';

  @override
  String get foodsEditTitle => 'Edit food';

  @override
  String get foodsFormHelp =>
      'Values are entered per 100 grams. If you pick a unit, also enter \"grams per 1 unit\" — then you can log by piece/slice.';

  @override
  String get foodsKcalPer100 => 'Calories /100g (kcal)';

  @override
  String get foodsProteinPer100 => 'Protein /100g (g)';

  @override
  String get foodsCarbPer100 => 'Carbs /100g (g)';

  @override
  String get foodsFatPer100 => 'Fat /100g (g)';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonDate => 'Date';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonNone => 'None';

  @override
  String get unitMinShort => 'min';

  @override
  String get unitReps => 'reps';

  @override
  String get labelSets => 'Sets';

  @override
  String get labelReps => 'Reps';

  @override
  String get labelRest => 'Rest';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelVolume => 'Volume';

  @override
  String get workoutLoadRoutinesError => 'Couldn\'t load routines';

  @override
  String get workoutLibrary => 'Exercise Library';

  @override
  String get workoutAddPast => 'Add Past Workout';

  @override
  String get workoutHistory => 'Workout History';

  @override
  String get wcalTitle => 'Workout calendar';

  @override
  String get wcalEmpty => 'No workout logged on this day.';

  @override
  String get wcalAddForDay => 'Log a workout for this day';

  @override
  String wcalMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workout days this month',
      one: '1 workout day this month',
      zero: 'No workouts this month',
    );
    return '$_temp0';
  }

  @override
  String get workoutThisWeekCaps => 'THIS WEEK';

  @override
  String get workoutTotalVolumeCaps => 'TOTAL VOLUME';

  @override
  String get workoutStartEmpty => 'Start Empty Workout';

  @override
  String get workoutNewRoutine => 'Create New Routine';

  @override
  String get workoutMyRoutines => 'My Routines';

  @override
  String get workoutNoRoutines => 'No routines yet';

  @override
  String get workoutNoRoutinesMsg =>
      'Create your own workout routine — pick exercises, set target sets and reps.';

  @override
  String get workoutCreateRoutine => 'Create routine';

  @override
  String get workoutResumeTitle => 'Workout in progress';

  @override
  String workoutResumeSub(int ex, int sets) {
    return '$ex exercises · $sets sets';
  }

  @override
  String get workoutDraftDelete => 'Discard draft';

  @override
  String get workoutDraftDeleteMsg =>
      'Discard the in-progress workout draft? Your entered sets won\'t be saved.';

  @override
  String workoutExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String workoutSetCount(int count) {
    return '$count sets';
  }

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exSubtitle =>
      'Ready-made programs — add one and its routines become yours to edit.';

  @override
  String get exLevelBeginner => 'Beginner';

  @override
  String get exLevelIntermediate => 'Intermediate';

  @override
  String get exLevelAdvanced => 'Advanced';

  @override
  String get exSplitFullBody => 'Full body';

  @override
  String get exSplitUpperLower => 'Upper / Lower';

  @override
  String get exSplitPpl => 'Push · Pull · Legs';

  @override
  String get exSplitFullBodyDesc =>
      'Whole body every session. Short, efficient — ideal if you train 3 days a week.';

  @override
  String get exSplitUpperLowerDesc =>
      'Upper and lower body on alternating days. More volume per muscle, 4 days a week.';

  @override
  String get exSplitPplDesc =>
      'Pushing, pulling and legs on separate days. Classic bodybuilding split.';

  @override
  String get exLevelBeginnerDesc =>
      'Mostly machines, moderate reps — learn the movements safely.';

  @override
  String get exLevelIntermediateDesc =>
      'Barbell basics plus accessories, double progression.';

  @override
  String get exLevelAdvancedDesc =>
      'Heavy low-rep main lifts and higher weekly volume.';

  @override
  String exDaysPerWeek(int count) {
    return '$count days/week';
  }

  @override
  String exRoutineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String exProgramTitle(String split, String level) {
    return '$split · $level';
  }

  @override
  String get exAddProgram => 'Add program';

  @override
  String get exAddAgainTitle => 'Already in your routines';

  @override
  String get exAddAgainMsg =>
      'This program\'s routines are already in your list. Add another copy?';

  @override
  String get exAddAgain => 'Add again';

  @override
  String exAdded(String name) {
    return '$name added to your routines';
  }

  @override
  String get exAddError => 'Couldn\'t add the program — try again';

  @override
  String get exHowTo =>
      'Rotate the routines in order, e.g. A → B → A. Targets are a starting point; the app suggests the next step from your sets.';

  @override
  String get exFreeWorkout => 'Free workout';

  @override
  String get exInList => 'In your routines';

  @override
  String get exRoutineFullBodyA => 'Full Body A';

  @override
  String get exRoutineFullBodyB => 'Full Body B';

  @override
  String get exRoutineFullBodyC => 'Full Body C';

  @override
  String get exRoutineUpper => 'Upper';

  @override
  String get exRoutineLower => 'Lower';

  @override
  String get exRoutineUpperA => 'Upper A';

  @override
  String get exRoutineLowerA => 'Lower A';

  @override
  String get exRoutineUpperB => 'Upper B';

  @override
  String get exRoutineLowerB => 'Lower B';

  @override
  String get exRoutineUpperPower => 'Upper · Strength';

  @override
  String get exRoutineLowerPower => 'Lower · Strength';

  @override
  String get exRoutineUpperHypertrophy => 'Upper · Volume';

  @override
  String get exRoutineLowerHypertrophy => 'Lower · Volume';

  @override
  String get exRoutinePush => 'Push';

  @override
  String get exRoutinePull => 'Pull';

  @override
  String get exRoutineLegs => 'Legs';

  @override
  String get workoutOwnRoutines => 'My own';

  @override
  String get whRecentTitle => 'Recent workouts';

  @override
  String get whSeeAll => 'See all';

  @override
  String whMoreExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more exercises',
      one: '+1 more exercise',
    );
    return '$_temp0';
  }

  @override
  String whRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String whVsLast(String value) {
    return 'vs last time: $value';
  }

  @override
  String whDeltaReps(String delta) {
    return '$delta reps';
  }

  @override
  String get whDeltaSame => 'same as last time';

  @override
  String get whMuscles => 'Muscles worked';

  @override
  String get whAvgRpe => 'Avg RPE';

  @override
  String get whNotes => 'Note';

  @override
  String whSetsWithRpe(String rpe) {
    return 'RPE $rpe';
  }

  @override
  String get whRpeLegend => 'RPE = Rate of Perceived Exertion, 10 is all-out.';

  @override
  String get workoutAddExercise => 'Add Exercise';

  @override
  String get rbEditTitle => 'Edit Routine';

  @override
  String get rbNewTitle => 'New Routine';

  @override
  String get rbNameCaps => 'ROUTINE NAME';

  @override
  String get rbNameHint => 'e.g. Push Day';

  @override
  String get rbNoExercises => 'No exercises yet';

  @override
  String get rbWeekday => 'Weekly day (optional)';

  @override
  String get rbWeekdayHelper =>
      'If set, Home suggests this routine on that day';

  @override
  String get rbNoDay => 'No day';

  @override
  String get rbRestBetweenSets => 'Rest between sets';

  @override
  String get rbNameRequired => 'Give the routine a name';

  @override
  String get rbNeedExercise => 'Add at least one exercise';

  @override
  String get rbSaveError => 'Couldn\'t save routine — try again';

  @override
  String get rbTargetHint => 'target sets×reps';

  @override
  String get rbSave => 'Save Routine';

  @override
  String get whLoadError => 'Couldn\'t load history';

  @override
  String get whEmptyTitle => 'No workouts yet';

  @override
  String get whEmptyMsg => 'Your first completed workout will appear here';

  @override
  String get whEditDate => 'Edit date';

  @override
  String get whDeleteTitle => 'Delete workout';

  @override
  String get whDeleteMsg =>
      'This session and all its sets will be deleted. Can\'t be undone.';

  @override
  String get whNoSets => 'No set records';

  @override
  String get whCalorieNote =>
      'Calories are an estimate — based on weight, duration and intensity (RPE).';

  @override
  String get wsTitle => 'Workout Summary';

  @override
  String get wsLoadError => 'Couldn\'t load summary';

  @override
  String get wsDone => 'Workout Complete';

  @override
  String get wsExercises => 'Exercises';

  @override
  String wsNewRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new records',
      one: 'New record',
    );
    return '$_temp0';
  }

  @override
  String get wsDoneBtn => 'Done';

  @override
  String get wsUnknownExercise => 'Exercise';

  @override
  String get rpFallback => 'Routine';

  @override
  String get rpArchiveTitle => 'Archive routine';

  @override
  String get rpArchiveMsg =>
      'It moves to Archive at the bottom of the Workout tab; you can restore it anytime. Past workouts are kept.';

  @override
  String get rpArchived => 'Routine archived';

  @override
  String workoutArchiveSection(int count) {
    return 'Archive ($count)';
  }

  @override
  String get workoutArchiveRestore => 'Restore';

  @override
  String workoutArchiveRestored(String name) {
    return '$name is back in your routines';
  }

  @override
  String get workoutArchiveHint =>
      'Archived routines don\'t appear in your list or schedule. Past workouts stay in history.';

  @override
  String get rpStart => 'Start Workout';

  @override
  String get rpLoadError => 'Couldn\'t load routine';

  @override
  String get rpEmptyTitle => 'This routine is empty';

  @override
  String get rpEmptyMsg => 'Add exercises via Edit';

  @override
  String get asPastWorkout => 'Past Workout';

  @override
  String get asEmptyWorkout => 'Empty Workout';

  @override
  String liveSetLabel(int n, int total) {
    return 'Set $n/$total';
  }

  @override
  String get liveAllDone => 'All sets done';

  @override
  String get liveRestOver => 'Rest over';

  @override
  String get liveNext => 'Next';

  @override
  String get liveCompleteSet => 'Complete set';

  @override
  String get liveAddRest => '+15 s';

  @override
  String get liveSkipRest => 'Skip';

  @override
  String get liveElapsed => 'Time';

  @override
  String get asPastEntry => 'Past entry';

  @override
  String asSetProgress(int done, int total) {
    return '$done/$total sets';
  }

  @override
  String get asFinish => 'Finish';

  @override
  String get asExitTitle => 'Leave workout?';

  @override
  String get asExitMsg => 'Your entered sets won\'t be saved.';

  @override
  String get asKeepGoing => 'Keep going';

  @override
  String get asLeave => 'Leave';

  @override
  String get asRemoveExercise => 'Remove exercise';

  @override
  String asRemoveExerciseMsg(String name) {
    return '$name and your entered sets will be deleted.';
  }

  @override
  String get asRemove => 'Remove';

  @override
  String get asNeedOneSet => 'Enter at least one set first';

  @override
  String get asNewRecord => 'New record';

  @override
  String get asSaveError => 'Couldn\'t save workout — try again';

  @override
  String get asStartFromLibrary => 'Start by adding exercises from the library';

  @override
  String get asAddSet => 'Add Set';

  @override
  String get asRemoveSet => 'Remove';

  @override
  String get asHowTo => 'How to do it';

  @override
  String get asExerciseOptions => 'Exercise options';

  @override
  String get asSkip => 'Skip';

  @override
  String get hdrSet => 'SET';

  @override
  String get hdrPrev => 'PREV';

  @override
  String get hdrKg => 'KG';

  @override
  String get hdrReps => 'REPS';

  @override
  String get hdrTime => 'TIME';

  @override
  String get hdrDistance => 'DISTANCE';

  @override
  String get rpeTitle => 'RPE — Perceived Exertion';

  @override
  String get rpeHelp =>
      'You rate how hard the set felt from 1 to 10. It\'s based on \"how many more reps could you have done?\". Optional — you can leave it empty.';

  @override
  String get rpe10 => 'Last rep — couldn\'t have done one more';

  @override
  String get rpe9 => 'Could have done 1 more rep';

  @override
  String get rpe8 => '2 reps left in reserve';

  @override
  String get rpe7 => '3-4 reps in reserve';

  @override
  String get rpe6 => 'Easy / warm-up set';

  @override
  String rpePick_title(int set) {
    return 'Set $set RPE';
  }

  @override
  String get rpePick_select => 'Select RPE';

  @override
  String get rpePick_done => 'Done';

  @override
  String get rpePick_clear => 'Clear';

  @override
  String get rpeEffort_light => 'Light effort';

  @override
  String get rpeEffort_moderate => 'Moderate effort';

  @override
  String get rpeEffort_vigorous => 'Vigorous effort';

  @override
  String get rpeEffort_veryHard => 'Very hard effort';

  @override
  String get rpeEffort_extremelyHard => 'Extremely hard effort';

  @override
  String get rpeEffort_max => 'Max effort';

  @override
  String get rpeRir_none => 'No more reps possible';

  @override
  String rpeRir_exact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Could have done $count more reps',
      one: 'Could have done 1 more rep',
    );
    return '$_temp0';
  }

  @override
  String rpeRir_range(int min, int max) {
    return 'Could have done $min–$max more reps';
  }

  @override
  String rpeRir_atLeast(int count) {
    return 'Could have done $count+ more reps';
  }

  @override
  String get rbAddWarmUp => 'Add warm-up';

  @override
  String get rbAddWarmUpHint => 'Puts a dynamic full-body warm-up at the start';

  @override
  String get rbWarmUpMissing => 'Warm-up exercise not found in the library';

  @override
  String rpSetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get asTimerStart => 'Start timer';

  @override
  String get asTimerStop => 'Stop timer';

  @override
  String get elPickTitle => 'Pick Exercise';

  @override
  String get elSearchHint => 'Search exercises…';

  @override
  String get elRecent => 'Recently used';

  @override
  String get elLoadError => 'Couldn\'t load exercises';

  @override
  String get elNotFoundTitle => 'No exercises found';

  @override
  String get elFilterHint => 'Change the filter or add a new exercise';

  @override
  String get elNew => 'New Exercise';

  @override
  String get elAdded => 'Exercise added';

  @override
  String get elNameLabel => 'Exercise name (e.g. Cable Row)';

  @override
  String get elCategory => 'Category';

  @override
  String get elPrimaryMuscle => 'Primary muscle';

  @override
  String get elEquipment => 'Equipment';

  @override
  String get elMeasureType => 'Measurement type';

  @override
  String get measureWeightReps => 'weight × reps';

  @override
  String get measureReps => 'reps';

  @override
  String get measureTime => 'time';

  @override
  String get measureDistance => 'distance';

  @override
  String get edFallbackTitle => 'Exercise';

  @override
  String get edArchiveTitle => 'Archive exercise';

  @override
  String edArchiveMsg(String name) {
    return 'Remove $name from the library? Past records are kept.';
  }

  @override
  String get edTabHow => 'How';

  @override
  String get edTabHistory => 'History';

  @override
  String get edTabChart => 'Chart';

  @override
  String get edTabRecords => 'Records';

  @override
  String get edMusclesWorked => 'Muscles Worked';

  @override
  String get edPrimary => 'Primary';

  @override
  String get edSecondary => 'Secondary';

  @override
  String get edNoInstructions => 'No instructions';

  @override
  String get edNoInstructionsMsg => 'No step-by-step guide for this exercise';

  @override
  String get edHowTo => 'How To';

  @override
  String get edLevelBeginner => 'Beginner';

  @override
  String get edLevelIntermediate => 'Intermediate';

  @override
  String get edLevelExpert => 'Advanced';

  @override
  String get edForcePush => 'Push';

  @override
  String get edForcePull => 'Pull';

  @override
  String get edForceStatic => 'Static';

  @override
  String get edLoadError => 'Couldn\'t load';

  @override
  String get edAppearsHere =>
      'Appears here once you use this exercise in a workout';

  @override
  String get edSetHistory => 'Set history';

  @override
  String get edChartEmpty => 'Not enough data for a chart';

  @override
  String get edChartEmptyMsg =>
      'Log weight×reps at least twice to see the progress chart';

  @override
  String get edE1rmTitle => 'Estimated 1RM progress';

  @override
  String get edEpley => 'Epley: weight × (1 + reps/30)';

  @override
  String get edNoPr => 'No records yet';

  @override
  String get edNoPrMsg =>
      'Your personal records collect here once you log weight×reps';

  @override
  String get edBestE1rm => 'Estimated 1RM';

  @override
  String get edHeaviest => 'Heaviest set';

  @override
  String get edTotalLogs => 'Total logged';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get commonCloseApp => 'Close App';

  @override
  String get bmAddMeasurement => 'Add Measurement';

  @override
  String get bmLoadError => 'Couldn\'t load measurements';

  @override
  String get bmEmptyTitle => 'No measurements yet';

  @override
  String get bmEmptyMsg =>
      'Track your progress by adding your first body measurement';

  @override
  String get bmAddFirst => 'Add your first measurement';

  @override
  String get bmPastMeasurements => 'Past Measurements';

  @override
  String get bmDeleteTitle => 'Delete measurement';

  @override
  String bmDeleteMsg(String date) {
    return 'Delete the measurement from $date?';
  }

  @override
  String get bmWeightTrend => 'Weight Trend';

  @override
  String bmGoalLine(String value) {
    return 'Goal $value';
  }

  @override
  String get bmLatest => 'Latest Measurements';

  @override
  String get bmWeight => 'Weight';

  @override
  String bmDiffSince(String date) {
    return 'vs. $date';
  }

  @override
  String get bmWaist => 'Waist';

  @override
  String get bmArm => 'Arm';

  @override
  String get bmChest => 'Chest';

  @override
  String get bmHip => 'Hip';

  @override
  String get bmNeck => 'Neck';

  @override
  String get bmBodyFat => 'Body Fat';

  @override
  String get bmNeedOneValue => 'Enter at least one value';

  @override
  String get bmSaveFailed => 'Couldn\'t save — try again';

  @override
  String get bmNewMeasurement => 'New Measurement';

  @override
  String get bmSheetSubtitle => 'Empty fields aren\'t saved';

  @override
  String get actTitle => 'Activity';

  @override
  String get actLoadError => 'Couldn\'t load calendar';

  @override
  String get actNoEntry => 'No entries for this day.';

  @override
  String get exTitle => 'Export Data';

  @override
  String get exNoData => 'No data to export in the selected range';

  @override
  String get exShareFailed => 'Sharing failed, try again';

  @override
  String get exHeadline => 'Export your data, analyze it with AI';

  @override
  String get exFormat => 'Format';

  @override
  String get exDateRange => 'Date Range';

  @override
  String get exWeek => '1 Week';

  @override
  String get exMonth => '1 Month';

  @override
  String get exAll => 'All';

  @override
  String get exScope => 'Scope';

  @override
  String get exScopeAll => 'All';

  @override
  String get exPreparing => 'Preparing…';

  @override
  String get exShareBtn => 'Export & Share';

  @override
  String get cloudSignupOk => 'Registered. Verify your email, then sign in.';

  @override
  String cloudConnErr(String err) {
    return 'Couldn\'t connect: $err';
  }

  @override
  String get cloudSignIn => 'Sign in';

  @override
  String get cloudCreateAccount => 'Create account';

  @override
  String get cloudIntro =>
      'Sign in — your workouts, meals and measurements are saved to your account automatically.';

  @override
  String get cloudEmail => 'Email';

  @override
  String get cloudPassword => 'Password (min 6 characters)';

  @override
  String get cloudSignInBtn => 'Sign In';

  @override
  String get cloudSignUpBtn => 'Sign Up';

  @override
  String get cloudGoogle => 'Continue with Google';

  @override
  String get cloudOrEmail => 'or continue with email';

  @override
  String get cloudForgot => 'Forgot your password?';

  @override
  String get cloudForgotTitle => 'Reset password';

  @override
  String get cloudForgotMsg =>
      'We\'ll email you a link to set a new password. Open it on this device.';

  @override
  String get cloudForgotSend => 'Send link';

  @override
  String get cloudForgotSent =>
      'If an account exists for that address, a reset link is on its way.';

  @override
  String get cloudResetTitle => 'Set a new password';

  @override
  String get cloudResetIntro =>
      'Choose a new password for your account. You\'ll be signed in right after.';

  @override
  String get cloudResetNew => 'New password (min 6 characters)';

  @override
  String get cloudResetRepeat => 'New password (again)';

  @override
  String get cloudResetMismatch => 'Passwords don\'t match.';

  @override
  String get cloudResetSave => 'Save password';

  @override
  String get cloudResetOk => 'Your password has been updated.';

  @override
  String get cloudResetCancel => 'Cancel and sign out';

  @override
  String get cloudNoAccount => 'No account? Sign up';

  @override
  String get cloudHaveAccount => 'Already have an account? Sign in';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Your data is safe on this device and will sync once you update.';

  @override
  String get updateRequiredAction => 'Update';

  @override
  String get cloudSignOut => 'Sign Out';

  @override
  String get cloudSyncNow => 'Sync now';

  @override
  String get cloudSyncDone => 'Synced';

  @override
  String cloudSyncPending(int count) {
    return '$count records are still waiting — check your connection';
  }

  @override
  String get cloudSyncFailed =>
      'Couldn\'t sync — your data is safe on this device';

  @override
  String get cloudDeleteAccount => 'Delete Account';

  @override
  String get cloudDeleteHint =>
      'Permanently deletes your account and the data stored in the cloud.';

  @override
  String get cloudDeleteTitle => 'Delete account';

  @override
  String get cloudDeleteMsg =>
      'Your cloud account and cloud backup will be permanently deleted. Data on this device is not affected.';

  @override
  String get cloudDeleteConfirm2Title => 'Are you sure?';

  @override
  String get cloudDeleteConfirm2Msg =>
      'This is the last step — your account can\'t be recovered afterwards.';

  @override
  String get cloudDeleted => 'Your account has been deleted';

  @override
  String cloudDeleteFailed(String error) {
    return 'Couldn\'t delete account: $error';
  }

  @override
  String get unitPortion => 'portion';

  @override
  String get unitPiece => 'piece';

  @override
  String get unitSlice => 'slice';

  @override
  String get unitBowl => 'bowl';

  @override
  String get unitWaterGlass => 'glass';

  @override
  String get unitCup => 'cup';

  @override
  String get unitTablespoon => 'tablespoon';

  @override
  String get unitHandful => 'handful';

  @override
  String get unitClove => 'clove';

  @override
  String get unitScoop => 'scoop';

  @override
  String get unitCan => 'can';

  @override
  String get homeInsightLabel => 'INSIGHT';

  @override
  String homeInsightMostImproved(String name) {
    return 'Most improved: $name';
  }

  @override
  String get homeInsightSubtitle =>
      'Your estimated 1RM rose in the last 6 weeks';

  @override
  String get homeWaterTitle => 'Water';

  @override
  String homeWaterAmount(String current, String goal) {
    return '$current / $goal L';
  }

  @override
  String get homeWaterAdd => '+250 ml';

  @override
  String get homeWeightTitle => 'Latest weight';

  @override
  String get homeWeightEmpty => 'Log your first weight';

  @override
  String get unitKg => 'kg';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileNotFound => 'Profile not found';

  @override
  String get settingsProfileNotFoundHint => 'Try restarting the app';

  @override
  String get settingsLoadError => 'Couldn\'t load settings';

  @override
  String get settingsSectionGoals => 'Goals';

  @override
  String get settingsSectionBody => 'Body';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionNutrition => 'Nutrition';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSectionIdentity => 'Identity & Energy';

  @override
  String get profileMeasurements => 'Measurements';

  @override
  String get profileMeasurementsSubtitle => 'Weight, waist, arm — tap to log';

  @override
  String get homeProfileTooltip => 'Profile';

  @override
  String get settingsLicenses => 'Open-Source Licenses';

  @override
  String get settingsAttribution => 'Open Data Sources';

  @override
  String get settingsAttributionSubtitle =>
      'Exercise & food databases the app builds on';

  @override
  String get settingsFeedback => 'Send Feedback';

  @override
  String get settingsFeedbackSubtitle => 'Report a problem or share an idea';

  @override
  String get settingsWeekStart => 'Week Starts On';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Rest timer, workout & water reminders';

  @override
  String get notifRestTimer => 'Rest timer alert';

  @override
  String get notifRestTimerSub =>
      'Notifies when rest ends while the app is in the background';

  @override
  String get notifRestSound => 'Rest timer sound';

  @override
  String get notifRestSoundSub =>
      'Beeps for the last 3 seconds and when rest ends. Uses media volume and plays over your music.';

  @override
  String get restSoundTitle => 'Rest sound';

  @override
  String get restSoundSheetSub =>
      'Plays in the last 3 seconds and when rest ends. Tap to choose and listen.';

  @override
  String get restSoundPreview => 'Listen';

  @override
  String get restSoundDigitalBeep => 'Digital beep';

  @override
  String get restSoundDigitalBeepHint => 'Short beeps, one long start tone';

  @override
  String get restSoundClassicBell => 'Classic bell';

  @override
  String get restSoundClassicBellHint => 'A single clear bell strike';

  @override
  String get restSoundBoxingBell => 'Boxing bell';

  @override
  String get restSoundBoxingBellHint => 'Ring bell: ding-ding-ding';

  @override
  String get restSoundSoftChime => 'Soft chime';

  @override
  String get restSoundSoftChimeHint => 'Gentle, quiet chord';

  @override
  String get restSoundStrongAlert => 'Strong alert';

  @override
  String get restSoundStrongAlertHint => 'Loud two-tone alarm for noisy gyms';

  @override
  String get notifIosSoundOff => 'Sound is off for Fit Pack notifications';

  @override
  String get notifIosSoundOffSub =>
      'Turn it on in iPhone Settings › Notifications › Fit Pack › Sounds.';

  @override
  String get notifRestIosNote =>
      'When the app is in the background, iPhone plays the rest alert as a notification: it is silent when the phone is on silent mode or a Focus filters it. With the app open, the sound always plays.';

  @override
  String get notifWorkout => 'Workout reminder';

  @override
  String get notifWater => 'Daily water reminder';

  @override
  String get notifTime => 'Time';

  @override
  String get notifPermissionDenied =>
      'Notification permission denied — enable it in system settings.';

  @override
  String get notifRestDoneTitle => 'Rest over';

  @override
  String get notifRestDoneBody => 'Time for the next set';

  @override
  String get notifRestEndingTitle => 'Rest ends in 3 seconds';

  @override
  String get notifRestEndingBody => 'Get ready for the next set';

  @override
  String get notifWorkoutTitle => 'Workout time';

  @override
  String get notifWorkoutBody =>
      'Your plan is waiting — a short session counts too.';

  @override
  String get notifWorkoutSub =>
      'If you take a 2-day break, reminds you of your next workout at your usual time.';

  @override
  String get notifWorkoutFallbackTime => 'Default time';

  @override
  String get notifWorkoutFallbackTimeSub =>
      'The time comes from your workout history; this one is used until there is history.';

  @override
  String get notifRecallTitle => 'Your next workout is ready';

  @override
  String get notifRecallTitle2 => 'A short session counts too';

  @override
  String get notifRecallTitle3 => 'Is today a good day?';

  @override
  String notifRecallBodyRoutine(String routine, int minutes) {
    return 'Up next: $routine · ~$minutes min';
  }

  @override
  String notifRecallBodyRoutineOnly(String routine) {
    return 'Up next: $routine';
  }

  @override
  String get notifRecallBody =>
      'Pick a routine or start an empty workout — a few sets do the job.';

  @override
  String notifMissedTitle(String routine) {
    return 'Today was $routine day';
  }

  @override
  String get notifMissedBody =>
      'Tomorrow works too. If you have time, a short session now still counts.';

  @override
  String get notifFirstWeekTitle => 'Ready for your first workout?';

  @override
  String notifFirstWeekBodyRoutine(String routine, int minutes) {
    return 'Your first workout is ready: $routine · ~$minutes min';
  }

  @override
  String notifFirstWeekBodyRoutineOnly(String routine) {
    return 'Your first workout is ready: $routine';
  }

  @override
  String get notifFirstWeekBody =>
      'Pick one of the ready-made programs or start an empty workout.';

  @override
  String get recallOfferTitle => 'Want a reminder for your next workout?';

  @override
  String get recallOfferBody =>
      'If you take a 2-day break or miss a planned day, I\'ll remind you around your usual time (at most 2 a day). Turn it off in Settings → Notifications.';

  @override
  String get recallOfferOnbTitle => 'Want reminders for your workouts?';

  @override
  String get recallOfferOnbBody =>
      'I\'ll remind you of your first workout, and of the next one if you take a 2-day break (at most 2 a day). Turn it off in Settings → Notifications.';

  @override
  String get recallOfferYes => 'Yes, remind me';

  @override
  String get recallOfferNo => 'Not now';

  @override
  String get recallOfferEnabled =>
      'Done — I\'ll remind you after a 2-day break.';

  @override
  String get notifWaterTitle => 'Water break';

  @override
  String get notifWaterBody => 'A glass of water now keeps your ring on track.';

  @override
  String get unitsMetric => 'Metric (kg, cm)';

  @override
  String get unitsImperial => 'Imperial (lb, ft)';

  @override
  String get attribIntro =>
      'Fit Pack is built on these open datasets and libraries. Thank you to their maintainers!';

  @override
  String get attribOffDesc =>
      'Packaged food nutrition data (barcode & text search)';

  @override
  String get attribFedDesc => 'Exercise library, instructions and demo photos';

  @override
  String get attribMuscleDesc => 'Body muscle map visual';

  @override
  String attribLicense(String name) {
    return 'License: $name';
  }

  @override
  String get settingsKcalGoal => 'Calorie Goal';

  @override
  String get settingsProteinGoal => 'Protein Goal';

  @override
  String get settingsHeight => 'Height';

  @override
  String get settingsGoalWeight => 'Goal Weight';

  @override
  String get settingsGender => 'Gender';

  @override
  String get settingsBirthDate => 'Birth Date';

  @override
  String get settingsActivityLevel => 'Activity Level';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsFoods => 'Foods';

  @override
  String get settingsFoodsSubtitle =>
      'Food database — view, edit and add values';

  @override
  String get settingsCloudAccount => 'Account';

  @override
  String settingsCloudSignedIn(String email) {
    return '$email';
  }

  @override
  String get settingsCloudSignedInFallback => 'Signed in';

  @override
  String get settingsCloudSignedOut =>
      'Sign in to save your data to your account';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Version $version · Personal fitness tracking';
  }

  @override
  String get settingsGenderMale => 'Male';

  @override
  String get settingsGenderFemale => 'Female';

  @override
  String settingsBirthDateValue(String date, int age) {
    return '$date · age $age';
  }

  @override
  String get settingsPickBirthDate => 'Pick your birth date';

  @override
  String get settingsDailyEnergyTitle => 'Estimated Daily Burn';

  @override
  String settingsDailyEnergyValue(int total, int bmr) {
    return '~$total kcal/day  ·  resting $bmr';
  }

  @override
  String settingsDailyEnergyMissing(String fields) {
    return 'To calculate, enter: $fields';
  }

  @override
  String get settingsMissingWeight => 'weight';

  @override
  String get settingsMissingHeight => 'height';

  @override
  String get settingsMissingBirthDate => 'birth date';

  @override
  String get settingsMissingGender => 'gender';

  @override
  String get themeSystem => 'System (device)';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System (device)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLight => 'Lightly active';

  @override
  String get activityModerate => 'Moderately active';

  @override
  String get activityActive => 'Active';

  @override
  String get activityVeryActive => 'Very active';

  @override
  String get onbWelcomeTitle => 'Welcome to Fit Pack';

  @override
  String get onbWelcomeTagline =>
      'Your workouts, nutrition and progress — all in one place.';

  @override
  String get onbWelcomeHint =>
      'A few quick questions to build your plan — takes under a minute.';

  @override
  String get onbAboutYouTitle => 'Let\'s get to know you';

  @override
  String get onbAboutYouSubtitle =>
      'Your weight is enough for a goal suggestion. You can add height, gender and age later in Profile.';

  @override
  String get onbCurrentWeight => 'Current weight';

  @override
  String get onbGoalWeightOptional => 'Goal weight (optional)';

  @override
  String get commonSelect => 'Select';

  @override
  String get onbYourGoal => 'Your goal';

  @override
  String get phaseCut => 'Lose Weight';

  @override
  String get phaseCutDesc => 'Burn fat, keep muscle';

  @override
  String get phaseMaintain => 'Maintain';

  @override
  String get phaseMaintainDesc => 'Sustain your current shape';

  @override
  String get phaseBulk => 'Build Muscle';

  @override
  String get phaseBulkDesc => 'Gain muscle, get stronger';

  @override
  String get onbPlanReadyTitle => 'Your plan is ready';

  @override
  String get onbPlanReadySubtitle =>
      'Suggested from your goal — adjust freely. You can change these anytime in Settings.';

  @override
  String get onbDailyKcal => 'Daily calorie goal';

  @override
  String get onbDailyProtein => 'Daily protein goal';

  @override
  String onbProjectionCut(String goal, int weeks) {
    return 'At this pace, you could reach $goal in roughly $weeks weeks.';
  }

  @override
  String onbProjectionBulk(String goal, int weeks) {
    return 'At this pace, you could build up to $goal in roughly $weeks weeks.';
  }

  @override
  String get onbProjectionNote =>
      'An estimate — real progress varies from person to person.';

  @override
  String get onbStart => 'Let\'s go';

  @override
  String get onbTrainingTitle => 'Your training';

  @override
  String get onbTrainingSubtitle =>
      'Two questions — let\'s start you on a program that fits.';

  @override
  String get onbExperienceQ => 'How long have you been training?';

  @override
  String get onbExpBeginner => 'Just starting';

  @override
  String get onbExpSome => 'For a while';

  @override
  String get onbExpLong => 'For a long time';

  @override
  String get onbDaysQ => 'How many days a week do you want to train?';

  @override
  String get onbDays23 => '2–3 days';

  @override
  String get onbDays4 => '4 days';

  @override
  String get onbDays56 => '5–6 days';

  @override
  String get onbProgramTitle => 'Our pick for you';

  @override
  String get onbProgramSubtitle =>
      'Chosen from your answers. The routines are added to your account — change them however you like.';

  @override
  String get onbProgramRestNote =>
      'Rest days speed up progress when you\'re starting out — so we suggest 4 days a week.';

  @override
  String get onbProgramUse => 'Start with this program';

  @override
  String get onbProgramSkip => 'I\'ll build my own';

  @override
  String get onbProgramSkipDesc =>
      'Set up your routine later in the Workout tab; ready-made programs are in Explore.';

  @override
  String get onbProgramInstallError =>
      'Couldn\'t add the program — you can add it from Workout → Explore.';

  @override
  String get onbGoalsNumberError =>
      'Enter your calorie and protein goals as numbers';

  @override
  String get onbSaveError => 'Couldn\'t save — try again';

  @override
  String get hintWorkout =>
      'Start with a ready-made program, or build your own routine.';

  @override
  String get hintNutrition =>
      'Add your first meal: search by typing or scan a barcode.';

  @override
  String get hintProgress => 'Log your first weight — your chart starts here.';

  @override
  String get hintGotIt => 'Got it';

  @override
  String get emptyRestartHint => 'Try restarting the app';

  @override
  String unitAge(int age) {
    return '$age yr';
  }

  @override
  String workoutRoutineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String get backupErrorInvalidFile => 'Not a valid Fit Pack backup.';

  @override
  String get backupErrorNewerVersion =>
      'This backup is from a newer version of Fit Pack. Update the app first.';

  @override
  String get backupErrorSignIn => 'Sign in first.';

  @override
  String exportRptRange(String start, String end) {
    return 'Range: $start → $end';
  }

  @override
  String exportRptGenerated(String ts) {
    return 'Generated: $ts';
  }

  @override
  String get exportRptProfile => 'Profile';

  @override
  String exportRptPhaseWeek(int phase, int week) {
    return 'Phase: $phase, Week: $week';
  }

  @override
  String exportRptCalorieGoal(int kcal) {
    return 'Calorie goal: $kcal kcal';
  }

  @override
  String exportRptProteinGoal(int g) {
    return 'Protein goal: $g g';
  }

  @override
  String exportRptHeight(String cm) {
    return 'Height: $cm cm';
  }

  @override
  String exportRptGoalWeight(String kg) {
    return 'Goal weight: $kg kg';
  }

  @override
  String exportRptWorkoutsTitle(int count) {
    return 'Workouts ($count sessions)';
  }

  @override
  String get exportRptNoWorkouts => 'No workouts in this range.';

  @override
  String exportRptDuration(int min) {
    return 'Duration: $min min';
  }

  @override
  String exportRptNote(String note) {
    return 'Note: $note';
  }

  @override
  String get exportRptWorkoutTable =>
      '| Exercise | Set | Kg | Reps | RPE | Duration | Distance | Type |';

  @override
  String get exportRptSetWarmup => 'Warmup';

  @override
  String get exportRptSetDrop => 'Drop';

  @override
  String get exportRptSetFail => 'Fail';

  @override
  String exportRptRoutinesTitle(int count) {
    return 'Routines ($count)';
  }

  @override
  String exportRptNutritionTitle(int count) {
    return 'Nutrition ($count entries)';
  }

  @override
  String get exportRptNoNutrition => 'No nutrition entries in this range.';

  @override
  String exportRptDayTotal(String kcal, String p, String c, String f) {
    return 'Total: $kcal kcal · P ${p}g · C ${c}g · F ${f}g';
  }

  @override
  String get exportRptNutritionTable =>
      '| Meal | Food | Grams | Kcal | Protein |';

  @override
  String exportRptWaterTitle(int count) {
    return 'Water ($count days)';
  }

  @override
  String get exportRptWaterTable => '| Date | ml |';

  @override
  String exportRptBodyTitle(int count) {
    return 'Body measurements ($count entries)';
  }

  @override
  String get exportRptNoBody => 'No measurements in this range.';

  @override
  String get exportRptBodyTable =>
      '| Date | Weight | Waist | Chest | Arm | Hip | Neck | BF% |';

  @override
  String get authWelcomeTitle => 'Welcome to Fit Pack';

  @override
  String get authWelcomeTagline =>
      'Your workouts, nutrition and progress — all in one place.';

  @override
  String get authValueWorkout => 'Build routines and log every set';

  @override
  String get authValueNutrition => 'Track calories and protein day by day';

  @override
  String get authValueProgress =>
      'Watch weight and measurements move in charts';

  @override
  String get authWhyAccount =>
      'Your data is stored in your account — it stays with you when you change phones.';

  @override
  String get cloudIntroSignUp =>
      'Create an account — your workouts, meals and measurements are saved to it automatically.';

  @override
  String get syncUpToDate => 'Your data is up to date';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String syncPendingOffline(int count) {
    return 'Saved — $count record(s) will upload when you\'re back online';
  }

  @override
  String syncPendingWaiting(int count) {
    return 'Saved — $count record(s) waiting to upload';
  }

  @override
  String get signOutPendingTitle => 'Records not yet uploaded';

  @override
  String signOutPendingMsg(int count) {
    return '$count record(s) haven\'t been uploaded to the server yet. If you sign out now, they won\'t upload until your next sign-in.';
  }

  @override
  String get signOutSyncFirst => 'Sync first';

  @override
  String get signOutAnyway => 'Sign out anyway';

  @override
  String get signOutStillPending => 'Still uploading — try again in a moment';

  @override
  String get settingsWeightIncrement => 'Weight increment';

  @override
  String progIncrease(String sets, int max, String inc) {
    return 'Last time: $sets — every set reached $max. Ready? Try +$inc.';
  }

  @override
  String progAddRep(String sets, int min, int max) {
    return 'Last time: $sets (range $min–$max). Try one more rep per set.';
  }

  @override
  String progRepeat(String sets, int min) {
    return 'Last time: $sets — some sets under $min. Repeat the same weights.';
  }

  @override
  String progApplyWeight(String inc) {
    return '+$inc';
  }

  @override
  String get progApplyReps => '+1 rep';

  @override
  String progAppliedWeight(String inc, int reps) {
    return 'Applied: +$inc per set, $reps reps';
  }

  @override
  String get progAppliedReps => 'Applied: +1 rep per set';

  @override
  String get progInfoTitle => 'How the target works';

  @override
  String progInfoBody(int min, int max, String inc) {
    return 'Double progression: keep the weight and add reps until every set reaches the top of your range ($min–$max). Then add weight (+$inc) and start again at $min reps. Nothing changes unless you tap the button — your routine stays the same and suggested sets are never marked done.';
  }

  @override
  String get progInfoSettings =>
      'Change the increment in Settings → Weight increment.';

  @override
  String progIncreaseHard(String sets, int max, String inc, String rpe) {
    return 'Last time: $sets — every set reached $max, but the hardest was RPE $rpe. Try +$inc; reps may drop in the first set.';
  }

  @override
  String progHoldFailure(String sets) {
    return 'Last time: $sets — at least one set was to failure (RPE 10). Repeat the same target before adding reps.';
  }

  @override
  String progDecrease(String sets, int min, String inc) {
    return 'Stuck below $min reps two sessions in a row, last one to failure. Drop −$inc and build back from $min reps.';
  }

  @override
  String progApplyDecrease(String inc) {
    return '−$inc';
  }

  @override
  String progAppliedDecrease(String inc, int reps) {
    return 'Applied: −$inc per set, $reps reps';
  }

  @override
  String get progInfoRpe =>
      'RPE also counts: if a set was to failure (RPE 10) you won\'t be pushed for an extra rep; stuck two sessions in a row suggests dropping one step.';

  @override
  String syncLastBackup(String when) {
    return 'Last backup: $when';
  }

  @override
  String syncWhenToday(String time) {
    return 'today $time';
  }

  @override
  String syncWhenYesterday(String time) {
    return 'yesterday $time';
  }

  @override
  String syncLongOutage(int days) {
    return 'Not backed up for $days days. Your data is safe on this phone.';
  }

  @override
  String syncReplacedRows(int count) {
    return '$count records were replaced by a newer version from the cloud';
  }

  @override
  String syncFailedRows(int count) {
    return '$count record(s) couldn\'t upload — tap to retry';
  }

  @override
  String get wrTitle => 'Weekly review';

  @override
  String wrInProgress(int days) {
    return 'Week in progress — based on $days day(s)';
  }

  @override
  String get wrPrevWeek => 'Previous week';

  @override
  String get wrNextWeek => 'Next week';

  @override
  String get wrSummaryTitle => 'Summary';

  @override
  String wrFactWorkouts(int count) {
    return '$count workout(s)';
  }

  @override
  String wrFactFoodDays(int days) {
    return 'food logged on $days day(s)';
  }

  @override
  String get wrFactNoFood => 'no food logged';

  @override
  String wrFactWeightDelta(String delta) {
    return 'weight $delta';
  }

  @override
  String get wrFactNoPrevWeight => 'no weigh-in last week to compare';

  @override
  String get wrFactNoWeight => 'no weigh-in';

  @override
  String get wrWorkoutTitle => 'Training';

  @override
  String wrWorkoutPlanned(int done, int planned) {
    return '$done/$planned planned workouts';
  }

  @override
  String wrWorkoutDone(int count) {
    return '$count workout(s)';
  }

  @override
  String wrWorkoutDetail(int sets, int minutes, String volume) {
    return '$sets completed sets · $minutes min · $volume volume';
  }

  @override
  String wrWorkoutPrev(int count) {
    return 'Last week: $count workout(s)';
  }

  @override
  String get wrWorkoutNone => 'No workouts logged this week';

  @override
  String wrWorkoutSource(int count) {
    return 'Source: $count session(s). Volume and session count use the same calculation as Home.';
  }

  @override
  String get wrProgressTitle => 'Exercise progress';

  @override
  String wrProgressRow(String weight, int reps, String delta) {
    return '$weight × $reps — est. 1RM +$delta';
  }

  @override
  String get wrProgressNone => 'No earlier record to compare, or no progress';

  @override
  String get wrProgressSource =>
      'Source: this week\'s best completed set vs. the exercise\'s previous record (Epley 1RM). Exercises are listed separately; no overall score.';

  @override
  String get wrNutritionTitle => 'Nutrition';

  @override
  String wrNutritionLogged(int days) {
    return '$days day(s) logged';
  }

  @override
  String wrNutritionAvg(int kcal, int protein) {
    return 'Average of logged days: $kcal kcal · $protein g protein';
  }

  @override
  String wrNutritionGoal(int kcal, int protein) {
    return 'Goal: $kcal kcal · $protein g protein';
  }

  @override
  String get wrNutritionNone => 'No food logged this week';

  @override
  String get wrNutritionSource =>
      'Source: logged days only. Unlogged days don\'t count as 0 and aren\'t judged against your goal.';

  @override
  String get wrWeightTitle => 'Weight';

  @override
  String wrWeightAvg(String weight, int count) {
    return 'Weekly average: $weight ($count weigh-in(s))';
  }

  @override
  String wrWeightDelta(String delta) {
    return '$delta vs. last week';
  }

  @override
  String get wrWeightSingle => 'Single weigh-in — not a trend';

  @override
  String get wrWeightNoPrev => 'No weigh-in last week — can\'t compare';

  @override
  String get wrWeightNone => 'No weigh-in this week';

  @override
  String get wrMeaningOnTrack => 'In line with your goal';

  @override
  String get wrMeaningAgainst =>
      'Against your goal — one week alone isn\'t a verdict';

  @override
  String get wrMeaningFlat => 'No clear change';

  @override
  String get wrDirectionLabel => 'Your weight goal';

  @override
  String get wrDirLose => 'Lose';

  @override
  String get wrDirMaintain => 'Maintain';

  @override
  String get wrDirGain => 'Gain';

  @override
  String get wrDirectionUnset =>
      'Pick a direction and weight changes are read against it. It won\'t be applied to past weeks.';

  @override
  String get wrGoalConflict =>
      'The direction you picked doesn\'t match your goal weight. Nothing was changed — you can check it in Profile.';

  @override
  String get wrGoalConflictAction => 'Open profile';

  @override
  String get wrWeightSource =>
      'Source: weekly averages. The direction only applies to weeks after you picked it.';

  @override
  String get wrMuscleTitle => 'Muscle group split';

  @override
  String wrMuscleRow(int sets) {
    return '$sets sets';
  }

  @override
  String get wrMuscleNone => 'No completed sets this week';

  @override
  String get wrMuscleSource =>
      'Source: completed, non-warm-up sets; the exercise\'s primary muscle. Counts only.';

  @override
  String get wrFocusTitle => 'Next week';

  @override
  String wrFocusCompletePlan(int done, int planned) {
    return 'You completed $done of $planned planned workouts — the goal is to finish the plan.';
  }

  @override
  String wrFocusIncrease(String name) {
    return '$name has been at the same weight for 3 weeks, above your rep range — try adding weight.';
  }

  @override
  String wrFocusLogging(int days) {
    return 'Food logged on $days day(s) — aim for a short entry every day.';
  }

  @override
  String get wrFocusCalories =>
      'Weight has moved against your goal for 2 weeks — consider reviewing your calorie goal.';

  @override
  String get wrFocusKeep => 'Keep the same rhythm.';

  @override
  String get wrFocusSource =>
      'Rule: the first matching suggestion is shown. It\'s a suggestion; your goals don\'t change.';

  @override
  String get wrOpen => 'Weekly review';

  @override
  String get notifWeeklyReview => 'Weekly review';

  @override
  String notifWeeklyReviewSub(String day) {
    return 'When your week closes: $day 20:00';
  }

  @override
  String get notifWeeklyTitle => 'Your week is ready';

  @override
  String get notifWeeklyBody =>
      'This week\'s summary and one focus for next week.';

  @override
  String get ppTitle => 'Progress photos';

  @override
  String ppEntrySub(int count) {
    return '$count photo(s) · never uploaded';
  }

  @override
  String get ppEntryEmpty => 'The mirror shows change before the scale does';

  @override
  String get ppEmptyTitle => 'No photos yet';

  @override
  String get ppEmptyMsg =>
      'Regular photos from the same angle and in the same light show change weeks before the scale.';

  @override
  String get ppAdd => 'Add photo';

  @override
  String get ppAngleFront => 'Front';

  @override
  String get ppAngleSide => 'Side';

  @override
  String get ppAngleBack => 'Back';

  @override
  String get ppAll => 'All';

  @override
  String get ppCamera => 'Take photo';

  @override
  String get ppGallery => 'Choose from library';

  @override
  String get ppAngle => 'Angle';

  @override
  String get ppDeleteTitle => 'Delete photo?';

  @override
  String get ppDeleteMsg =>
      'This photo isn\'t backed up on our server; once deleted, it can\'t be restored in the app.';

  @override
  String get ppCompare => 'Compare';

  @override
  String get ppCompareHint => 'Select two photos to compare';

  @override
  String ppSelected(int count) {
    return '$count/2 selected';
  }

  @override
  String ppDaysApart(int days) {
    return '$days day(s) apart';
  }

  @override
  String get ppDeviceOnly =>
      'Photos are never uploaded to our server or saved to your gallery; they\'re stored on this phone. If your phone\'s own backup (iCloud / Google) is on, they\'re included in it. They\'re deleted from this phone if you switch accounts.';

  @override
  String get ppLoadError => 'Couldn\'t load photos';

  @override
  String get ppSaveError => 'Couldn\'t save the photo';

  @override
  String get ppMissingFile => 'File not found';

  @override
  String get homeTitleToday => 'Today';

  @override
  String get homeUpNext => 'UP NEXT';

  @override
  String get homeTodayPlan => 'TODAY\'S PLAN';

  @override
  String homePlanSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · Planned routine';
  }

  @override
  String get homeInProgress => 'IN PROGRESS';

  @override
  String get homeResumeAction => 'Resume session';

  @override
  String get homeRhythmKicker => 'YOUR RHYTHM';

  @override
  String homeRhythmLeft(int done, int goal, int left) {
    return 'This week $done/$goal workouts · $left to go';
  }

  @override
  String homeRhythmDone(int done, int goal) {
    return 'This week\'s goal is done ($done/$goal)';
  }

  @override
  String homeRhythmEmptySub(int goal) {
    return 'Weekly goal: $goal workouts · rest days don\'t break it';
  }

  @override
  String homeRhythmRestartSub(int done, int goal) {
    return 'Last week\'s goal was missed · this week $done/$goal';
  }

  @override
  String get homeLast30 => 'LAST 30 DAYS';

  @override
  String get homeStatKcalEstimated => 'est. kcal';

  @override
  String get homeDayLog => 'Today\'s log';

  @override
  String get calTitle => 'CALENDAR';

  @override
  String get calBackToToday => 'Back to today';

  @override
  String get calPrevWeek => 'Previous week';

  @override
  String get calNextWeek => 'Next week';

  @override
  String get calPrevMonth => 'Previous month';

  @override
  String get calNextMonth => 'Next month';

  @override
  String get calOpenMonth => 'Open month view';

  @override
  String get calLegendRecord => 'Has entries';

  @override
  String calSelected(String date) {
    return 'Selected: $date';
  }

  @override
  String get calDayRecords => 'Entries for this day';

  @override
  String get calOpen => 'Open';

  @override
  String calWorkoutLine(int sets, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    return '$_temp0 · $volume volume';
  }

  @override
  String calNutritionLine(int kcal, int protein) {
    return '$kcal kcal · $protein g protein';
  }

  @override
  String calWaterLine(String liters) {
    return '$liters L water';
  }

  @override
  String get asMoveUp => 'Move up';

  @override
  String get asMoveDown => 'Move down';

  @override
  String get asRestTitle => 'Rest between sets';

  @override
  String get asRestRoutineNote =>
      'Saved to the routine too — next time it starts with this.';

  @override
  String get asRestSessionNote => 'Applies to this workout.';

  @override
  String get asRestChange => 'Change rest time';

  @override
  String get asRestSaveError => 'Couldn\'t save the rest time to the routine';

  @override
  String asSuggestHint(String value) {
    return 'Tap ✓ to log $value';
  }

  @override
  String get asStepTitle => 'Weight step';

  @override
  String get asStepHelp =>
      'The − and + buttons change the weight by this amount. Remembered for this exercise.';

  @override
  String get asStepChange => 'Change weight step';

  @override
  String asStepDecrease(String step) {
    return 'Decrease weight by $step';
  }

  @override
  String asStepIncrease(String step) {
    return 'Increase weight by $step';
  }

  @override
  String get wrThisWeek => 'This week';

  @override
  String get wrHowCalculated => 'How it\'s calculated';

  @override
  String get wrKpiWorkouts => 'Workouts';

  @override
  String get wrKpiVolume => 'Volume';

  @override
  String get wrKpiKcal => 'Avg. calories';

  @override
  String get wrKpiWeight => 'Avg. weight';

  @override
  String wrPrevValue(String value) {
    return 'Last week: $value';
  }

  @override
  String wrPlannedOf(int planned) {
    return 'of $planned planned';
  }

  @override
  String wrLoggedOf(int days, int total) {
    return '$days/$total days logged';
  }

  @override
  String wrProteinAvg(int protein) {
    return '$protein g protein';
  }

  @override
  String wrGoalShort(int kcal) {
    return 'Goal $kcal';
  }

  @override
  String wrMeasureCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weigh-ins',
      one: '1 weigh-in',
    );
    return '$_temp0';
  }

  @override
  String get wrSingleShort => 'Single weigh-in — not a trend';

  @override
  String get wrNoPrevShort => 'No weigh-in last week';

  @override
  String get wrNoRecord => 'No data';

  @override
  String wrProgressDelta(String delta) {
    return '1RM +$delta';
  }

  @override
  String get wrVsPrev => 'vs last week';

  @override
  String get rhythmStart => 'Start your rhythm';

  @override
  String get rhythmFirstWeek => 'Complete your first week';

  @override
  String get rhythmFirstWeekLastOne => 'One more workout and week one is yours';

  @override
  String get rhythmWeek1 => 'Week one: done!';

  @override
  String get rhythmWeek2 => '2 weeks in a row, a habit is forming';

  @override
  String get rhythmWeek3 => '3 weeks! You\'ve found your rhythm';

  @override
  String get rhythmMonth1 => 'One month strong, this is your routine now';

  @override
  String get rhythmMonth2 => '2 months without a break, serious work';

  @override
  String get rhythmMonth3 => '3 months! Discipline is winning';

  @override
  String get rhythmHalfYear => 'Half a year unbroken, legendary streak';

  @override
  String get rhythmYear1 => 'A full year. Hats off';

  @override
  String rhythmDoneA(int n) {
    return 'Week $n, in the bag';
  }

  @override
  String rhythmDoneB(int n) {
    return '$n weeks and no stopping';
  }

  @override
  String rhythmDoneC(int n) {
    return '$n-week streak, on fire';
  }

  @override
  String rhythmDoneD(int n) {
    return '$n weeks, not a single miss';
  }

  @override
  String rhythmOngoingA(int n) {
    return '$n-week streak, take this week too';
  }

  @override
  String rhythmOngoingB(int next) {
    return 'Carry the streak into week $next';
  }

  @override
  String rhythmOngoingC(int n) {
    return '$n weeks in, no quitting now';
  }

  @override
  String rhythmOngoingLastOne(int next) {
    return 'One more workout, then week $next';
  }

  @override
  String get rhythmRestartA => 'A new streak starts';

  @override
  String get rhythmRestartB => 'Pick up where you left off';

  @override
  String get rhythmRestartC => 'Every streak starts with one workout';

  @override
  String get nhUsualBreakfast => 'Your usual breakfast';

  @override
  String get nhUsualLunch => 'Your usual lunch';

  @override
  String get nhUsualDinner => 'Your usual dinner';

  @override
  String get nhUsualSnack => 'Your usual snack';

  @override
  String nhUsualSub(int count, int kcal, int protein) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods',
      one: '1 food',
    );
    return '$_temp0 · $kcal kcal · $protein g protein';
  }

  @override
  String get nhUsualAdd => 'Add';

  @override
  String get nhUsualLater => 'Not now';

  @override
  String nhUsualAdded(String meal) {
    return '$meal added';
  }

  @override
  String nhWeekStart(int goal) {
    return 'Log your first day this week · goal $goal days';
  }

  @override
  String nhWeekGoing(int done, int goal, int left) {
    return 'This week $done/$goal days logged · $left to go';
  }

  @override
  String nhWeekLastOne(int done, int goal) {
    return 'This week $done/$goal days · one more and the week is done';
  }

  @override
  String nhWeekDone(int done, int goal) {
    return 'This week\'s logging goal is done ($done/$goal)';
  }

  @override
  String get nhQuickButton => 'Quick: kcal + protein';

  @override
  String get nhQuickTitle => 'Quick entry';

  @override
  String get nhQuickHint =>
      'For meals you can\'t weigh: just calories and protein. It\'s also saved to your foods so you can find it next time.';

  @override
  String get nhQuickName => 'What did you eat? (optional)';

  @override
  String get nhQuickDefaultName => 'Quick entry';

  @override
  String get nhQuickKcal => 'Calories (kcal)';

  @override
  String get nhQuickProtein => 'Protein (g, optional)';

  @override
  String get nhQuickEntry => 'quick entry';

  @override
  String nhQuickAdded(String name) {
    return '$name added';
  }

  @override
  String get nhReminderCta =>
      'Turn on meal reminders — no notification for meals you\'ve already logged.';

  @override
  String get nhReminderEnable => 'Turn on';

  @override
  String get nhReminderEnabled => 'Meal reminders are on';

  @override
  String get notifMealLabel => 'Meal reminders';

  @override
  String get notifMealSub =>
      'If you haven\'t logged a meal, a bit after you usually do. Logged meals get no notification.';

  @override
  String get notifMealBreakfastTitle => 'Logged your breakfast?';

  @override
  String get notifMealLunchTitle => 'Logged your lunch?';

  @override
  String get notifMealDinnerTitle => 'Logged your dinner?';

  @override
  String get notifMealBody => 'It takes 10 seconds.';

  @override
  String get notifMealBreakfastTitle2 => 'Start the day with one entry';

  @override
  String get notifMealBreakfastTitle3 => 'What fueled your morning?';

  @override
  String get notifMealLunchTitle2 => 'What was on your lunch plate?';

  @override
  String get notifMealLunchTitle3 => 'Lunch break: a 10-second log';

  @override
  String get notifMealDinnerTitle2 => 'One last entry before the day ends';

  @override
  String get notifMealDinnerTitle3 => 'Don\'t forget your dinner plate';

  @override
  String get notifMealBody2 =>
      'Log it while it\'s fresh and you won\'t forget the portion.';

  @override
  String get notifMealBody3 =>
      'Not sure? A quick estimated calorie entry is enough.';

  @override
  String get notifMealBody4 => 'This meal completes today\'s picture.';

  @override
  String get notifMealBody5 =>
      'Seeing what you eat is half the way to your goal.';

  @override
  String get notifMealBody6 => 'Your protein goal is waiting on this meal.';

  @override
  String notifMealUsualBreakfast(String foods) {
    return 'Your usual breakfast: $foods. Add it with one tap.';
  }

  @override
  String notifMealUsualLunch(String foods) {
    return 'Your usual lunch: $foods. Add it with one tap.';
  }

  @override
  String notifMealUsualDinner(String foods) {
    return 'Your usual dinner: $foods. Add it with one tap.';
  }

  @override
  String get notifMealWeekStart => 'This week\'s first log is waiting for you.';

  @override
  String notifMealWeekProgress(int done, int goal, int next) {
    return '$done/$goal days logged this week. Log today to make it $next/$goal.';
  }

  @override
  String get notifMealWeekMet =>
      'Weekly goal reached. Log today too and keep the picture complete.';

  @override
  String get nhPortion => 'portion';

  @override
  String get foodCatSweet => 'Sweets & snacks';

  @override
  String get foodCatDrink => 'Drinks';

  @override
  String get attribUsdaDesc =>
      'Basic food nutrition values; Turkish dishes are estimated from their ingredients';

  @override
  String get afScan => 'Barcode';

  @override
  String get afQuick => 'Quick calories';

  @override
  String get afCustom => 'Your own food';

  @override
  String get afRecent => 'Recently added';

  @override
  String afAllCount(int count) {
    return 'All foods · $count';
  }

  @override
  String afResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get afCatAll => 'All';

  @override
  String afAdded(String name) {
    return '$name added';
  }

  @override
  String afSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries added',
      one: '1 entry added',
    );
    return '$_temp0';
  }

  @override
  String get afDone => 'Done';

  @override
  String get afAddBreakfast => 'Add to breakfast';

  @override
  String get afAddLunch => 'Add to lunch';

  @override
  String get afAddDinner => 'Add to dinner';

  @override
  String get afAddSnack => 'Add to snack';

  @override
  String afQuickAddTip(String portion) {
    return 'Add now: $portion';
  }

  @override
  String get afChangeMeal => 'Change meal';

  @override
  String get afEditHint =>
      'Tap a row to change the amount, + to add right away';

  @override
  String get journalTitle => 'One step further today.';

  @override
  String get journalSubtitle => 'Performance journal';

  @override
  String get journalEnergyMacros => 'Energy & macros';

  @override
  String get journalEnergyLogged => 'Energy logged';

  @override
  String get journalEnergyGoal => 'Daily goal';

  @override
  String get journalProteinRing => 'Inner ring: protein';

  @override
  String get journalMeals => 'Your meal journal';

  @override
  String get journalMealAdd => '+ Add';

  @override
  String get journalActivity => 'Workout activity';

  @override
  String get journalActivityPeriod => 'Last 7 days · estimated kcal';

  @override
  String get journalActivityEmpty => 'No workouts logged in the last 7 days.';

  @override
  String get journalEstimateMissing =>
      'Weight and duration are needed to estimate calories.';

  @override
  String get journalNoWorkout => 'No workout logged on this day.';

  @override
  String journalActivitySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logged workouts',
      one: '1 logged workout',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDailyEnergy => 'Daily energy';

  @override
  String get nutritionKcalRemaining => 'kcal remaining';

  @override
  String get nutritionKcalAboveGoal => 'kcal above goal';

  @override
  String get nutritionKcalAtGoal => 'kcal to goal';

  @override
  String get nutritionDiary => 'Meal journal';

  @override
  String nutritionFoodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods',
      one: '1 food',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDayCompleteToday => 'I logged all of today’s meals';

  @override
  String get nutritionDayCompletePast => 'I logged all meals for this day';

  @override
  String get nutritionDayCompleteHint =>
      'Tick it so the weekly review and assistant don’t treat this day as incomplete.';

  @override
  String get nutritionDayCompleted => 'All meals logged';

  @override
  String get nutritionDayCompletedSub =>
      'This day counts as complete in your weekly review.';

  @override
  String get nutritionDayChangedAfter => 'Changed after completion';

  @override
  String get nutritionDayReopen => 'Undo';

  @override
  String wrCompletedDays(int days) {
    return '$days completed days';
  }

  @override
  String wrExcludedDays(int days) {
    return '$days not counted';
  }

  @override
  String wrProteinHit(int hit, int total) {
    return 'Protein goal $hit/$total days';
  }

  @override
  String get healthSteps => 'Steps';

  @override
  String get healthInstall => 'Install Health Connect';

  @override
  String get healthSeeSteps => 'See your steps';

  @override
  String get healthNoData => 'No data — check your health permissions';

  @override
  String get healthReadError => 'Couldn’t read your steps. Try again.';

  @override
  String get healthStepGoal => 'Daily step goal';

  @override
  String get healthPermissionTitle => 'Your steps on Home';

  @override
  String get healthPermissionStepsOnly => 'Only your step count is read.';

  @override
  String get healthPermissionOnDevice => 'Your steps stay on this phone.';

  @override
  String get healthPermissionNoSharing =>
      'Your calorie goal stays the same. Nothing is shared.';

  @override
  String get healthConnect => 'Connect';

  @override
  String get healthNotNow => 'Not now';

  @override
  String get healthConnectError =>
      'Couldn’t connect. Check your health permissions and try again.';

  @override
  String get healthWeekTitle => 'Last 7 days';

  @override
  String get healthRetry => 'Try again';

  @override
  String get healthNotConnected => 'Not connected · see your steps';

  @override
  String get healthAverage => 'Average of days with data';

  @override
  String healthStepCount(String count) {
    return '$count steps';
  }

  @override
  String get healthGoalHint => 'Leave blank or enter 0 for no goal.';

  @override
  String get healthGoalSaveError => 'Couldn’t save your goal. Try again.';

  @override
  String get healthSection => 'Health';

  @override
  String get healthConnection => 'Step connection';

  @override
  String get healthConnected => 'Connected';

  @override
  String get healthDisconnect => 'Disconnect';

  @override
  String get healthDisconnectNote =>
      'You can also revoke access in Health or Health Connect settings.';

  @override
  String get healthNoGoal => 'No goal';

  @override
  String get healthInstallError => 'Couldn’t open Health Connect. Try again.';

  @override
  String get healthDisconnectError => 'Couldn’t disconnect. Try again.';

  @override
  String get assistantTitle => 'Ask my data';

  @override
  String get assistantSubtitle =>
      'Answers from your records. Pick a question to explore.';

  @override
  String get assistantQuestionHint => 'How were my workouts this week?';

  @override
  String get assistantAsk => 'Ask';

  @override
  String get assistantReady => 'Ready questions';

  @override
  String get assistantAll => 'All questions';

  @override
  String get assistantLess => 'Show less';

  @override
  String get assistantUnderstood => 'My understanding';

  @override
  String get assistantChange => 'Change';

  @override
  String get assistantApply => 'Show result';

  @override
  String get assistantPeriod => 'Period';

  @override
  String get assistantExercise => 'Exercise';

  @override
  String get assistantChooseExercise => 'Choose an exercise';

  @override
  String get assistantInterpretation => 'Explain the numbers too';

  @override
  String get assistantMeal => 'Choose a meal for food examples';

  @override
  String get assistantNoMeal => 'Remaining amounts only';

  @override
  String get assistantPrivacyTitle => 'Your question will be sent to Google';

  @override
  String get assistantPrivacy =>
      'Only your question and fixed routing definitions go to Gemini; your workout, nutrition and measurement records are not sent to Google. With free Gemini, Google may use the text and model output to improve products, with possible human review. Do not enter identity, contact or private health information. Ready questions run on your device.';

  @override
  String get assistantPrivacyAccept => 'I understand, send question';

  @override
  String get assistantPrivacyCancel => 'Use ready questions';

  @override
  String get assistantUnavailable =>
      'Free-text routing is unavailable. You can continue with ready questions.';

  @override
  String get assistantSignedOut =>
      'Sign in to ask a free-text question. Ready questions run on your device.';

  @override
  String get assistantPrivateBlocked =>
      'This question may contain private information. Remove identity, contact or health details, or choose a ready question.';

  @override
  String get assistantFallback =>
      'I could not reliably route this question. Choose a ready question to explore your records.';

  @override
  String get assistantClarify =>
      'Choose a period or exercise before opening the result.';

  @override
  String get assistantMulti =>
      'There are several topics. Which one should we explore first?';

  @override
  String assistantQuota(String time) {
    return 'Question limit reached. Resets: $time. Ready questions remain available.';
  }

  @override
  String get assistantError => 'Could not read records. Try again.';

  @override
  String get assistantRetry => 'Try again';

  @override
  String get assistantOpenRecords => 'Open records';

  @override
  String assistantRecords(String count) {
    return '$count records';
  }

  @override
  String get assistantSoFar => 'So far';

  @override
  String get assistantUnknownStart => 'Since the first record';

  @override
  String get assistantNoData =>
      'No records in this period. Missing data is not a zero result.';

  @override
  String get assistantInsufficient =>
      'Numbers are available; there is not enough data for a trend interpretation yet.';

  @override
  String get assistantNoGoal => 'No goal has been set for this calculation.';

  @override
  String get assistantNoPlan => 'No workout days are scheduled.';

  @override
  String get assistantIncompleteDays =>
      'No completed days; protein-goal success cannot be calculated.';

  @override
  String get assistantLoggedBasis =>
      'Logged days only; records may be incomplete.';

  @override
  String get assistantCompletedBasis =>
      'Average uses completed days only; a completed empty day counts as zero.';

  @override
  String get assistantCurrentPlan =>
      'Uses your current plan; past plan changes are unknown.';

  @override
  String get assistantFoodBasis =>
      'Examples use past portions for the selected meal. Filtered by remaining calories only; nothing is logged automatically.';

  @override
  String get assistantUnknownExercise => 'Unknown exercise';

  @override
  String get assistantOwnHistory => 'Your own history';

  @override
  String get assistantGuideline => 'General research finding';

  @override
  String get assistantSources => 'Sources';

  @override
  String get assistantDeveloper => 'Developer';

  @override
  String get assistantQuality => 'Assistant quality';

  @override
  String get assistantQualityInfo =>
      'Text-free events on this device only. Correction rate is not accuracy; no correction does not prove a correct route.';

  @override
  String get assistantQualityAuto => 'Automatic answers';

  @override
  String get assistantQualityCorrections => 'Changed selections';

  @override
  String get assistantQualityLatency => 'Latency: median / 95th percentile';

  @override
  String get assistantQualityTokens => 'Input / output tokens';

  @override
  String get assistantQualityFree => 'Gemini free tier · cost \$0';

  @override
  String get assistantQualityClear => 'Clear local quality events';

  @override
  String get assistantQualityClearConfirm =>
      'Delete assistant quality events? Your fitness records are preserved.';

  @override
  String get assistantQualitySmall =>
      'Small sample; interpret the rate cautiously.';

  @override
  String get assistantQualityWarning =>
      'Correction rate exceeded 3% in two consecutive weeks. Review routing.';

  @override
  String get assistantQualityTransitions => 'Query changes';

  @override
  String get assistantQualityDays => 'Last 7 days';

  @override
  String get assistantNotAvailable => 'Unknown';

  @override
  String get assistantPeriodToday => 'Today';

  @override
  String get assistantPeriodThisWeek => 'This week';

  @override
  String get assistantPeriodLastWeek => 'Last week';

  @override
  String get assistantPeriodLast30Days => 'Last 30 days';

  @override
  String get assistantPeriodAllTime => 'All time';

  @override
  String get assistantQueryWorkoutSummary => 'How were my workouts?';

  @override
  String get assistantQueryPlanAdherence =>
      'How closely did I follow scheduled days?';

  @override
  String get assistantQueryStrengthProgress => 'Which exercises improved?';

  @override
  String get assistantQueryExerciseHistory =>
      'How did I progress in this exercise?';

  @override
  String get assistantQueryNutritionSummary =>
      'What do my nutrition records show?';

  @override
  String get assistantQueryProteinGoal =>
      'How many days did I reach my protein goal?';

  @override
  String get assistantQueryWeightTrend => 'How did my weight change?';

  @override
  String get assistantQueryMuscleBalance => 'How many sets per muscle group?';

  @override
  String get assistantQueryStreak => 'How many consistent weeks?';

  @override
  String get assistantQueryTodayRemaining => 'What remains of my goals today?';

  @override
  String get assistantQueryTopExercises => 'Which exercises did I do most?';

  @override
  String get assistantMetricSessions => 'Sessions';

  @override
  String get assistantMetricSets => 'Completed sets';

  @override
  String get assistantMetricMinutes => 'Duration';

  @override
  String get assistantMetricVolume => 'Volume';

  @override
  String get assistantMetricPlannedDays => 'Scheduled days';

  @override
  String get assistantMetricDoneDays => 'Scheduled days completed';

  @override
  String get assistantMetricLoggedDays => 'Logged days';

  @override
  String get assistantMetricCompletedDays => 'Completed days';

  @override
  String get assistantMetricExcludedDays => 'Excluded days';

  @override
  String get assistantMetricAvgKcal => 'Average energy';

  @override
  String get assistantMetricAvgProtein => 'Average protein';

  @override
  String get assistantMetricProteinGoal => 'Protein goal';

  @override
  String get assistantMetricHitDays => 'Completed days reaching goal';

  @override
  String get assistantMetricMeasurements => 'Measurements';

  @override
  String get assistantMetricFirstWeight => 'First weight';

  @override
  String get assistantMetricLastWeight => 'Last weight';

  @override
  String get assistantMetricChange => 'Change';

  @override
  String get assistantMetricWeeks => 'Weekly streak';

  @override
  String get assistantMetricWeeklyGoal => 'Weekly day goal';

  @override
  String get assistantMetricRemainingKcal => 'Remaining energy';

  @override
  String get assistantMetricRemainingProtein => 'Remaining protein';

  @override
  String get assistantMetricFirstE1rm => 'First estimated one-rep maximum';

  @override
  String get assistantMetricLastE1rm => 'Last estimated one-rep maximum';

  @override
  String get assistantMetricPortion => 'Past portion';

  @override
  String get assistantMetricPortionKcal => 'Portion energy';

  @override
  String get assistantMetricPortionProtein => 'Portion protein';

  @override
  String insightMuscleBelowTen(String muscle, String sets, String level) {
    return '$muscle: $sets sets, below the roughly $level weekly-set level studied.';
  }

  @override
  String insightMuscleAtTen(String muscle, String sets, String level) {
    return '$muscle: $sets sets, at or above the roughly $level-set level studied.';
  }

  @override
  String insightMuscleBeyondTwenty(
    String muscle,
    String sets,
    String limitedEvidenceAbove,
  ) {
    return '$muscle: $sets sets. Evidence for added gains beyond $limitedEvidenceAbove sets is limited.';
  }

  @override
  String insightWeightNotEnoughData(
    String count,
    String spanDays,
    String minDays,
  ) {
    return '$count measurements spanning $spanDays days. Trend interpretation needs at least two measurements over $minDays days.';
  }

  @override
  String insightWeightAgainstGoal(String weeklyChangeKg) {
    return 'Weekly change is $weeklyChangeKg, opposite your selected goal direction.';
  }

  @override
  String insightWeightNoClearChange(String weeklyChangeKg) {
    return 'Weekly change is $weeklyChangeKg; no clear trend is visible.';
  }

  @override
  String insightWeightLossSlower(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Weekly change is $weeklyChangeKg; slower than the CDC general loss range of $rangeMinKg–$rangeMaxKg.';
  }

  @override
  String insightWeightLossInRange(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Weekly change is $weeklyChangeKg; within the CDC general loss range of $rangeMinKg–$rangeMaxKg.';
  }

  @override
  String insightWeightLossFaster(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Weekly change is $weeklyChangeKg; faster than the CDC general loss range of $rangeMinKg–$rangeMaxKg.';
  }

  @override
  String insightWeightGainSlower(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Weekly gain is $pctPerWeek%, slower than the $rangeMinPct–$rangeMaxPct% level studied.';
  }

  @override
  String insightWeightGainInRange(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Weekly gain is $pctPerWeek%, within the $rangeMinPct–$rangeMaxPct% level studied.';
  }

  @override
  String insightWeightGainFaster(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Weekly gain is $pctPerWeek%, faster than the $rangeMinPct–$rangeMaxPct% level studied.';
  }

  @override
  String insightWeightStable(String totalChangePct, String stablePct) {
    return 'Estimated change over the period is $totalChangePct%, within ±$stablePct% of the mean.';
  }

  @override
  String insightWeightDriftUp(String totalChangePct) {
    return 'Estimated increase over the period is $totalChangePct%.';
  }

  @override
  String insightWeightDriftDown(String totalChangePct) {
    return 'Estimated change over the period is $totalChangePct%.';
  }

  @override
  String insightWorkoutNotEnoughHistory(
    String metric,
    String value,
    String minWeeks,
    String baselineWeeks,
  ) {
    return '$metric: $value. Comparison with your history needs at least $minWeeks complete weeks; you have $baselineWeeks.';
  }

  @override
  String insightWorkoutNoBaseline(String metric, String value) {
    return '$metric: $value. Historical median is 0; percentage comparison is unavailable.';
  }

  @override
  String insightWorkoutSoFar(
    String metric,
    String value,
    String baselineWeeks,
    String median,
  ) {
    return '$metric: $value so far. Median of the prior $baselineWeeks weeks is $median; an ongoing week is not compared as a full week.';
  }

  @override
  String insightWorkoutAboveMedian(
    String metric,
    String value,
    String median,
    String pct,
  ) {
    return '$metric: $value, historical median $median; $pct% above.';
  }

  @override
  String insightWorkoutAtMedian(String metric, String value, String median) {
    return '$metric: $value, equal to the historical median ($median).';
  }

  @override
  String insightWorkoutBelowMedian(
    String metric,
    String value,
    String median,
    String pct,
  ) {
    return '$metric: $value, historical median $median; difference $pct%.';
  }

  @override
  String get insightStrengthNotApplicable =>
      'No suitable weight/repetition sets; estimated one-rep maximum is unavailable.';

  @override
  String insightStrengthNotEnoughData(String days) {
    return 'Suitable sets on $days distinct days; progress needs at least two days.';
  }

  @override
  String insightStrengthUp(String firstE1rm, String lastE1rm, String pct) {
    return 'Estimated one-rep maximum: $firstE1rm → $lastE1rm; $pct% increase.';
  }

  @override
  String insightStrengthStable(String firstE1rm, String lastE1rm) {
    return 'Estimated one-rep maximum: $firstE1rm → $lastE1rm; change within ±1%.';
  }

  @override
  String insightStrengthDown(String firstE1rm, String lastE1rm, String pct) {
    return 'Estimated one-rep maximum: $firstE1rm → $lastE1rm; change $pct%.';
  }

  @override
  String insightStrengthPlateau(String topKg, String weeks) {
    return 'Heaviest set was $topKg in each of the last $weeks consecutive data weeks.';
  }

  @override
  String get insightNutritionNoLogs => 'No nutrition data for this period.';

  @override
  String insightProteinGoalDays(
    String goal,
    String hitDays,
    String loggedDays,
  ) {
    return 'Protein goal of $goal g reached on $hitDays/$loggedDays completed days.';
  }

  @override
  String insightKcalVsGoal(
    String loggedDays,
    String avgKcal,
    String goal,
    String pctOfGoal,
  ) {
    return 'Average across $loggedDays days: $avgKcal kcal; goal $goal kcal ($pctOfGoal%).';
  }

  @override
  String insightProteinPerKgBelow(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Recorded average is $gPerKg g/kg, below the roughly $breakpoint g/kg level studied. Weight used: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightProteinPerKgInRange(
    String gPerKg,
    String breakpoint,
    String upper,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Recorded average is $gPerKg g/kg, within the $breakpoint–$upper g/kg range studied. Weight used: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightProteinPerKgAbove(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Recorded average is $gPerKg g/kg. Research found no additional lean-mass gains above roughly $breakpoint g/kg; this is not a safety limit. Weight used: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightTodayNoGoal(String loggedKcal, String loggedProtein) {
    return 'No energy goal; $loggedKcal kcal and $loggedProtein g protein recorded today.';
  }

  @override
  String insightTodayRemaining(String remainingKcal) {
    return '$remainingKcal kcal remain to your energy goal. Records may be incomplete.';
  }

  @override
  String insightTodayGoalReached(String remainingKcal) {
    return 'Remaining energy is $remainingKcal kcal; zero or a negative value means the recorded goal has been reached.';
  }

  @override
  String get assistantNoteGeneralGuideline =>
      'General guidance, not personal medical advice.';

  @override
  String get assistantNoteConsultProfessional =>
      'Consult a professional for medical assessment.';

  @override
  String get assistantNoteSoFar => 'Records so far in the ongoing period.';

  @override
  String get assistantNoteCompletedSetsCounted =>
      'Completed non-warm-up sets count toward the primary muscle; studies examine challenging sets.';

  @override
  String get assistantNoteFastLossCaution =>
      'Weekly loss exceeded 1.5%. This caution threshold is a product choice.';

  @override
  String get assistantNoteLeanMassInfo =>
      'In one study of strength athletes, roughly 0.7% weekly loss preserved lean mass better.';

  @override
  String get assistantNoteBeginnerIntermediateRange =>
      'This range was studied for beginner/intermediate athletes.';

  @override
  String get assistantNoteLoggedOnly =>
      'Recorded amounts only; records may be incomplete.';

  @override
  String get assistantNoteCompletedDaysOnly =>
      'Only completed days were included.';

  @override
  String get assistantNoteChooseGoalDirection =>
      'Select a goal direction for direction-specific interpretation.';

  @override
  String get assistantQualityUnavailable =>
      'Could not write local quality event. You can still use your results.';

  @override
  String get assistantDecisionAuto => 'Automatic';

  @override
  String get assistantDecisionClarify => 'Clarification';

  @override
  String get assistantDecisionMulti => 'Multiple topics';

  @override
  String get assistantDecisionFallback => 'Fallback to ready questions';

  @override
  String get assistantDecisionError => 'Network / quota error';

  @override
  String get assistantMuscleChest => 'Chest';

  @override
  String get assistantMuscleUpperChest => 'Upper chest';

  @override
  String get assistantMuscleBack => 'Back';

  @override
  String get assistantMuscleShoulders => 'Shoulders';

  @override
  String get assistantMuscleFrontDelt => 'Front delts';

  @override
  String get assistantMuscleRearDelt => 'Rear delts';

  @override
  String get assistantMuscleBiceps => 'Biceps';

  @override
  String get assistantMuscleTriceps => 'Triceps';

  @override
  String get assistantMuscleForearms => 'Forearms';

  @override
  String get assistantMuscleLegs => 'Legs';

  @override
  String get assistantMuscleQuads => 'Quads';

  @override
  String get assistantMuscleHamstrings => 'Hamstrings';

  @override
  String get assistantMuscleGlutes => 'Glutes';

  @override
  String get assistantMuscleCalves => 'Calves';

  @override
  String get assistantMuscleCore => 'Core';

  @override
  String get assistantMuscleFullBody => 'Full body';

  @override
  String get assistantMuscleOther => 'Other';

  @override
  String bmFromHealth(String app) {
    return 'Health · $app';
  }

  @override
  String get bmHideTitle => 'Hide measurement';

  @override
  String bmHideMsg(String date) {
    return 'Hide the scale measurement from $date? The record in your health app stays unchanged.';
  }

  @override
  String get healthWeightRow => 'Weight and body fat';

  @override
  String get healthWeightOn => 'On · from your scale apps';

  @override
  String get healthWeightOff => 'Off';

  @override
  String get healthConsentTitle => 'Bring in your scale measurements';

  @override
  String get healthConsentWhat =>
      'Read: weight and body fat percentage that your scale apps write to Apple Health / Health Connect. Nothing else.';

  @override
  String get healthConsentWhere =>
      'Stored in your Fit Pack account; servers are in the European Union (Germany).';

  @override
  String get healthConsentWhy =>
      'Used only for your progress chart, weight trend and weekly review.';

  @override
  String get healthConsentNoShare =>
      'Never used for ads, never sold or shared with third parties.';

  @override
  String get healthConsentWithdraw =>
      'You can withdraw anytime in Settings → Health; imported measurements are then deleted.';

  @override
  String get healthConsentLegal =>
      'This is your explicit consent to the processing of health data (GDPR Art. 9, KVKK Art. 6).';

  @override
  String get healthConsentAccept => 'I agree';

  @override
  String get healthConsentDecline => 'Not now';

  @override
  String get healthWithdrawTitle => 'Withdraw consent';

  @override
  String get healthWithdrawMsg =>
      'Importing from your scale stops and the measurements already imported are deleted (also from the cloud). If you consent again later, only new measurements are imported.';

  @override
  String get healthWithdrawDelete => 'Delete measurements';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacySubtitle => 'What data we process, where, and your rights';

  @override
  String get privacyAuthLink => 'How we use your data (privacy policy)';

  @override
  String get homeWeightTrend7d => '7-day trend';

  @override
  String get bmTrendLegend => 'dots: daily · line: trend';

  @override
  String get adaptiveTdeeTitle => 'Your actual expenditure (estimate)';

  @override
  String adaptiveTdeeValue(int kcal, int days) {
    return '~$kcal kcal/day · from $days completed days and your weight trend';
  }

  @override
  String adaptiveTdeeAtGoal(int goal, String change) {
    return 'With your $goal kcal goal: about $change per week';
  }

  @override
  String adaptiveTdeeNeedDays(int need, int have) {
    return 'Needs $need days marked complete in the last 4 weeks (you have $have).';
  }

  @override
  String adaptiveTdeeNeedWeighIns(int count, int days) {
    return 'Needs at least $count weigh-ins spread over $days days.';
  }

  @override
  String get adaptiveTdeeInconsistent =>
      'Logs look incomplete for an estimate — check that completed days are fully logged.';

  @override
  String get adaptiveTdeeNote =>
      'Estimate (1 kg ≈ 7,700 kcal). Your goal is not changed automatically.';

  @override
  String get healthWriteWorkouts => 'Save workouts to Health';

  @override
  String get healthWriteWorkoutsNote =>
      'Live sessions appear in Apple Health / Health Connect (time and name; no calories).';

  @override
  String get expDraftError =>
      'Could not load your workout in progress. Try again.';

  @override
  String expFirstMeal(String goal) {
    return 'Today 0 / $goal kcal';
  }

  @override
  String get expPlanSubtitle =>
      'Suggested from your goal — adjust freely. You can change these anytime in Profile.';

  @override
  String get expMeasurementError =>
      'Could not change the measurement. Try again.';

  @override
  String get expAuthConnection =>
      'Could not connect. Check your internet and try again.';

  @override
  String get expAuthCredentials => 'Incorrect email or password.';

  @override
  String get expAuthUnconfirmed => 'Confirm your email before signing in.';

  @override
  String get expAuthExists =>
      'An account already uses this email. Try signing in.';

  @override
  String get expAuthRateLimit =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get expAuthPassword =>
      'Choose a different password with at least 6 characters.';

  @override
  String get expAuthGeneric => 'Could not complete the request. Try again.';

  @override
  String get expConfirmTitle => 'Confirm your email';

  @override
  String get expConfirmHelp =>
      'Check your inbox and spam folder. If you opened the link on another device, return here and sign in. You can also continue with Google.';

  @override
  String get expResend => 'Resend confirmation email';

  @override
  String get expChangeEmail => 'Change email address';

  @override
  String get expEmailSent => 'Confirmation email sent.';

  @override
  String get expAmountDecrease => 'Decrease amount';

  @override
  String get expAmountIncrease => 'Increase amount';

  @override
  String get expAmount => 'Amount';

  @override
  String get expUpdate => 'Update';

  @override
  String get expBarcode => 'Barcode';

  @override
  String get expCreateFood => 'Create your own food';

  @override
  String get expYesterdayMeal => 'Add yesterday’s meal';

  @override
  String expProteinRemaining(String grams) {
    return '$grams g protein left';
  }

  @override
  String expTodayLeftBoth(String protein, String kcal) {
    return 'Today: $protein g protein and $kcal kcal left.';
  }

  @override
  String expTodayLeftProtein(String protein) {
    return 'Today: $protein g protein left.';
  }

  @override
  String expTodayLeftKcal(String kcal) {
    return 'Today: $kcal kcal left.';
  }

  @override
  String get asExitMsg2 =>
      'If you save, pick up where you left off from the Continue card on Home. The rest timer and lock screen card stop.';

  @override
  String get asSaveAndExit => 'Save and exit';

  @override
  String get asDiscardAndExit => 'Discard and exit';

  @override
  String get asDraftSaveError =>
      'Couldn\'t save the workout — try again before leaving';

  @override
  String get asFinishIncompleteTitle => 'Finish workout?';

  @override
  String asFinishIncompleteMsg(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets aren\'t done.',
      one: '1 set isn\'t done.',
    );
    return '$_temp0 Entered values are saved, empty sets are skipped.';
  }

  @override
  String get asFinishAnyway => 'Finish with completed';

  @override
  String get asEnterValueFirst => 'Enter this set\'s value first';

  @override
  String asSuggestWithPrev(String value, String prev) {
    return '✓ logs $value · last time $prev';
  }

  @override
  String asPrevOnly(String prev) {
    return 'Last time $prev';
  }

  @override
  String get asRestMinus => '−15 s';

  @override
  String get asRestPlus => '+15 s';

  @override
  String get asRestMinusHint => 'Shorten rest by 15 seconds';

  @override
  String get asRestPlusHint => 'Extend rest by 15 seconds';

  @override
  String asRestStarted(String time) {
    return 'Rest started, $time';
  }

  @override
  String asSemCompleteSet(int n, String value) {
    return 'Complete set $n: $value';
  }

  @override
  String asSemCompleteSetEmpty(int n) {
    return 'Complete set $n';
  }

  @override
  String asSemUndoSet(int n) {
    return 'Set $n done. Tap to undo';
  }

  @override
  String asSemField(int n, String field) {
    return 'Set $n $field';
  }

  @override
  String asSemSuggestion(String value) {
    return 'suggested $value';
  }

  @override
  String asSemSetOptions(int n, String type) {
    return 'Set $n, $type. Set type and RPE';
  }

  @override
  String asSetOptionsTitle(int n) {
    return 'Set $n';
  }

  @override
  String get asTypeNormal => 'Normal';

  @override
  String get asTypeWarmup => 'Warm-up';

  @override
  String get asTypeDrop => 'Drop set';

  @override
  String get asTypeFailure => 'To failure';

  @override
  String get asSetType => 'Set type';

  @override
  String get asKbNext => 'Next';

  @override
  String get asKbDone => 'Done';

  @override
  String get today3aFinishedKicker => 'DONE TODAY';

  @override
  String today3aFinishedSub(int mins) {
    return 'Saved · $mins min';
  }

  @override
  String get today3aFinishedSubNoTime => 'Saved';

  @override
  String get today3aViewSummary => 'View summary';

  @override
  String get today3aTrainAnyway => 'Train anyway';

  @override
  String today3aAddMealHint(String meal) {
    return 'Add meal: $meal';
  }

  @override
  String get prog3cSegTraining => 'Training';

  @override
  String get prog3cSegBody => 'Body';

  @override
  String get prog3cSegWeek => 'Week';

  @override
  String get prog3cSegmentLabel => 'Progress section';

  @override
  String get prog3cTopTitle => 'Main lifts';

  @override
  String get prog3cTopNote => 'Daily best estimated 1RM · last 8 weeks';

  @override
  String get prog3cE1rm => 'est. 1RM';

  @override
  String prog3cLatest(String value) {
    return 'latest $value';
  }

  @override
  String prog3cDelta(String delta) {
    return '$delta · 4 weeks';
  }

  @override
  String get prog3cNoCurve => 'One more training day for a trend';

  @override
  String get prog3cRecordsTitle => 'Records in the last 30 days';

  @override
  String get prog3cNoRecords => 'No new records in the last 30 days';

  @override
  String get prog3cVolumeTitle => 'Weekly volume';

  @override
  String get prog3cVolumeNote => 'Last 8 weeks · weeks without logs stay empty';

  @override
  String get prog3cNoData => 'no data';

  @override
  String prog3cEmptyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more workouts to compare',
      one: '1 more workout to compare',
    );
    return '$_temp0';
  }

  @override
  String get prog3cEmptyMsg =>
      'Log workouts on two different days and your progress shows up here.';

  @override
  String get prog3cStartWorkout => 'Go to training';

  @override
  String get analyticsSectionTitle => 'Your usage preference';

  @override
  String get analyticsSwitchTitle => 'Help improve Fit Pack';

  @override
  String get analyticsSwitchDescription =>
      'Share limited usage and technical information. Off by default.';

  @override
  String get analyticsNotAvailable =>
      'This feature is not available yet. Your usage information is not shared.';

  @override
  String get analyticsConsentTitle => 'Share usage information?';

  @override
  String get analyticsConsentDescription =>
      'App visits, onboarding steps, workout starts and saves, app version and limited error/sync codes linked to your account are shared to improve Fit Pack. Weight, reps, foods, photos, steps and your written text are not sent. Raw usage information is kept for 30 days and preference history for 180 days. You can turn it off at any time; pending information is removed from this device. If you turn it off while offline, withdrawal reaches the server after reconnecting.';

  @override
  String get analyticsConsentAccept => 'Share usage information';

  @override
  String get analyticsEnabled => 'Usage sharing is on.';

  @override
  String get analyticsDisabled =>
      'Usage sharing is off; pending information was removed.';

  @override
  String get analyticsPreferenceError =>
      'Your preference could not be confirmed with the server. If you turned sharing off, it stopped on this device; withdrawal will be sent after reconnecting.';

  @override
  String get analyticsPurposeBoundary =>
      'This choice does not allow advertising, special offers or personalized notification delivery. You can use the app with sharing off.';

  @override
  String get analyticsWithdraw => 'Withdraw my server analytics preference';

  @override
  String get setupPlanSourceQuestion =>
      'How would you like to plan your training?';

  @override
  String get setupSourceCatalog => 'Help me choose a program';

  @override
  String get setupSourceCatalogDesc =>
      'Match an existing gym program to your answers.';

  @override
  String get setupSourceOwn => 'I will use my own routine';

  @override
  String get setupSourceOwnDesc =>
      'Keep your own plan. You can create or choose routines after setup.';

  @override
  String get setupDaysQuestion => 'How many training days fit a busy week?';

  @override
  String setupDaysCount(int count) {
    return '$count days';
  }

  @override
  String get setupTimeQuestion => 'Optional: time available per workout';

  @override
  String get setupTimeNone => 'No time limit';

  @override
  String setupMinutes(int count) {
    return '$count min';
  }

  @override
  String get setupOwnTitle => 'Your plan stays yours';

  @override
  String get setupOwnReason =>
      'You chose your own routine, so no catalog program will be added. Your weekly target is saved; choose or create your routine in Training.';

  @override
  String setupRecommendationReason(int days) {
    return 'Your experience and $days-day budget were used to choose from the existing catalog. You can change either answer.';
  }

  @override
  String setupFrequencyMismatch(int selected, int program) {
    return 'You chose $selected days. This catalog program recommends $program days. Your target will not be changed and the program content will stay the same.';
  }

  @override
  String setupTimeEstimate(int minutes) {
    return 'Longest routine: about $minutes min, excluding warm-up, equipment changes and waiting.';
  }

  @override
  String setupTimeMismatch(int minutes) {
    return 'This may exceed your $minutes-minute budget. Sets and rest times will not be shortened automatically.';
  }

  @override
  String get setupOwnTime =>
      'Your time budget is saved. Check the duration of your own routine before starting.';

  @override
  String get setupConfirmMismatch =>
      'I have reviewed these differences and choose to use this route.';

  @override
  String get setupChangeAnswers => 'Change my answers';

  @override
  String get setupLocalPreference =>
      'These training preferences are saved for this account on this device. They do not sync to other devices.';

  @override
  String get setupNutritionChoice =>
      'Choose your nutrition direction to continue. It will not be selected for you.';

  @override
  String get setupSaveError =>
      'Your training choices could not be saved. Your setup is still open; try again.';

  @override
  String get goalTitle => 'Your goal journey';

  @override
  String get goalWhyTitle => 'What matters to you?';

  @override
  String get goalWhyDescription =>
      'Choose what you want to understand from your real records. You can change this and keep logging without choosing.';

  @override
  String get goalPurposeRoutine => 'Build a rhythm I can sustain';

  @override
  String get goalPurposeStrength => 'Understand progress in one exercise';

  @override
  String get goalPurposeReturn => 'Return to my own routine';

  @override
  String get goalLocalOnly =>
      'These preferences stay on this device for this account. They do not change your program or nutrition targets.';

  @override
  String get goalLoadError =>
      'Could not read your goal. Retry without changing your plan.';

  @override
  String get goalBaselineTitle => 'Your starting point';

  @override
  String get goalNoBaseline =>
      'No earlier records here. Your first real workout will give you a starting point.';

  @override
  String goalBaselineCount(int count) {
    return 'Records on $count days in the 28 days before this journey.';
  }

  @override
  String get goalRecordsScope =>
      'Records may be incomplete. An unlogged day does not mean you did nothing.';

  @override
  String get goalChooseExercise => 'Choose an exercise from your real records';

  @override
  String get goalRouteTitle => 'Your weekly route';

  @override
  String goalWeeklyDays(int count) {
    return 'Weekly plan: $count training days';
  }

  @override
  String get goalTargetUnknown => 'No confirmed target for this week yet.';

  @override
  String goalTimeBudget(int count) {
    return 'Your time constraint: $count minutes per workout';
  }

  @override
  String get goalNoRoute =>
      'No routine selected. You can use your own routine or choose a catalog program in Workouts.';

  @override
  String get goalRouteExplanation =>
      'Your existing routine order stays the same. A weekly time plan is not a new exercise prescription.';

  @override
  String get goalChooseNextWeek => 'Choose next week’s training days';

  @override
  String get goalNextWeekOnly =>
      'Choose the number of separate days. This applies from next week; earlier weeks keep their own target.';

  @override
  String get goalConfirmTitle => 'Confirm next week’s plan';

  @override
  String goalConfirmNextWeek(int count) {
    return 'Plan $count separate training days from next week? Your routine, weights and nutrition targets stay the same.';
  }

  @override
  String get goalTodayTitle => 'Your next real step';

  @override
  String get goalResumeAction => 'Continue your workout';

  @override
  String get goalTodayRecorded =>
      'Your workout is recorded today. You can review it.';

  @override
  String get goalTodayDescription =>
      'See your workout plan and choose when to begin. Rest days do not require opening the app.';

  @override
  String get goalOpenNextAction => 'Open the next step';

  @override
  String get goalMilestonesTitle => 'Progress you can see';

  @override
  String get goalMilestoneStart => 'A real starting record';

  @override
  String get goalMilestoneCompare => 'Two different days to compare';

  @override
  String get goalMilestoneReview => 'A weekly reflection you chose';

  @override
  String get goalComparisonBoundary =>
      'These are recorded sets, not a strength score. Different equipment or technique can affect the comparison.';

  @override
  String get goalNeedComparison =>
      'Choose an exercise. Two different days of completed working sets are needed for comparison.';

  @override
  String get goalReturnEvidence =>
      'Your next real record starts your return. Old peak weights are context, not today’s obligation.';

  @override
  String get goalRhythmEvidence =>
      'Look for a rhythm you can repeat. A week of records does not guarantee a body or strength outcome.';

  @override
  String get goalReflectionTitle => 'Reflect on the last complete week';

  @override
  String goalRecordedDays(int count) {
    return 'Records on $count separate training days';
  }

  @override
  String get goalPastTargetUnknown =>
      'That week’s target is unknown; no success or failure is inferred.';

  @override
  String get goalRecordsAccurate => 'These records represent my week';

  @override
  String get goalTimeObstacle => 'My available time was the obstacle';

  @override
  String goalTimeReason(int count) {
    return 'You reported a time constraint; there are records on $count days. You can choose a realistic budget for next week. Nothing changes automatically.';
  }

  @override
  String get goalMarkReviewed => 'Save my reflection';

  @override
  String get goalAddMissingRecord => 'I trained but did not log it';

  @override
  String get goalOpenWeek => 'Open the weekly details';

  @override
  String get goalFlexTitle => 'Your plan can change';

  @override
  String get goalFlexDescription =>
      'Travel or a break can change your available time. Choose a future plan when it suits you; missed sessions are not a debt.';

  @override
  String get goalHealthBoundary =>
      'If pain or an injury affects training, seek appropriate professional guidance. This app does not provide treatment or a rehabilitation plan.';

  @override
  String get goalReminderSettings => 'Manage existing reminders';

  @override
  String get goalEntryTitle => 'Connect your records to a goal';

  @override
  String get goalEntryDescription =>
      'Your reason, your route and your weekly reflection';

  @override
  String get goalTrainingDaysLabel => 'Training days';

  @override
  String goalSessionCount(int count) {
    return '$count workout records; more than one on a day still counts as one training day.';
  }

  @override
  String goalSuggestDays(int count) {
    return 'Consider $count days next week';
  }

  @override
  String get goalAccountChanged =>
      'Your account changed. Reopen this page from your current account.';

  @override
  String goalEffectiveFrom(String date) {
    return 'Target effective from $date';
  }

  @override
  String get goalRecordedStart =>
      'Your first workout is recorded. It is now a real starting point.';

  @override
  String get goalStepDone => 'Completed';

  @override
  String get goalStepPending => 'Not yet recorded';

  @override
  String get goalAccountDeletedCleanupWarning =>
      'Your account was deleted. Some local training preferences could not be cleared on this device.';

  @override
  String get goalSetupRecovery =>
      'Your catalog choice is saved, but its routines are not here yet. Review the program to complete setup.';

  @override
  String get goalCompleteRoute => 'Review and finish program setup';

  @override
  String get asReplaceExercise => 'Replace exercise';

  @override
  String get asReplaceExplanation =>
      'Completed sets and any entered values stay with the original exercise. Only empty sets move to the exercise you choose. If there are no empty sets, it starts with one new set. This change applies only to this session.';

  @override
  String get asReplaceChoose => 'Choose exercise';

  @override
  String get asReplaceError =>
      'The exercise could not be replaced. Your current sets are unchanged. Try again.';
}
