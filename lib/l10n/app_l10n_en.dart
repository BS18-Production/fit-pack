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
  String get homeToday => 'TODAY';

  @override
  String get homeStreakKickerZero => 'New week, new rhythm';

  @override
  String homeStreakTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-week\nstreak',
      one: '1-week\nstreak',
    );
    return '$_temp0';
  }

  @override
  String get homeStreakTitleZero => 'Start your streak';

  @override
  String get homeStreakTitleFirstWeek => 'Finish your\nfirst week';

  @override
  String homeStreakWeekProgress(int done, int goal) {
    return 'This week: $done/$goal workouts';
  }

  @override
  String get homeStatWorkouts => 'workouts';

  @override
  String homeStatVolume(String unit) {
    return '$unit volume';
  }

  @override
  String get homeStatKcal => 'kcal';

  @override
  String homeTodayRoutine(String name) {
    return 'Today: $name';
  }

  @override
  String homeStartWithCount(int count) {
    return 'Start workout · $count exercises';
  }

  @override
  String get homeStart => 'Start workout';

  @override
  String get homeStartTitle => 'Start a workout';

  @override
  String get homeStartSubtitle => 'Create a routine or start an empty workout';

  @override
  String get homeRestTitle => 'Rest day today';

  @override
  String homeRestNext(String name) {
    return 'Next: $name';
  }

  @override
  String get homeWorkoutAnyway => 'Work out anyway';

  @override
  String get homeThisWeek => 'This Week';

  @override
  String homeWeekGoalDone(int done, int total) {
    return '$done/$total workouts done';
  }

  @override
  String homeWeekGoalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String get homeMetricVolume => 'volume lifted';

  @override
  String get homeMetricKcal => 'kcal burned';

  @override
  String get homeMetricWorkouts => 'workouts done';

  @override
  String get homeMetricProtein => 'avg protein goal';

  @override
  String get homeNutritionTitle => 'Today\'s Nutrition';

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
  String get whSetsLoadError => 'Couldn\'t load sets';

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
      'Remove this routine from the list? Past workouts are kept.';

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
  String get asPastEntry => 'Past entry';

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
  String get elPickTitle => 'Pick Exercise';

  @override
  String get elSearchHint => 'Search exercises…';

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
  String get cloudSignOut => 'Sign Out';

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
  String get notifWorkout => 'Daily workout reminder';

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
  String get notifWorkoutTitle => 'Workout time';

  @override
  String get notifWorkoutBody =>
      'Your plan is waiting — a short session counts too.';

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
      'Your weight is enough for a goal suggestion — the rest is optional (gender and birth date improve the daily energy estimate).';

  @override
  String get onbCurrentWeight => 'Current weight';

  @override
  String get onbGoalWeightOptional => 'Goal weight (optional)';

  @override
  String get onbBirthDateOptional => 'Birth date (optional)';

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
  String get onbWhatsInsideTitle => 'What\'s inside';

  @override
  String get onbWhatsInsideSubtitle => 'Four tabs, everything in its place:';

  @override
  String get onbTourHomeDesc =>
      'Your day at a glance: streak, plan, nutrition, water';

  @override
  String get onbTourWorkoutDesc =>
      'Build routines, log your sets, review past sessions';

  @override
  String get onbTourNutritionDesc =>
      'Add meals: search, scan a barcode, track macros';

  @override
  String get onbTourProgressDesc =>
      'Log weight and measurements, watch the trend';

  @override
  String get onbStart => 'Let\'s go';

  @override
  String get onbGoalsNumberError =>
      'Enter your calorie and protein goals as numbers';

  @override
  String get onbSaveError => 'Couldn\'t save — try again';

  @override
  String get hintWorkout =>
      'Create your first routine here — or start an empty workout right away.';

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
}
