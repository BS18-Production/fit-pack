import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_en.dart';
import 'app_l10n_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fit Pack'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get commonInvalidNumber;

  /// No description provided for @commonRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Range: {min} – {max}'**
  String commonRangeHint(String min, String max);

  /// No description provided for @commonRangeError.
  ///
  /// In en, this message translates to:
  /// **'Must be between {min} and {max}'**
  String commonRangeError(String min, String max);

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @macroCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get macroCalories;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get homeToday;

  /// No description provided for @homeExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get homeExportTooltip;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// No description provided for @homeStreakKicker.
  ///
  /// In en, this message translates to:
  /// **'On a streak'**
  String get homeStreakKicker;

  /// No description provided for @homeStreakKickerZero.
  ///
  /// In en, this message translates to:
  /// **'New week, new rhythm'**
  String get homeStreakKickerZero;

  /// No description provided for @homeStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'{count}-day\nstreak 🔥'**
  String homeStreakTitle(int count);

  /// No description provided for @homeStreakTitleZero.
  ///
  /// In en, this message translates to:
  /// **'Start your streak 💪'**
  String get homeStreakTitleZero;

  /// No description provided for @homeStatWorkouts.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get homeStatWorkouts;

  /// No description provided for @homeStatVolume.
  ///
  /// In en, this message translates to:
  /// **'kg volume'**
  String get homeStatVolume;

  /// No description provided for @homeStatKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get homeStatKcal;

  /// No description provided for @homeTodayRoutine.
  ///
  /// In en, this message translates to:
  /// **'Today: {name}'**
  String homeTodayRoutine(String name);

  /// No description provided for @homeStartWithCount.
  ///
  /// In en, this message translates to:
  /// **'Start workout · {count} exercises'**
  String homeStartWithCount(int count);

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get homeStart;

  /// No description provided for @homeStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a workout'**
  String get homeStartTitle;

  /// No description provided for @homeStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a routine or start an empty workout'**
  String get homeStartSubtitle;

  /// No description provided for @homeRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest day today'**
  String get homeRestTitle;

  /// No description provided for @homeRestNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String homeRestNext(String name);

  /// No description provided for @homeWorkoutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Work out anyway'**
  String get homeWorkoutAnyway;

  /// No description provided for @homeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get homeThisWeek;

  /// No description provided for @homeWeekGoalDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} workouts done'**
  String homeWeekGoalDone(int done, int total);

  /// No description provided for @homeWeekGoalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String homeWeekGoalCount(int count);

  /// No description provided for @homeMetricVolume.
  ///
  /// In en, this message translates to:
  /// **'volume lifted'**
  String get homeMetricVolume;

  /// No description provided for @homeMetricKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal burned'**
  String get homeMetricKcal;

  /// No description provided for @homeMetricWorkouts.
  ///
  /// In en, this message translates to:
  /// **'workouts done'**
  String get homeMetricWorkouts;

  /// No description provided for @homeMetricProtein.
  ///
  /// In en, this message translates to:
  /// **'avg protein goal'**
  String get homeMetricProtein;

  /// No description provided for @homeNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nutrition'**
  String get homeNutritionTitle;

  /// No description provided for @nutritionKcalLeft.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get nutritionKcalLeft;

  /// No description provided for @nutritionKcalOver.
  ///
  /// In en, this message translates to:
  /// **'kcal over'**
  String get nutritionKcalOver;

  /// No description provided for @homeInsightLabel.
  ///
  /// In en, this message translates to:
  /// **'INSIGHT'**
  String get homeInsightLabel;

  /// No description provided for @homeInsightMostImproved.
  ///
  /// In en, this message translates to:
  /// **'Most improved: {name}'**
  String homeInsightMostImproved(String name);

  /// No description provided for @homeInsightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your estimated 1RM rose in the last 6 weeks'**
  String get homeInsightSubtitle;

  /// No description provided for @homeWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get homeWaterTitle;

  /// No description provided for @homeWaterAmount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {goal} L'**
  String homeWaterAmount(String current, String goal);

  /// No description provided for @homeWaterAdd.
  ///
  /// In en, this message translates to:
  /// **'+250 ml'**
  String get homeWaterAdd;

  /// No description provided for @homeWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest weight'**
  String get homeWeightTitle;

  /// No description provided for @homeWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight'**
  String get homeWeightEmpty;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get settingsProfileNotFound;

  /// No description provided for @settingsProfileNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try restarting the app'**
  String get settingsProfileNotFoundHint;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load settings'**
  String get settingsLoadError;

  /// No description provided for @settingsSectionGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get settingsSectionGoals;

  /// No description provided for @settingsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get settingsSectionBody;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get settingsSectionNutrition;

  /// No description provided for @settingsSectionMyData.
  ///
  /// In en, this message translates to:
  /// **'My Data'**
  String get settingsSectionMyData;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsKcalGoal.
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get settingsKcalGoal;

  /// No description provided for @settingsProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein Goal'**
  String get settingsProteinGoal;

  /// No description provided for @settingsHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsHeight;

  /// No description provided for @settingsGoalWeight.
  ///
  /// In en, this message translates to:
  /// **'Goal Weight'**
  String get settingsGoalWeight;

  /// No description provided for @settingsGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get settingsGender;

  /// No description provided for @settingsBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get settingsBirthDate;

  /// No description provided for @settingsActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get settingsActivityLevel;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsFoods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get settingsFoods;

  /// No description provided for @settingsFoodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Food database — view, edit and add values'**
  String get settingsFoodsSubtitle;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Back Up to Device'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your data as a file (Drive/Files) — restorable'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get settingsRestore;

  /// No description provided for @settingsRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup file you saved earlier'**
  String get settingsRestoreSubtitle;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export Data (report)'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Readable report — Markdown / JSON / CSV'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsCloudAccount.
  ///
  /// In en, this message translates to:
  /// **'Cloud Account'**
  String get settingsCloudAccount;

  /// No description provided for @settingsCloudSignedIn.
  ///
  /// In en, this message translates to:
  /// **'{email} · back up / restore to cloud'**
  String settingsCloudSignedIn(String email);

  /// No description provided for @settingsCloudSignedInFallback.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsCloudSignedInFallback;

  /// No description provided for @settingsCloudSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in → back up to cloud, restore on a new device'**
  String get settingsCloudSignedOut;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · Personal fitness tracking'**
  String settingsAboutSubtitle(String version);

  /// No description provided for @settingsGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsGenderMale;

  /// No description provided for @settingsGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsGenderFemale;

  /// No description provided for @settingsBirthDateValue.
  ///
  /// In en, this message translates to:
  /// **'{date} · age {age}'**
  String settingsBirthDateValue(String date, int age);

  /// No description provided for @settingsPickBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Pick your birth date'**
  String get settingsPickBirthDate;

  /// No description provided for @settingsDailyEnergyTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated Daily Burn'**
  String get settingsDailyEnergyTitle;

  /// No description provided for @settingsDailyEnergyValue.
  ///
  /// In en, this message translates to:
  /// **'~{total} kcal/day  ·  resting {bmr}'**
  String settingsDailyEnergyValue(int total, int bmr);

  /// No description provided for @settingsDailyEnergyMissing.
  ///
  /// In en, this message translates to:
  /// **'To calculate, enter: {fields}'**
  String settingsDailyEnergyMissing(String fields);

  /// No description provided for @settingsMissingWeight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get settingsMissingWeight;

  /// No description provided for @settingsMissingHeight.
  ///
  /// In en, this message translates to:
  /// **'height'**
  String get settingsMissingHeight;

  /// No description provided for @settingsMissingBirthDate.
  ///
  /// In en, this message translates to:
  /// **'birth date'**
  String get settingsMissingBirthDate;

  /// No description provided for @settingsMissingGender.
  ///
  /// In en, this message translates to:
  /// **'gender'**
  String get settingsMissingGender;

  /// No description provided for @settingsBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create backup: {error}'**
  String settingsBackupFailed(String error);

  /// No description provided for @settingsRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get settingsRestoreConfirmTitle;

  /// No description provided for @settingsRestoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will replace all your current data with this backup. This can\'t be undone. Continue?'**
  String get settingsRestoreConfirmMessage;

  /// No description provided for @settingsRestoreConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestoreConfirmAction;

  /// No description provided for @settingsRestoreFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get settingsRestoreFailedTitle;

  /// No description provided for @settingsRestoreFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, your current data is safe. The app will close — just reopen it.'**
  String get settingsRestoreFailedMessage;

  /// No description provided for @settingsRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String settingsRestoreFailed(String error);

  /// No description provided for @settingsRestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get settingsRestoredTitle;

  /// No description provided for @settingsRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. The app will close so changes take effect — just reopen it.'**
  String get settingsRestoredMessage;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System (device)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System (device)'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get activityModerate;

  /// No description provided for @activityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activityActive;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get activityVeryActive;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Fit Pack'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Your workouts, nutrition and progress — all in one place.'**
  String get onbWelcomeTagline;

  /// No description provided for @onbWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to build your plan — takes under a minute.'**
  String get onbWelcomeHint;

  /// No description provided for @onbAboutYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get to know you'**
  String get onbAboutYouTitle;

  /// No description provided for @onbAboutYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your weight is enough for a goal suggestion — the rest is optional (gender and birth date improve the daily energy estimate).'**
  String get onbAboutYouSubtitle;

  /// No description provided for @onbCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get onbCurrentWeight;

  /// No description provided for @onbGoalWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Goal weight (optional)'**
  String get onbGoalWeightOptional;

  /// No description provided for @onbBirthDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Birth date (optional)'**
  String get onbBirthDateOptional;

  /// No description provided for @commonSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelect;

  /// No description provided for @onbYourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get onbYourGoal;

  /// No description provided for @phaseCut.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get phaseCut;

  /// No description provided for @phaseCutDesc.
  ///
  /// In en, this message translates to:
  /// **'Burn fat, keep muscle'**
  String get phaseCutDesc;

  /// No description provided for @phaseMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get phaseMaintain;

  /// No description provided for @phaseMaintainDesc.
  ///
  /// In en, this message translates to:
  /// **'Sustain your current shape'**
  String get phaseMaintainDesc;

  /// No description provided for @phaseBulk.
  ///
  /// In en, this message translates to:
  /// **'Build Muscle'**
  String get phaseBulk;

  /// No description provided for @phaseBulkDesc.
  ///
  /// In en, this message translates to:
  /// **'Gain muscle, get stronger'**
  String get phaseBulkDesc;

  /// No description provided for @onbPlanReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready ✨'**
  String get onbPlanReadyTitle;

  /// No description provided for @onbPlanReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your goal — adjust freely. You can change these anytime in Settings.'**
  String get onbPlanReadySubtitle;

  /// No description provided for @onbDailyKcal.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal'**
  String get onbDailyKcal;

  /// No description provided for @onbDailyProtein.
  ///
  /// In en, this message translates to:
  /// **'Daily protein goal'**
  String get onbDailyProtein;

  /// No description provided for @onbProjectionCut.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you could reach {goal} kg in roughly {weeks} weeks.'**
  String onbProjectionCut(String goal, int weeks);

  /// No description provided for @onbProjectionBulk.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you could build up to {goal} kg in roughly {weeks} weeks.'**
  String onbProjectionBulk(String goal, int weeks);

  /// No description provided for @onbProjectionNote.
  ///
  /// In en, this message translates to:
  /// **'An estimate — real progress varies from person to person.'**
  String get onbProjectionNote;

  /// No description provided for @onbWhatsInsideTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get onbWhatsInsideTitle;

  /// No description provided for @onbWhatsInsideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Four tabs, everything in its place:'**
  String get onbWhatsInsideSubtitle;

  /// No description provided for @onbTourHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance: streak, plan, nutrition, water'**
  String get onbTourHomeDesc;

  /// No description provided for @onbTourWorkoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Build routines, log your sets, review past sessions'**
  String get onbTourWorkoutDesc;

  /// No description provided for @onbTourNutritionDesc.
  ///
  /// In en, this message translates to:
  /// **'Add meals: search, scan a barcode, track macros'**
  String get onbTourNutritionDesc;

  /// No description provided for @onbTourProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Log weight and measurements, watch the trend'**
  String get onbTourProgressDesc;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get onbStart;

  /// No description provided for @onbGoalsNumberError.
  ///
  /// In en, this message translates to:
  /// **'Enter your calorie and protein goals as numbers'**
  String get onbGoalsNumberError;

  /// No description provided for @onbSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save — try again'**
  String get onbSaveError;

  /// No description provided for @hintWorkout.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine here — or start an empty workout right away.'**
  String get hintWorkout;

  /// No description provided for @hintNutrition.
  ///
  /// In en, this message translates to:
  /// **'Add your first meal: search by typing or scan a barcode.'**
  String get hintNutrition;

  /// No description provided for @hintProgress.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight — your chart starts here.'**
  String get hintProgress;

  /// No description provided for @hintGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hintGotIt;

  /// No description provided for @emptyRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Try restarting the app'**
  String get emptyRestartHint;

  /// No description provided for @unitAge.
  ///
  /// In en, this message translates to:
  /// **'{age} yr'**
  String unitAge(int age);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'tr':
      return AppL10nTr();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
