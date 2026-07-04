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
  String get homeExportTooltip => 'Export data';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeStreakKicker => 'On a streak';

  @override
  String get homeStreakKickerZero => 'New week, new rhythm';

  @override
  String homeStreakTitle(int count) {
    return '$count-day\nstreak 🔥';
  }

  @override
  String get homeStreakTitleZero => 'Start your streak 💪';

  @override
  String get homeStatWorkouts => 'workouts';

  @override
  String get homeStatVolume => 'kg volume';

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
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionNutrition => 'Nutrition';

  @override
  String get settingsSectionMyData => 'My Data';

  @override
  String get settingsSectionAbout => 'About';

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
  String get settingsBackup => 'Back Up to Device';

  @override
  String get settingsBackupSubtitle =>
      'Save your data as a file (Drive/Files) — restorable';

  @override
  String get settingsRestore => 'Restore from Backup';

  @override
  String get settingsRestoreSubtitle =>
      'Restore a backup file you saved earlier';

  @override
  String get settingsExport => 'Export Data (report)';

  @override
  String get settingsExportSubtitle =>
      'Readable report — Markdown / JSON / CSV';

  @override
  String get settingsCloudAccount => 'Cloud Account';

  @override
  String settingsCloudSignedIn(String email) {
    return '$email · back up / restore to cloud';
  }

  @override
  String get settingsCloudSignedInFallback => 'Signed in';

  @override
  String get settingsCloudSignedOut =>
      'Sign in → back up to cloud, restore on a new device';

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
  String settingsBackupFailed(String error) {
    return 'Couldn\'t create backup: $error';
  }

  @override
  String get settingsRestoreConfirmTitle => 'Restore from backup';

  @override
  String get settingsRestoreConfirmMessage =>
      'This will replace all your current data with this backup. This can\'t be undone. Continue?';

  @override
  String get settingsRestoreConfirmAction => 'Restore';

  @override
  String get settingsRestoreFailedTitle => 'Restore failed';

  @override
  String get settingsRestoreFailedMessage =>
      'Something went wrong, your current data is safe. The app will close — just reopen it.';

  @override
  String settingsRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get settingsRestoredTitle => 'Restored';

  @override
  String get settingsRestoredMessage =>
      'Your data has been restored. The app will close so changes take effect — just reopen it.';

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
  String get onbPlanReadyTitle => 'Your plan is ready ✨';

  @override
  String get onbPlanReadySubtitle =>
      'Suggested from your goal — adjust freely. You can change these anytime in Settings.';

  @override
  String get onbDailyKcal => 'Daily calorie goal';

  @override
  String get onbDailyProtein => 'Daily protein goal';

  @override
  String onbProjectionCut(String goal, int weeks) {
    return 'At this pace, you could reach $goal kg in roughly $weeks weeks.';
  }

  @override
  String onbProjectionBulk(String goal, int weeks) {
    return 'At this pace, you could build up to $goal kg in roughly $weeks weeks.';
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
}
