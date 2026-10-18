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

  /// No description provided for @accountErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify account'**
  String get accountErrorTitle;

  /// No description provided for @accountErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm that the data on this device belongs to you. For safety you weren\'t let in — another account\'s data could have been shown. Check your connection and try again.'**
  String get accountErrorBody;

  /// No description provided for @accountConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsynced records on this device'**
  String get accountConflictTitle;

  /// No description provided for @accountConflictBody.
  ///
  /// In en, this message translates to:
  /// **'{count} records from the previous account haven\'t been uploaded yet. Continuing with the new account deletes them.'**
  String accountConflictBody(int count);

  /// No description provided for @accountConflictGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back to previous account'**
  String get accountConflictGoBack;

  /// No description provided for @accountConflictDiscard.
  ///
  /// In en, this message translates to:
  /// **'Delete records and continue'**
  String get accountConflictDiscard;

  /// No description provided for @accountConflictDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete records?'**
  String get accountConflictDiscardTitle;

  /// No description provided for @accountConflictDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'{count} records will be permanently deleted. This can\'t be undone.'**
  String accountConflictDiscardBody(int count);

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

  /// Generic SnackBar when a user-initiated write fails (CR-019).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save, try again'**
  String get commonSaveFailed;

  /// No description provided for @commonDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete, try again'**
  String get commonDeleteFailed;

  /// No description provided for @commonUndoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo, try again'**
  String get commonUndoFailed;

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

  /// No description provided for @macroProteinAbbr.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get macroProteinAbbr;

  /// No description provided for @macroCarbsAbbr.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get macroCarbsAbbr;

  /// No description provided for @macroFatAbbr.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get macroFatAbbr;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

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

  /// No description provided for @homeStatWorkouts.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get homeStatWorkouts;

  /// No description provided for @homeStatVolume.
  ///
  /// In en, this message translates to:
  /// **'{unit} volume'**
  String homeStatVolume(String unit);

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

  /// No description provided for @homeUpNextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 exercise} other{{count} exercises}} · ~{mins} min'**
  String homeUpNextSubtitle(int count, int mins);

  /// No description provided for @homeNoRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your first workout'**
  String get homeNoRoutineTitle;

  /// No description provided for @homeNoRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start right away with a ready-made program or build your own routine.'**
  String get homeNoRoutineSubtitle;

  /// No description provided for @homePickProgram.
  ///
  /// In en, this message translates to:
  /// **'Pick a program'**
  String get homePickProgram;

  /// No description provided for @homeBuildRoutine.
  ///
  /// In en, this message translates to:
  /// **'Build your own routine'**
  String get homeBuildRoutine;

  /// No description provided for @homeFirstWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'FIRST WEEK'**
  String get homeFirstWeekTitle;

  /// No description provided for @homeFirstWeekProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/3 done'**
  String homeFirstWeekProgress(int done);

  /// No description provided for @homeFirstWeekWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish your first workout'**
  String get homeFirstWeekWorkout;

  /// No description provided for @homeFirstWeekMeal.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal'**
  String get homeFirstWeekMeal;

  /// No description provided for @homeFirstWeekWeight.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight'**
  String get homeFirstWeekWeight;

  /// No description provided for @homeTodayLiftIncrease.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: try {weight} this time.'**
  String homeTodayLiftIncrease(String exercise, String weight);

  /// No description provided for @homeTodayLiftAddRep.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: try +1 rep per set at {weight}.'**
  String homeTodayLiftAddRep(String exercise, String weight);

  /// No description provided for @homeTodayFirstMeal.
  ///
  /// In en, this message translates to:
  /// **'Add your first meal.'**
  String get homeTodayFirstMeal;

  /// No description provided for @homeTodayLeftBoth.
  ///
  /// In en, this message translates to:
  /// **'{protein} g protein, {kcal} kcal left today.'**
  String homeTodayLeftBoth(int protein, int kcal);

  /// No description provided for @homeTodayLeftProtein.
  ///
  /// In en, this message translates to:
  /// **'{protein} g protein left today.'**
  String homeTodayLeftProtein(int protein);

  /// No description provided for @homeTodayLeftKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left today.'**
  String homeTodayLeftKcal(int kcal);

  /// No description provided for @homeWeekReadyKicker.
  ///
  /// In en, this message translates to:
  /// **'YOUR WEEK IS READY'**
  String get homeWeekReadyKicker;

  /// No description provided for @homeWeekReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly review is ready'**
  String get homeWeekReadyTitle;

  /// No description provided for @homeWeekReadyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeWeekReadyOpen;

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

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get commonMustBePositive;

  /// No description provided for @commonNotNegative.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be negative'**
  String get commonNotNegative;

  /// No description provided for @commonEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get commonEnterName;

  /// No description provided for @nutritionPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get nutritionPickDate;

  /// No description provided for @nutritionAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get nutritionAddFood;

  /// No description provided for @nutritionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nutrition logs'**
  String get nutritionLoadError;

  /// No description provided for @nutritionCopyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Copy yesterday\'s meals'**
  String get nutritionCopyYesterday;

  /// No description provided for @nutritionCopyPrevDay.
  ///
  /// In en, this message translates to:
  /// **'Copy the previous day\'s meals'**
  String get nutritionCopyPrevDay;

  /// No description provided for @nutritionCopyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries on the previous day'**
  String get nutritionCopyEmpty;

  /// No description provided for @nutritionCopied.
  ///
  /// In en, this message translates to:
  /// **'{count} entries copied'**
  String nutritionCopied(int count);

  /// No description provided for @nutritionCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy — try again'**
  String get nutritionCopyFailed;

  /// No description provided for @nutritionMealMenu.
  ///
  /// In en, this message translates to:
  /// **'Meal options'**
  String get nutritionMealMenu;

  /// No description provided for @nutritionCopyFromDay.
  ///
  /// In en, this message translates to:
  /// **'Copy from another day'**
  String get nutritionCopyFromDay;

  /// No description provided for @nutritionCopyMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy {meal}'**
  String nutritionCopyMealTitle(String meal);

  /// No description provided for @nutritionCopyPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick the day to copy from'**
  String get nutritionCopyPickDay;

  /// No description provided for @nutritionCopyNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No entries for this meal in the last {days} days'**
  String nutritionCopyNoHistory(int days);

  /// No description provided for @nutritionCopyEditHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust the amounts, drop what you don\'t want'**
  String get nutritionCopyEditHint;

  /// No description provided for @nutritionCopyAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String nutritionCopyAddCount(int count);

  /// No description provided for @nutritionCopyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get nutritionCopyRemove;

  /// No description provided for @nutritionPrevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get nutritionPrevDay;

  /// No description provided for @nutritionNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nutritionNextDay;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @mealSnackShort.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnackShort;

  /// No description provided for @nutritionAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String nutritionAddTo(String meal);

  /// No description provided for @nutritionNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get nutritionNoEntries;

  /// No description provided for @nutritionAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add — try again'**
  String get nutritionAddFailed;

  /// No description provided for @nutritionOffNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results on OpenFoodFacts. You can add it manually.'**
  String get nutritionOffNoResults;

  /// No description provided for @nutritionMultiAddHint.
  ///
  /// In en, this message translates to:
  /// **'You can add more than one'**
  String get nutritionMultiAddHint;

  /// No description provided for @nutritionSessionAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} added · last: {name}'**
  String nutritionSessionAdded(int count, String name);

  /// No description provided for @nutritionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search foods…'**
  String get nutritionSearchHint;

  /// No description provided for @nutritionScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get nutritionScanBarcode;

  /// No description provided for @nutritionAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add your own food'**
  String get nutritionAddCustom;

  /// No description provided for @nutritionOffSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching OpenFoodFacts…'**
  String get nutritionOffSearching;

  /// No description provided for @nutritionOffSearchFor.
  ///
  /// In en, this message translates to:
  /// **'Search packaged product online: \"{query}\"'**
  String nutritionOffSearchFor(String query);

  /// No description provided for @nutritionOffHeader.
  ///
  /// In en, this message translates to:
  /// **'OpenFoodFacts · \"{query}\" ({count})'**
  String nutritionOffHeader(String query, int count);

  /// No description provided for @nutritionNoFoods.
  ///
  /// In en, this message translates to:
  /// **'No foods'**
  String get nutritionNoFoods;

  /// No description provided for @nutritionNotFound.
  ///
  /// In en, this message translates to:
  /// **'\"{query}\" not found'**
  String nutritionNotFound(String query);

  /// No description provided for @nutritionNotInListHint.
  ///
  /// In en, this message translates to:
  /// **'If it\'s not in the list, add it yourself'**
  String get nutritionNotInListHint;

  /// No description provided for @nutritionUnitApprox.
  ///
  /// In en, this message translates to:
  /// **'1 {unit} ≈ {grams} g'**
  String nutritionUnitApprox(String unit, int grams);

  /// No description provided for @nutritionCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Your own food'**
  String get nutritionCustomTitle;

  /// No description provided for @nutritionCustomHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the values for one unit (e.g. 1 portion of \"3-Egg Omelette\"): how many grams plus that amount\'s kcal/macros. It gets converted to /100g, saved and reused. No unit? Pick \"(no unit)\".'**
  String get nutritionCustomHelp;

  /// No description provided for @nutritionFoodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get nutritionFoodName;

  /// No description provided for @nutritionUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get nutritionUnit;

  /// No description provided for @nutritionNoUnitOption.
  ///
  /// In en, this message translates to:
  /// **'(no unit — grams only)'**
  String get nutritionNoUnitOption;

  /// No description provided for @nutritionOneUnit.
  ///
  /// In en, this message translates to:
  /// **'1 {unit}'**
  String nutritionOneUnit(String unit);

  /// No description provided for @nutritionPortionGrams.
  ///
  /// In en, this message translates to:
  /// **'Portion (g)'**
  String get nutritionPortionGrams;

  /// No description provided for @nutritionUnitGramsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many grams is 1 {unit}?'**
  String nutritionUnitGramsQuestion(String unit);

  /// No description provided for @nutritionTotalKcal.
  ///
  /// In en, this message translates to:
  /// **'Total kcal'**
  String get nutritionTotalKcal;

  /// No description provided for @nutritionAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get nutritionAdding;

  /// No description provided for @nutritionAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'{name} (already saved)'**
  String nutritionAlreadySaved(String name);

  /// No description provided for @nutritionOffQuerying.
  ///
  /// In en, this message translates to:
  /// **'Querying OpenFoodFacts…'**
  String get nutritionOffQuerying;

  /// No description provided for @nutritionProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found ({code}). You can add it manually.'**
  String nutritionProductNotFound(String code);

  /// No description provided for @nutritionAddedFromOff.
  ///
  /// In en, this message translates to:
  /// **'{name} added (OpenFoodFacts)'**
  String nutritionAddedFromOff(String name);

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanTitle;

  /// No description provided for @scanTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get scanTorchOn;

  /// No description provided for @scanTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off flashlight'**
  String get scanTorchOff;

  /// No description provided for @scanPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Allow it in Settings or add the food manually.'**
  String get scanPermissionDenied;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera couldn\'t start. You can add the food manually.'**
  String get scanCameraError;

  /// No description provided for @scanFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Line up the barcode in the frame'**
  String get scanFrameHint;

  /// No description provided for @scanManualAdd.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get scanManualAdd;

  /// No description provided for @foodsNew.
  ///
  /// In en, this message translates to:
  /// **'New food'**
  String get foodsNew;

  /// No description provided for @foodCatMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat, fish, eggs'**
  String get foodCatMeat;

  /// No description provided for @foodCatDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get foodCatDairy;

  /// No description provided for @foodCatGrain.
  ///
  /// In en, this message translates to:
  /// **'Grains & starches'**
  String get foodCatGrain;

  /// No description provided for @foodCatLegume.
  ///
  /// In en, this message translates to:
  /// **'Legumes'**
  String get foodCatLegume;

  /// No description provided for @foodCatVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get foodCatVegetable;

  /// No description provided for @foodCatFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get foodCatFruit;

  /// No description provided for @foodCatFat.
  ///
  /// In en, this message translates to:
  /// **'Fats & nuts'**
  String get foodCatFat;

  /// No description provided for @foodCatDish.
  ///
  /// In en, this message translates to:
  /// **'Prepared dishes'**
  String get foodCatDish;

  /// No description provided for @foodCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get foodCatOther;

  /// No description provided for @foodsAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String foodsAdded(String name);

  /// No description provided for @foodsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get foodsUpdated;

  /// No description provided for @foodsHasLogs.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has {count} log entries — delete those first'**
  String foodsHasLogs(String name, int count);

  /// No description provided for @foodsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete food'**
  String get foodsDeleteTitle;

  /// No description provided for @foodsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the food database?'**
  String foodsDeleteMessage(String name);

  /// No description provided for @foodsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String foodsDeleted(String name);

  /// No description provided for @foodsPer100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get foodsPer100g;

  /// No description provided for @foodsReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Built-in food — can\'t be edited (the database is protected).'**
  String get foodsReadOnlyNote;

  /// No description provided for @foodsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load foods'**
  String get foodsLoadError;

  /// No description provided for @foodsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a new food from the bottom right'**
  String get foodsEmptyHint;

  /// No description provided for @foodsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get foodsEditTitle;

  /// No description provided for @foodsFormHelp.
  ///
  /// In en, this message translates to:
  /// **'Values are entered per 100 grams. If you pick a unit, also enter \"grams per 1 unit\" — then you can log by piece/slice.'**
  String get foodsFormHelp;

  /// No description provided for @foodsKcalPer100.
  ///
  /// In en, this message translates to:
  /// **'Calories /100g (kcal)'**
  String get foodsKcalPer100;

  /// No description provided for @foodsProteinPer100.
  ///
  /// In en, this message translates to:
  /// **'Protein /100g (g)'**
  String get foodsProteinPer100;

  /// No description provided for @foodsCarbPer100.
  ///
  /// In en, this message translates to:
  /// **'Carbs /100g (g)'**
  String get foodsCarbPer100;

  /// No description provided for @foodsFatPer100.
  ///
  /// In en, this message translates to:
  /// **'Fat /100g (g)'**
  String get foodsFatPer100;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @unitMinShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinShort;

  /// No description provided for @unitReps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get unitReps;

  /// No description provided for @labelSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get labelSets;

  /// No description provided for @labelReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get labelReps;

  /// No description provided for @labelRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get labelRest;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get labelVolume;

  /// No description provided for @workoutLoadRoutinesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load routines'**
  String get workoutLoadRoutinesError;

  /// No description provided for @workoutLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get workoutLibrary;

  /// No description provided for @workoutAddPast.
  ///
  /// In en, this message translates to:
  /// **'Add Past Workout'**
  String get workoutAddPast;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistory;

  /// No description provided for @wcalTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout calendar'**
  String get wcalTitle;

  /// No description provided for @wcalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workout logged on this day.'**
  String get wcalEmpty;

  /// No description provided for @wcalAddForDay.
  ///
  /// In en, this message translates to:
  /// **'Log a workout for this day'**
  String get wcalAddForDay;

  /// No description provided for @wcalMonthCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workouts this month} =1{1 workout day this month} other{{count} workout days this month}}'**
  String wcalMonthCount(int count);

  /// No description provided for @workoutThisWeekCaps.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get workoutThisWeekCaps;

  /// No description provided for @workoutTotalVolumeCaps.
  ///
  /// In en, this message translates to:
  /// **'TOTAL VOLUME'**
  String get workoutTotalVolumeCaps;

  /// No description provided for @workoutStartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start Empty Workout'**
  String get workoutStartEmpty;

  /// No description provided for @workoutNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create New Routine'**
  String get workoutNewRoutine;

  /// No description provided for @workoutMyRoutines.
  ///
  /// In en, this message translates to:
  /// **'My Routines'**
  String get workoutMyRoutines;

  /// No description provided for @workoutNoRoutines.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get workoutNoRoutines;

  /// No description provided for @workoutNoRoutinesMsg.
  ///
  /// In en, this message translates to:
  /// **'Create your own workout routine — pick exercises, set target sets and reps.'**
  String get workoutNoRoutinesMsg;

  /// No description provided for @workoutCreateRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create routine'**
  String get workoutCreateRoutine;

  /// No description provided for @workoutResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutResumeTitle;

  /// No description provided for @workoutResumeSub.
  ///
  /// In en, this message translates to:
  /// **'{ex} exercises · {sets} sets'**
  String workoutResumeSub(int ex, int sets);

  /// No description provided for @workoutDraftDelete.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get workoutDraftDelete;

  /// No description provided for @workoutDraftDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Discard the in-progress workout draft? Your entered sets won\'t be saved.'**
  String get workoutDraftDeleteMsg;

  /// No description provided for @workoutExerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String workoutExerciseCount(int count);

  /// No description provided for @workoutSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String workoutSetCount(int count);

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready-made programs — add one and its routines become yours to edit.'**
  String get exSubtitle;

  /// No description provided for @exLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get exLevelBeginner;

  /// No description provided for @exLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get exLevelIntermediate;

  /// No description provided for @exLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get exLevelAdvanced;

  /// No description provided for @exSplitFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full body'**
  String get exSplitFullBody;

  /// No description provided for @exSplitUpperLower.
  ///
  /// In en, this message translates to:
  /// **'Upper / Lower'**
  String get exSplitUpperLower;

  /// No description provided for @exSplitPpl.
  ///
  /// In en, this message translates to:
  /// **'Push · Pull · Legs'**
  String get exSplitPpl;

  /// No description provided for @exSplitFullBodyDesc.
  ///
  /// In en, this message translates to:
  /// **'Whole body every session. Short, efficient — ideal if you train 3 days a week.'**
  String get exSplitFullBodyDesc;

  /// No description provided for @exSplitUpperLowerDesc.
  ///
  /// In en, this message translates to:
  /// **'Upper and lower body on alternating days. More volume per muscle, 4 days a week.'**
  String get exSplitUpperLowerDesc;

  /// No description provided for @exSplitPplDesc.
  ///
  /// In en, this message translates to:
  /// **'Pushing, pulling and legs on separate days. Classic bodybuilding split.'**
  String get exSplitPplDesc;

  /// No description provided for @exLevelBeginnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Mostly machines, moderate reps — learn the movements safely.'**
  String get exLevelBeginnerDesc;

  /// No description provided for @exLevelIntermediateDesc.
  ///
  /// In en, this message translates to:
  /// **'Barbell basics plus accessories, double progression.'**
  String get exLevelIntermediateDesc;

  /// No description provided for @exLevelAdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Heavy low-rep main lifts and higher weekly volume.'**
  String get exLevelAdvancedDesc;

  /// No description provided for @exDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} days/week'**
  String exDaysPerWeek(int count);

  /// No description provided for @exRoutineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 routine} other{{count} routines}}'**
  String exRoutineCount(int count);

  /// No description provided for @exProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'{split} · {level}'**
  String exProgramTitle(String split, String level);

  /// No description provided for @exAddProgram.
  ///
  /// In en, this message translates to:
  /// **'Add program'**
  String get exAddProgram;

  /// No description provided for @exAddAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Already in your routines'**
  String get exAddAgainTitle;

  /// No description provided for @exAddAgainMsg.
  ///
  /// In en, this message translates to:
  /// **'This program\'s routines are already in your list. Add another copy?'**
  String get exAddAgainMsg;

  /// No description provided for @exAddAgain.
  ///
  /// In en, this message translates to:
  /// **'Add again'**
  String get exAddAgain;

  /// No description provided for @exAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your routines'**
  String exAdded(String name);

  /// No description provided for @exAddError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the program — try again'**
  String get exAddError;

  /// No description provided for @exHowTo.
  ///
  /// In en, this message translates to:
  /// **'Rotate the routines in order, e.g. A → B → A. Targets are a starting point; the app suggests the next step from your sets.'**
  String get exHowTo;

  /// No description provided for @exFreeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Free workout'**
  String get exFreeWorkout;

  /// No description provided for @exInList.
  ///
  /// In en, this message translates to:
  /// **'In your routines'**
  String get exInList;

  /// No description provided for @exRoutineFullBodyA.
  ///
  /// In en, this message translates to:
  /// **'Full Body A'**
  String get exRoutineFullBodyA;

  /// No description provided for @exRoutineFullBodyB.
  ///
  /// In en, this message translates to:
  /// **'Full Body B'**
  String get exRoutineFullBodyB;

  /// No description provided for @exRoutineFullBodyC.
  ///
  /// In en, this message translates to:
  /// **'Full Body C'**
  String get exRoutineFullBodyC;

  /// No description provided for @exRoutineUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper'**
  String get exRoutineUpper;

  /// No description provided for @exRoutineLower.
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get exRoutineLower;

  /// No description provided for @exRoutineUpperA.
  ///
  /// In en, this message translates to:
  /// **'Upper A'**
  String get exRoutineUpperA;

  /// No description provided for @exRoutineLowerA.
  ///
  /// In en, this message translates to:
  /// **'Lower A'**
  String get exRoutineLowerA;

  /// No description provided for @exRoutineUpperB.
  ///
  /// In en, this message translates to:
  /// **'Upper B'**
  String get exRoutineUpperB;

  /// No description provided for @exRoutineLowerB.
  ///
  /// In en, this message translates to:
  /// **'Lower B'**
  String get exRoutineLowerB;

  /// No description provided for @exRoutineUpperPower.
  ///
  /// In en, this message translates to:
  /// **'Upper · Strength'**
  String get exRoutineUpperPower;

  /// No description provided for @exRoutineLowerPower.
  ///
  /// In en, this message translates to:
  /// **'Lower · Strength'**
  String get exRoutineLowerPower;

  /// No description provided for @exRoutineUpperHypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Upper · Volume'**
  String get exRoutineUpperHypertrophy;

  /// No description provided for @exRoutineLowerHypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Lower · Volume'**
  String get exRoutineLowerHypertrophy;

  /// No description provided for @exRoutinePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get exRoutinePush;

  /// No description provided for @exRoutinePull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get exRoutinePull;

  /// No description provided for @exRoutineLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get exRoutineLegs;

  /// No description provided for @workoutOwnRoutines.
  ///
  /// In en, this message translates to:
  /// **'My own'**
  String get workoutOwnRoutines;

  /// No description provided for @whRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent workouts'**
  String get whRecentTitle;

  /// No description provided for @whSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get whSeeAll;

  /// No description provided for @whMoreExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{+1 more exercise} other{+{count} more exercises}}'**
  String whMoreExercises(int count);

  /// No description provided for @whRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record} other{{count} records}}'**
  String whRecordCount(int count);

  /// No description provided for @whVsLast.
  ///
  /// In en, this message translates to:
  /// **'vs last time: {value}'**
  String whVsLast(String value);

  /// No description provided for @whDeltaReps.
  ///
  /// In en, this message translates to:
  /// **'{delta} reps'**
  String whDeltaReps(String delta);

  /// No description provided for @whDeltaSame.
  ///
  /// In en, this message translates to:
  /// **'same as last time'**
  String get whDeltaSame;

  /// No description provided for @whMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles worked'**
  String get whMuscles;

  /// No description provided for @whAvgRpe.
  ///
  /// In en, this message translates to:
  /// **'Avg RPE'**
  String get whAvgRpe;

  /// No description provided for @whNotes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get whNotes;

  /// No description provided for @whSetsWithRpe.
  ///
  /// In en, this message translates to:
  /// **'RPE {rpe}'**
  String whSetsWithRpe(String rpe);

  /// No description provided for @whRpeLegend.
  ///
  /// In en, this message translates to:
  /// **'RPE = Rate of Perceived Exertion, 10 is all-out.'**
  String get whRpeLegend;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get workoutAddExercise;

  /// No description provided for @rbEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get rbEditTitle;

  /// No description provided for @rbNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get rbNewTitle;

  /// No description provided for @rbNameCaps.
  ///
  /// In en, this message translates to:
  /// **'ROUTINE NAME'**
  String get rbNameCaps;

  /// No description provided for @rbNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push Day'**
  String get rbNameHint;

  /// No description provided for @rbNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get rbNoExercises;

  /// No description provided for @rbWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekly day (optional)'**
  String get rbWeekday;

  /// No description provided for @rbWeekdayHelper.
  ///
  /// In en, this message translates to:
  /// **'If set, Home suggests this routine on that day'**
  String get rbWeekdayHelper;

  /// No description provided for @rbNoDay.
  ///
  /// In en, this message translates to:
  /// **'No day'**
  String get rbNoDay;

  /// No description provided for @rbRestBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets'**
  String get rbRestBetweenSets;

  /// No description provided for @rbNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the routine a name'**
  String get rbNameRequired;

  /// No description provided for @rbNeedExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise'**
  String get rbNeedExercise;

  /// No description provided for @rbSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save routine — try again'**
  String get rbSaveError;

  /// No description provided for @rbTargetHint.
  ///
  /// In en, this message translates to:
  /// **'target sets×reps'**
  String get rbTargetHint;

  /// No description provided for @rbSave.
  ///
  /// In en, this message translates to:
  /// **'Save Routine'**
  String get rbSave;

  /// No description provided for @whLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load history'**
  String get whLoadError;

  /// No description provided for @whEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get whEmptyTitle;

  /// No description provided for @whEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Your first completed workout will appear here'**
  String get whEmptyMsg;

  /// No description provided for @whEditDate.
  ///
  /// In en, this message translates to:
  /// **'Edit date'**
  String get whEditDate;

  /// No description provided for @whDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get whDeleteTitle;

  /// No description provided for @whDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This session and all its sets will be deleted. Can\'t be undone.'**
  String get whDeleteMsg;

  /// No description provided for @whNoSets.
  ///
  /// In en, this message translates to:
  /// **'No set records'**
  String get whNoSets;

  /// No description provided for @whCalorieNote.
  ///
  /// In en, this message translates to:
  /// **'Calories are an estimate — based on weight, duration and intensity (RPE).'**
  String get whCalorieNote;

  /// No description provided for @wsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Summary'**
  String get wsTitle;

  /// No description provided for @wsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load summary'**
  String get wsLoadError;

  /// No description provided for @wsDone.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete'**
  String get wsDone;

  /// No description provided for @wsExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get wsExercises;

  /// No description provided for @wsNewRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{New record} other{{count} new records}}'**
  String wsNewRecords(int count);

  /// No description provided for @wsDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get wsDoneBtn;

  /// No description provided for @wsUnknownExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get wsUnknownExercise;

  /// No description provided for @rpFallback.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get rpFallback;

  /// No description provided for @rpArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive routine'**
  String get rpArchiveTitle;

  /// No description provided for @rpArchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'It moves to Archive at the bottom of the Workout tab; you can restore it anytime. Past workouts are kept.'**
  String get rpArchiveMsg;

  /// No description provided for @rpArchived.
  ///
  /// In en, this message translates to:
  /// **'Routine archived'**
  String get rpArchived;

  /// No description provided for @workoutArchiveSection.
  ///
  /// In en, this message translates to:
  /// **'Archive ({count})'**
  String workoutArchiveSection(int count);

  /// No description provided for @workoutArchiveRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get workoutArchiveRestore;

  /// No description provided for @workoutArchiveRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} is back in your routines'**
  String workoutArchiveRestored(String name);

  /// No description provided for @workoutArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Archived routines don\'t appear in your list or schedule. Past workouts stay in history.'**
  String get workoutArchiveHint;

  /// No description provided for @rpStart.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get rpStart;

  /// No description provided for @rpLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load routine'**
  String get rpLoadError;

  /// No description provided for @rpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This routine is empty'**
  String get rpEmptyTitle;

  /// No description provided for @rpEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Add exercises via Edit'**
  String get rpEmptyMsg;

  /// No description provided for @asPastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Past Workout'**
  String get asPastWorkout;

  /// No description provided for @asEmptyWorkout.
  ///
  /// In en, this message translates to:
  /// **'Empty Workout'**
  String get asEmptyWorkout;

  /// No description provided for @liveSetLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {n}/{total}'**
  String liveSetLabel(int n, int total);

  /// No description provided for @liveAllDone.
  ///
  /// In en, this message translates to:
  /// **'All sets done'**
  String get liveAllDone;

  /// No description provided for @liveRestOver.
  ///
  /// In en, this message translates to:
  /// **'Rest over'**
  String get liveRestOver;

  /// No description provided for @liveNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get liveNext;

  /// No description provided for @liveCompleteSet.
  ///
  /// In en, this message translates to:
  /// **'Complete set'**
  String get liveCompleteSet;

  /// No description provided for @liveAddRest.
  ///
  /// In en, this message translates to:
  /// **'+15 s'**
  String get liveAddRest;

  /// No description provided for @liveSkipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get liveSkipRest;

  /// No description provided for @liveElapsed.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get liveElapsed;

  /// No description provided for @asPastEntry.
  ///
  /// In en, this message translates to:
  /// **'Past entry'**
  String get asPastEntry;

  /// Active session: completed sets out of all sets
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} sets'**
  String asSetProgress(int done, int total);

  /// No description provided for @asFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get asFinish;

  /// No description provided for @asExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave workout?'**
  String get asExitTitle;

  /// No description provided for @asExitMsg.
  ///
  /// In en, this message translates to:
  /// **'Your entered sets won\'t be saved.'**
  String get asExitMsg;

  /// No description provided for @asKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get asKeepGoing;

  /// No description provided for @asLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get asLeave;

  /// No description provided for @asRemoveExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get asRemoveExercise;

  /// No description provided for @asRemoveExerciseMsg.
  ///
  /// In en, this message translates to:
  /// **'{name} and your entered sets will be deleted.'**
  String asRemoveExerciseMsg(String name);

  /// No description provided for @asRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get asRemove;

  /// No description provided for @asNeedOneSet.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one set first'**
  String get asNeedOneSet;

  /// No description provided for @asNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get asNewRecord;

  /// No description provided for @asSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save workout — try again'**
  String get asSaveError;

  /// No description provided for @asStartFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Start by adding exercises from the library'**
  String get asStartFromLibrary;

  /// No description provided for @asAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get asAddSet;

  /// No description provided for @asRemoveSet.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get asRemoveSet;

  /// No description provided for @asHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to do it'**
  String get asHowTo;

  /// No description provided for @asExerciseOptions.
  ///
  /// In en, this message translates to:
  /// **'Exercise options'**
  String get asExerciseOptions;

  /// No description provided for @asSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get asSkip;

  /// No description provided for @hdrSet.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get hdrSet;

  /// No description provided for @hdrPrev.
  ///
  /// In en, this message translates to:
  /// **'PREV'**
  String get hdrPrev;

  /// No description provided for @hdrKg.
  ///
  /// In en, this message translates to:
  /// **'KG'**
  String get hdrKg;

  /// No description provided for @hdrReps.
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get hdrReps;

  /// No description provided for @hdrTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get hdrTime;

  /// No description provided for @hdrDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get hdrDistance;

  /// No description provided for @rpeTitle.
  ///
  /// In en, this message translates to:
  /// **'RPE — Perceived Exertion'**
  String get rpeTitle;

  /// No description provided for @rpeHelp.
  ///
  /// In en, this message translates to:
  /// **'You rate how hard the set felt from 1 to 10. It\'s based on \"how many more reps could you have done?\". Optional — you can leave it empty.'**
  String get rpeHelp;

  /// No description provided for @rpe10.
  ///
  /// In en, this message translates to:
  /// **'Last rep — couldn\'t have done one more'**
  String get rpe10;

  /// No description provided for @rpe9.
  ///
  /// In en, this message translates to:
  /// **'Could have done 1 more rep'**
  String get rpe9;

  /// No description provided for @rpe8.
  ///
  /// In en, this message translates to:
  /// **'2 reps left in reserve'**
  String get rpe8;

  /// No description provided for @rpe7.
  ///
  /// In en, this message translates to:
  /// **'3-4 reps in reserve'**
  String get rpe7;

  /// No description provided for @rpe6.
  ///
  /// In en, this message translates to:
  /// **'Easy / warm-up set'**
  String get rpe6;

  /// No description provided for @rpePick_title.
  ///
  /// In en, this message translates to:
  /// **'Set {set} RPE'**
  String rpePick_title(int set);

  /// No description provided for @rpePick_select.
  ///
  /// In en, this message translates to:
  /// **'Select RPE'**
  String get rpePick_select;

  /// No description provided for @rpePick_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get rpePick_done;

  /// No description provided for @rpePick_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get rpePick_clear;

  /// No description provided for @rpeEffort_light.
  ///
  /// In en, this message translates to:
  /// **'Light effort'**
  String get rpeEffort_light;

  /// No description provided for @rpeEffort_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate effort'**
  String get rpeEffort_moderate;

  /// No description provided for @rpeEffort_vigorous.
  ///
  /// In en, this message translates to:
  /// **'Vigorous effort'**
  String get rpeEffort_vigorous;

  /// No description provided for @rpeEffort_veryHard.
  ///
  /// In en, this message translates to:
  /// **'Very hard effort'**
  String get rpeEffort_veryHard;

  /// No description provided for @rpeEffort_extremelyHard.
  ///
  /// In en, this message translates to:
  /// **'Extremely hard effort'**
  String get rpeEffort_extremelyHard;

  /// No description provided for @rpeEffort_max.
  ///
  /// In en, this message translates to:
  /// **'Max effort'**
  String get rpeEffort_max;

  /// No description provided for @rpeRir_none.
  ///
  /// In en, this message translates to:
  /// **'No more reps possible'**
  String get rpeRir_none;

  /// No description provided for @rpeRir_exact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Could have done 1 more rep} other{Could have done {count} more reps}}'**
  String rpeRir_exact(int count);

  /// No description provided for @rpeRir_range.
  ///
  /// In en, this message translates to:
  /// **'Could have done {min}–{max} more reps'**
  String rpeRir_range(int min, int max);

  /// No description provided for @rpeRir_atLeast.
  ///
  /// In en, this message translates to:
  /// **'Could have done {count}+ more reps'**
  String rpeRir_atLeast(int count);

  /// No description provided for @rbAddWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Add warm-up'**
  String get rbAddWarmUp;

  /// No description provided for @rbAddWarmUpHint.
  ///
  /// In en, this message translates to:
  /// **'Puts a dynamic full-body warm-up at the start'**
  String get rbAddWarmUpHint;

  /// No description provided for @rbWarmUpMissing.
  ///
  /// In en, this message translates to:
  /// **'Warm-up exercise not found in the library'**
  String get rbWarmUpMissing;

  /// No description provided for @rpSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String rpSetCount(int count);

  /// No description provided for @asTimerStart.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get asTimerStart;

  /// No description provided for @asTimerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop timer'**
  String get asTimerStop;

  /// No description provided for @elPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick Exercise'**
  String get elPickTitle;

  /// No description provided for @elSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises…'**
  String get elSearchHint;

  /// No description provided for @elRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get elRecent;

  /// No description provided for @elLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load exercises'**
  String get elLoadError;

  /// No description provided for @elNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get elNotFoundTitle;

  /// No description provided for @elFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Change the filter or add a new exercise'**
  String get elFilterHint;

  /// No description provided for @elNew.
  ///
  /// In en, this message translates to:
  /// **'New Exercise'**
  String get elNew;

  /// No description provided for @elAdded.
  ///
  /// In en, this message translates to:
  /// **'Exercise added'**
  String get elAdded;

  /// No description provided for @elNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise name (e.g. Cable Row)'**
  String get elNameLabel;

  /// No description provided for @elCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get elCategory;

  /// No description provided for @elPrimaryMuscle.
  ///
  /// In en, this message translates to:
  /// **'Primary muscle'**
  String get elPrimaryMuscle;

  /// No description provided for @elEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get elEquipment;

  /// No description provided for @elMeasureType.
  ///
  /// In en, this message translates to:
  /// **'Measurement type'**
  String get elMeasureType;

  /// No description provided for @measureWeightReps.
  ///
  /// In en, this message translates to:
  /// **'weight × reps'**
  String get measureWeightReps;

  /// No description provided for @measureReps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get measureReps;

  /// No description provided for @measureTime.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get measureTime;

  /// No description provided for @measureDistance.
  ///
  /// In en, this message translates to:
  /// **'distance'**
  String get measureDistance;

  /// No description provided for @edFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get edFallbackTitle;

  /// No description provided for @edArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive exercise'**
  String get edArchiveTitle;

  /// No description provided for @edArchiveMsg.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the library? Past records are kept.'**
  String edArchiveMsg(String name);

  /// No description provided for @edTabHow.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get edTabHow;

  /// No description provided for @edTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get edTabHistory;

  /// No description provided for @edTabChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get edTabChart;

  /// No description provided for @edTabRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get edTabRecords;

  /// No description provided for @edMusclesWorked.
  ///
  /// In en, this message translates to:
  /// **'Muscles Worked'**
  String get edMusclesWorked;

  /// No description provided for @edPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get edPrimary;

  /// No description provided for @edSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get edSecondary;

  /// No description provided for @edNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'No instructions'**
  String get edNoInstructions;

  /// No description provided for @edNoInstructionsMsg.
  ///
  /// In en, this message translates to:
  /// **'No step-by-step guide for this exercise'**
  String get edNoInstructionsMsg;

  /// No description provided for @edHowTo.
  ///
  /// In en, this message translates to:
  /// **'How To'**
  String get edHowTo;

  /// No description provided for @edLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get edLevelBeginner;

  /// No description provided for @edLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get edLevelIntermediate;

  /// No description provided for @edLevelExpert.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get edLevelExpert;

  /// No description provided for @edForcePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get edForcePush;

  /// No description provided for @edForcePull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get edForcePull;

  /// No description provided for @edForceStatic.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get edForceStatic;

  /// No description provided for @edLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get edLoadError;

  /// No description provided for @edAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Appears here once you use this exercise in a workout'**
  String get edAppearsHere;

  /// No description provided for @edSetHistory.
  ///
  /// In en, this message translates to:
  /// **'Set history'**
  String get edSetHistory;

  /// No description provided for @edChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for a chart'**
  String get edChartEmpty;

  /// No description provided for @edChartEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Log weight×reps at least twice to see the progress chart'**
  String get edChartEmptyMsg;

  /// No description provided for @edE1rmTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM progress'**
  String get edE1rmTitle;

  /// No description provided for @edEpley.
  ///
  /// In en, this message translates to:
  /// **'Epley: weight × (1 + reps/30)'**
  String get edEpley;

  /// No description provided for @edNoPr.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get edNoPr;

  /// No description provided for @edNoPrMsg.
  ///
  /// In en, this message translates to:
  /// **'Your personal records collect here once you log weight×reps'**
  String get edNoPrMsg;

  /// No description provided for @edBestE1rm.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM'**
  String get edBestE1rm;

  /// No description provided for @edHeaviest.
  ///
  /// In en, this message translates to:
  /// **'Heaviest set'**
  String get edHeaviest;

  /// No description provided for @edTotalLogs.
  ///
  /// In en, this message translates to:
  /// **'Total logged'**
  String get edTotalLogs;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @commonCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get commonCloseApp;

  /// No description provided for @bmAddMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get bmAddMeasurement;

  /// No description provided for @bmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load measurements'**
  String get bmLoadError;

  /// No description provided for @bmEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get bmEmptyTitle;

  /// No description provided for @bmEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Track your progress by adding your first body measurement'**
  String get bmEmptyMsg;

  /// No description provided for @bmAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first measurement'**
  String get bmAddFirst;

  /// No description provided for @bmPastMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Past Measurements'**
  String get bmPastMeasurements;

  /// No description provided for @bmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement'**
  String get bmDeleteTitle;

  /// No description provided for @bmDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete the measurement from {date}?'**
  String bmDeleteMsg(String date);

  /// No description provided for @bmWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend'**
  String get bmWeightTrend;

  /// No description provided for @bmGoalLine.
  ///
  /// In en, this message translates to:
  /// **'Goal {value}'**
  String bmGoalLine(String value);

  /// No description provided for @bmLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest Measurements'**
  String get bmLatest;

  /// No description provided for @bmWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bmWeight;

  /// Caption under the weight change: which measurement the change is compared to
  ///
  /// In en, this message translates to:
  /// **'vs. {date}'**
  String bmDiffSince(String date);

  /// No description provided for @bmWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get bmWaist;

  /// No description provided for @bmArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get bmArm;

  /// No description provided for @bmChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get bmChest;

  /// No description provided for @bmHip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get bmHip;

  /// No description provided for @bmNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get bmNeck;

  /// No description provided for @bmBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get bmBodyFat;

  /// No description provided for @bmNeedOneValue.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one value'**
  String get bmNeedOneValue;

  /// No description provided for @bmSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save — try again'**
  String get bmSaveFailed;

  /// No description provided for @bmNewMeasurement.
  ///
  /// In en, this message translates to:
  /// **'New Measurement'**
  String get bmNewMeasurement;

  /// No description provided for @bmSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Empty fields aren\'t saved'**
  String get bmSheetSubtitle;

  /// No description provided for @actTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get actTitle;

  /// No description provided for @actLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load calendar'**
  String get actLoadError;

  /// No description provided for @actNoEntry.
  ///
  /// In en, this message translates to:
  /// **'No entries for this day.'**
  String get actNoEntry;

  /// No description provided for @exTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exTitle;

  /// No description provided for @exNoData.
  ///
  /// In en, this message translates to:
  /// **'No data to export in the selected range'**
  String get exNoData;

  /// No description provided for @exShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed, try again'**
  String get exShareFailed;

  /// No description provided for @exHeadline.
  ///
  /// In en, this message translates to:
  /// **'Export your data, analyze it with AI'**
  String get exHeadline;

  /// No description provided for @exFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exFormat;

  /// No description provided for @exDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get exDateRange;

  /// No description provided for @exWeek.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get exWeek;

  /// No description provided for @exMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get exMonth;

  /// No description provided for @exAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exAll;

  /// No description provided for @exScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get exScope;

  /// No description provided for @exScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exScopeAll;

  /// No description provided for @exPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get exPreparing;

  /// No description provided for @exShareBtn.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get exShareBtn;

  /// No description provided for @cloudSignupOk.
  ///
  /// In en, this message translates to:
  /// **'Registered. Verify your email, then sign in.'**
  String get cloudSignupOk;

  /// No description provided for @cloudConnErr.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect: {err}'**
  String cloudConnErr(String err);

  /// No description provided for @cloudSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get cloudSignIn;

  /// No description provided for @cloudCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get cloudCreateAccount;

  /// No description provided for @cloudIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in — your workouts, meals and measurements are saved to your account automatically.'**
  String get cloudIntro;

  /// No description provided for @cloudEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cloudEmail;

  /// No description provided for @cloudPassword.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6 characters)'**
  String get cloudPassword;

  /// No description provided for @cloudSignInBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get cloudSignInBtn;

  /// No description provided for @cloudSignUpBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get cloudSignUpBtn;

  /// No description provided for @cloudGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get cloudGoogle;

  /// No description provided for @cloudOrEmail.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get cloudOrEmail;

  /// No description provided for @cloudForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get cloudForgot;

  /// No description provided for @cloudForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get cloudForgotTitle;

  /// No description provided for @cloudForgotMsg.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to set a new password. Open it on this device.'**
  String get cloudForgotMsg;

  /// No description provided for @cloudForgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get cloudForgotSend;

  /// No description provided for @cloudForgotSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that address, a reset link is on its way.'**
  String get cloudForgotSent;

  /// No description provided for @cloudResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get cloudResetTitle;

  /// No description provided for @cloudResetIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account. You\'ll be signed in right after.'**
  String get cloudResetIntro;

  /// No description provided for @cloudResetNew.
  ///
  /// In en, this message translates to:
  /// **'New password (min 6 characters)'**
  String get cloudResetNew;

  /// No description provided for @cloudResetRepeat.
  ///
  /// In en, this message translates to:
  /// **'New password (again)'**
  String get cloudResetRepeat;

  /// No description provided for @cloudResetMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get cloudResetMismatch;

  /// No description provided for @cloudResetSave.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get cloudResetSave;

  /// No description provided for @cloudResetOk.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get cloudResetOk;

  /// No description provided for @cloudResetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel and sign out'**
  String get cloudResetCancel;

  /// No description provided for @cloudNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get cloudNoAccount;

  /// No description provided for @cloudHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get cloudHaveAccount;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Your data is safe on this device and will sync once you update.'**
  String get updateRequiredBody;

  /// No description provided for @updateRequiredAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateRequiredAction;

  /// No description provided for @cloudSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get cloudSignOut;

  /// No description provided for @cloudSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get cloudSyncNow;

  /// No description provided for @cloudSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get cloudSyncDone;

  /// No description provided for @cloudSyncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} records are still waiting — check your connection'**
  String cloudSyncPending(int count);

  /// No description provided for @cloudSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync — your data is safe on this device'**
  String get cloudSyncFailed;

  /// No description provided for @cloudDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get cloudDeleteAccount;

  /// No description provided for @cloudDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your account and the data stored in the cloud.'**
  String get cloudDeleteHint;

  /// No description provided for @cloudDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get cloudDeleteTitle;

  /// No description provided for @cloudDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Your cloud account and cloud backup will be permanently deleted. Data on this device is not affected.'**
  String get cloudDeleteMsg;

  /// No description provided for @cloudDeleteConfirm2Title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get cloudDeleteConfirm2Title;

  /// No description provided for @cloudDeleteConfirm2Msg.
  ///
  /// In en, this message translates to:
  /// **'This is the last step — your account can\'t be recovered afterwards.'**
  String get cloudDeleteConfirm2Msg;

  /// No description provided for @cloudDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get cloudDeleted;

  /// No description provided for @cloudDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete account: {error}'**
  String cloudDeleteFailed(String error);

  /// No description provided for @unitPortion.
  ///
  /// In en, this message translates to:
  /// **'portion'**
  String get unitPortion;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get unitPiece;

  /// No description provided for @unitSlice.
  ///
  /// In en, this message translates to:
  /// **'slice'**
  String get unitSlice;

  /// No description provided for @unitBowl.
  ///
  /// In en, this message translates to:
  /// **'bowl'**
  String get unitBowl;

  /// No description provided for @unitWaterGlass.
  ///
  /// In en, this message translates to:
  /// **'glass'**
  String get unitWaterGlass;

  /// No description provided for @unitCup.
  ///
  /// In en, this message translates to:
  /// **'cup'**
  String get unitCup;

  /// No description provided for @unitTablespoon.
  ///
  /// In en, this message translates to:
  /// **'tablespoon'**
  String get unitTablespoon;

  /// No description provided for @unitHandful.
  ///
  /// In en, this message translates to:
  /// **'handful'**
  String get unitHandful;

  /// No description provided for @unitClove.
  ///
  /// In en, this message translates to:
  /// **'clove'**
  String get unitClove;

  /// No description provided for @unitScoop.
  ///
  /// In en, this message translates to:
  /// **'scoop'**
  String get unitScoop;

  /// No description provided for @unitCan.
  ///
  /// In en, this message translates to:
  /// **'can'**
  String get unitCan;

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

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get settingsSectionNutrition;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity & Energy'**
  String get profileSectionIdentity;

  /// No description provided for @profileMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get profileMeasurements;

  /// No description provided for @profileMeasurementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weight, waist, arm — tap to log'**
  String get profileMeasurementsSubtitle;

  /// No description provided for @homeProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileTooltip;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-Source Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsAttribution.
  ///
  /// In en, this message translates to:
  /// **'Open Data Sources'**
  String get settingsAttribution;

  /// No description provided for @settingsAttributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise & food databases the app builds on'**
  String get settingsAttributionSubtitle;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem or share an idea'**
  String get settingsFeedbackSubtitle;

  /// No description provided for @settingsWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Week Starts On'**
  String get settingsWeekStart;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rest timer, workout & water reminders'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @notifRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest timer alert'**
  String get notifRestTimer;

  /// No description provided for @notifRestTimerSub.
  ///
  /// In en, this message translates to:
  /// **'Notifies when rest ends while the app is in the background'**
  String get notifRestTimerSub;

  /// No description provided for @notifRestSound.
  ///
  /// In en, this message translates to:
  /// **'Rest timer sound'**
  String get notifRestSound;

  /// No description provided for @notifRestSoundSub.
  ///
  /// In en, this message translates to:
  /// **'Beeps for the last 3 seconds and when rest ends. Uses media volume and plays over your music.'**
  String get notifRestSoundSub;

  /// No description provided for @restSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest sound'**
  String get restSoundTitle;

  /// No description provided for @restSoundSheetSub.
  ///
  /// In en, this message translates to:
  /// **'Plays in the last 3 seconds and when rest ends. Tap to choose and listen.'**
  String get restSoundSheetSub;

  /// No description provided for @restSoundPreview.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get restSoundPreview;

  /// No description provided for @restSoundDigitalBeep.
  ///
  /// In en, this message translates to:
  /// **'Digital beep'**
  String get restSoundDigitalBeep;

  /// No description provided for @restSoundDigitalBeepHint.
  ///
  /// In en, this message translates to:
  /// **'Short beeps, one long start tone'**
  String get restSoundDigitalBeepHint;

  /// No description provided for @restSoundClassicBell.
  ///
  /// In en, this message translates to:
  /// **'Classic bell'**
  String get restSoundClassicBell;

  /// No description provided for @restSoundClassicBellHint.
  ///
  /// In en, this message translates to:
  /// **'A single clear bell strike'**
  String get restSoundClassicBellHint;

  /// No description provided for @restSoundBoxingBell.
  ///
  /// In en, this message translates to:
  /// **'Boxing bell'**
  String get restSoundBoxingBell;

  /// No description provided for @restSoundBoxingBellHint.
  ///
  /// In en, this message translates to:
  /// **'Ring bell: ding-ding-ding'**
  String get restSoundBoxingBellHint;

  /// No description provided for @restSoundSoftChime.
  ///
  /// In en, this message translates to:
  /// **'Soft chime'**
  String get restSoundSoftChime;

  /// No description provided for @restSoundSoftChimeHint.
  ///
  /// In en, this message translates to:
  /// **'Gentle, quiet chord'**
  String get restSoundSoftChimeHint;

  /// No description provided for @restSoundStrongAlert.
  ///
  /// In en, this message translates to:
  /// **'Strong alert'**
  String get restSoundStrongAlert;

  /// No description provided for @restSoundStrongAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Loud two-tone alarm for noisy gyms'**
  String get restSoundStrongAlertHint;

  /// No description provided for @notifIosSoundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound is off for Fit Pack notifications'**
  String get notifIosSoundOff;

  /// No description provided for @notifIosSoundOffSub.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in iPhone Settings › Notifications › Fit Pack › Sounds.'**
  String get notifIosSoundOffSub;

  /// No description provided for @notifRestIosNote.
  ///
  /// In en, this message translates to:
  /// **'When the app is in the background, iPhone plays the rest alert as a notification: it is silent when the phone is on silent mode or a Focus filters it. With the app open, the sound always plays.'**
  String get notifRestIosNote;

  /// No description provided for @notifWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout reminder'**
  String get notifWorkout;

  /// No description provided for @notifWater.
  ///
  /// In en, this message translates to:
  /// **'Daily water reminder'**
  String get notifWater;

  /// No description provided for @notifTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notifTime;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied — enable it in system settings.'**
  String get notifPermissionDenied;

  /// No description provided for @notifRestDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest over'**
  String get notifRestDoneTitle;

  /// No description provided for @notifRestDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Time for the next set'**
  String get notifRestDoneBody;

  /// No description provided for @notifRestEndingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest ends in 3 seconds'**
  String get notifRestEndingTitle;

  /// No description provided for @notifRestEndingBody.
  ///
  /// In en, this message translates to:
  /// **'Get ready for the next set'**
  String get notifRestEndingBody;

  /// No description provided for @notifWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout time'**
  String get notifWorkoutTitle;

  /// No description provided for @notifWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan is waiting — a short session counts too.'**
  String get notifWorkoutBody;

  /// No description provided for @notifWorkoutSub.
  ///
  /// In en, this message translates to:
  /// **'If you take a 2-day break, reminds you of your next workout at your usual time.'**
  String get notifWorkoutSub;

  /// No description provided for @notifWorkoutFallbackTime.
  ///
  /// In en, this message translates to:
  /// **'Default time'**
  String get notifWorkoutFallbackTime;

  /// No description provided for @notifWorkoutFallbackTimeSub.
  ///
  /// In en, this message translates to:
  /// **'The time comes from your workout history; this one is used until there is history.'**
  String get notifWorkoutFallbackTimeSub;

  /// No description provided for @notifRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next workout is ready'**
  String get notifRecallTitle;

  /// No description provided for @notifRecallTitle2.
  ///
  /// In en, this message translates to:
  /// **'A short session counts too'**
  String get notifRecallTitle2;

  /// No description provided for @notifRecallTitle3.
  ///
  /// In en, this message translates to:
  /// **'Is today a good day?'**
  String get notifRecallTitle3;

  /// No description provided for @notifRecallBodyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Up next: {routine} · ~{minutes} min'**
  String notifRecallBodyRoutine(String routine, int minutes);

  /// No description provided for @notifRecallBodyRoutineOnly.
  ///
  /// In en, this message translates to:
  /// **'Up next: {routine}'**
  String notifRecallBodyRoutineOnly(String routine);

  /// No description provided for @notifRecallBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a routine or start an empty workout — a few sets do the job.'**
  String get notifRecallBody;

  /// No description provided for @notifMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Today was {routine} day'**
  String notifMissedTitle(String routine);

  /// No description provided for @notifMissedBody.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow works too. If you have time, a short session now still counts.'**
  String get notifMissedBody;

  /// No description provided for @notifFirstWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for your first workout?'**
  String get notifFirstWeekTitle;

  /// No description provided for @notifFirstWeekBodyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Your first workout is ready: {routine} · ~{minutes} min'**
  String notifFirstWeekBodyRoutine(String routine, int minutes);

  /// No description provided for @notifFirstWeekBodyRoutineOnly.
  ///
  /// In en, this message translates to:
  /// **'Your first workout is ready: {routine}'**
  String notifFirstWeekBodyRoutineOnly(String routine);

  /// No description provided for @notifFirstWeekBody.
  ///
  /// In en, this message translates to:
  /// **'Pick one of the ready-made programs or start an empty workout.'**
  String get notifFirstWeekBody;

  /// No description provided for @recallOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Want a reminder for your next workout?'**
  String get recallOfferTitle;

  /// No description provided for @recallOfferBody.
  ///
  /// In en, this message translates to:
  /// **'If you take a 2-day break or miss a planned day, I\'ll remind you around your usual time (at most 2 a day). Turn it off in Settings → Notifications.'**
  String get recallOfferBody;

  /// No description provided for @recallOfferOnbTitle.
  ///
  /// In en, this message translates to:
  /// **'Want reminders for your workouts?'**
  String get recallOfferOnbTitle;

  /// No description provided for @recallOfferOnbBody.
  ///
  /// In en, this message translates to:
  /// **'I\'ll remind you of your first workout, and of the next one if you take a 2-day break (at most 2 a day). Turn it off in Settings → Notifications.'**
  String get recallOfferOnbBody;

  /// No description provided for @recallOfferYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, remind me'**
  String get recallOfferYes;

  /// No description provided for @recallOfferNo.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get recallOfferNo;

  /// No description provided for @recallOfferEnabled.
  ///
  /// In en, this message translates to:
  /// **'Done — I\'ll remind you after a 2-day break.'**
  String get recallOfferEnabled;

  /// No description provided for @notifWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water break'**
  String get notifWaterTitle;

  /// No description provided for @notifWaterBody.
  ///
  /// In en, this message translates to:
  /// **'A glass of water now keeps your ring on track.'**
  String get notifWaterBody;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, cm)'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lb, ft)'**
  String get unitsImperial;

  /// No description provided for @attribIntro.
  ///
  /// In en, this message translates to:
  /// **'Fit Pack is built on these open datasets and libraries. Thank you to their maintainers!'**
  String get attribIntro;

  /// No description provided for @attribOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Packaged food nutrition data (barcode & text search)'**
  String get attribOffDesc;

  /// No description provided for @attribFedDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise library, instructions and demo photos'**
  String get attribFedDesc;

  /// No description provided for @attribMuscleDesc.
  ///
  /// In en, this message translates to:
  /// **'Body muscle map visual'**
  String get attribMuscleDesc;

  /// No description provided for @attribLicense.
  ///
  /// In en, this message translates to:
  /// **'License: {name}'**
  String attribLicense(String name);

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

  /// No description provided for @settingsCloudAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsCloudAccount;

  /// No description provided for @settingsCloudSignedIn.
  ///
  /// In en, this message translates to:
  /// **'{email}'**
  String settingsCloudSignedIn(String email);

  /// No description provided for @settingsCloudSignedInFallback.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsCloudSignedInFallback;

  /// No description provided for @settingsCloudSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your data to your account'**
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
  /// **'Your weight is enough for a goal suggestion. You can add height, gender and age later in Profile.'**
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
  /// **'Your plan is ready'**
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
  /// **'At this pace, you could reach {goal} in roughly {weeks} weeks.'**
  String onbProjectionCut(String goal, int weeks);

  /// No description provided for @onbProjectionBulk.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you could build up to {goal} in roughly {weeks} weeks.'**
  String onbProjectionBulk(String goal, int weeks);

  /// No description provided for @onbProjectionNote.
  ///
  /// In en, this message translates to:
  /// **'An estimate — real progress varies from person to person.'**
  String get onbProjectionNote;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get onbStart;

  /// No description provided for @onbTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your training'**
  String get onbTrainingTitle;

  /// No description provided for @onbTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two questions — let\'s start you on a program that fits.'**
  String get onbTrainingSubtitle;

  /// No description provided for @onbExperienceQ.
  ///
  /// In en, this message translates to:
  /// **'How long have you been training?'**
  String get onbExperienceQ;

  /// No description provided for @onbExpBeginner.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get onbExpBeginner;

  /// No description provided for @onbExpSome.
  ///
  /// In en, this message translates to:
  /// **'For a while'**
  String get onbExpSome;

  /// No description provided for @onbExpLong.
  ///
  /// In en, this message translates to:
  /// **'For a long time'**
  String get onbExpLong;

  /// No description provided for @onbDaysQ.
  ///
  /// In en, this message translates to:
  /// **'How many days a week do you want to train?'**
  String get onbDaysQ;

  /// No description provided for @onbDays23.
  ///
  /// In en, this message translates to:
  /// **'2–3 days'**
  String get onbDays23;

  /// No description provided for @onbDays4.
  ///
  /// In en, this message translates to:
  /// **'4 days'**
  String get onbDays4;

  /// No description provided for @onbDays56.
  ///
  /// In en, this message translates to:
  /// **'5–6 days'**
  String get onbDays56;

  /// No description provided for @onbProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Our pick for you'**
  String get onbProgramTitle;

  /// No description provided for @onbProgramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen from your answers. The routines are added to your account — change them however you like.'**
  String get onbProgramSubtitle;

  /// No description provided for @onbProgramRestNote.
  ///
  /// In en, this message translates to:
  /// **'Rest days speed up progress when you\'re starting out — so we suggest 4 days a week.'**
  String get onbProgramRestNote;

  /// No description provided for @onbProgramUse.
  ///
  /// In en, this message translates to:
  /// **'Start with this program'**
  String get onbProgramUse;

  /// No description provided for @onbProgramSkip.
  ///
  /// In en, this message translates to:
  /// **'I\'ll build my own'**
  String get onbProgramSkip;

  /// No description provided for @onbProgramSkipDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up your routine later in the Workout tab; ready-made programs are in Explore.'**
  String get onbProgramSkipDesc;

  /// No description provided for @onbProgramInstallError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the program — you can add it from Workout → Explore.'**
  String get onbProgramInstallError;

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
  /// **'Start with a ready-made program, or build your own routine.'**
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

  /// No description provided for @workoutRoutineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String workoutRoutineCount(int count);

  /// No description provided for @backupErrorInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Not a valid Fit Pack backup.'**
  String get backupErrorInvalidFile;

  /// No description provided for @backupErrorNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer version of Fit Pack. Update the app first.'**
  String get backupErrorNewerVersion;

  /// No description provided for @backupErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in first.'**
  String get backupErrorSignIn;

  /// No description provided for @exportRptRange.
  ///
  /// In en, this message translates to:
  /// **'Range: {start} → {end}'**
  String exportRptRange(String start, String end);

  /// No description provided for @exportRptGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {ts}'**
  String exportRptGenerated(String ts);

  /// No description provided for @exportRptProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get exportRptProfile;

  /// No description provided for @exportRptPhaseWeek.
  ///
  /// In en, this message translates to:
  /// **'Phase: {phase}, Week: {week}'**
  String exportRptPhaseWeek(int phase, int week);

  /// No description provided for @exportRptCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Calorie goal: {kcal} kcal'**
  String exportRptCalorieGoal(int kcal);

  /// No description provided for @exportRptProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein goal: {g} g'**
  String exportRptProteinGoal(int g);

  /// No description provided for @exportRptHeight.
  ///
  /// In en, this message translates to:
  /// **'Height: {cm} cm'**
  String exportRptHeight(String cm);

  /// No description provided for @exportRptGoalWeight.
  ///
  /// In en, this message translates to:
  /// **'Goal weight: {kg} kg'**
  String exportRptGoalWeight(String kg);

  /// No description provided for @exportRptWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workouts ({count} sessions)'**
  String exportRptWorkoutsTitle(int count);

  /// No description provided for @exportRptNoWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts in this range.'**
  String get exportRptNoWorkouts;

  /// No description provided for @exportRptDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {min} min'**
  String exportRptDuration(int min);

  /// No description provided for @exportRptNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String exportRptNote(String note);

  /// No description provided for @exportRptWorkoutTable.
  ///
  /// In en, this message translates to:
  /// **'| Exercise | Set | Kg | Reps | RPE | Duration | Distance | Type |'**
  String get exportRptWorkoutTable;

  /// No description provided for @exportRptSetWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get exportRptSetWarmup;

  /// No description provided for @exportRptSetDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get exportRptSetDrop;

  /// No description provided for @exportRptSetFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get exportRptSetFail;

  /// No description provided for @exportRptRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines ({count})'**
  String exportRptRoutinesTitle(int count);

  /// No description provided for @exportRptNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition ({count} entries)'**
  String exportRptNutritionTitle(int count);

  /// No description provided for @exportRptNoNutrition.
  ///
  /// In en, this message translates to:
  /// **'No nutrition entries in this range.'**
  String get exportRptNoNutrition;

  /// No description provided for @exportRptDayTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {kcal} kcal · P {p}g · C {c}g · F {f}g'**
  String exportRptDayTotal(String kcal, String p, String c, String f);

  /// No description provided for @exportRptNutritionTable.
  ///
  /// In en, this message translates to:
  /// **'| Meal | Food | Grams | Kcal | Protein |'**
  String get exportRptNutritionTable;

  /// No description provided for @exportRptWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water ({count} days)'**
  String exportRptWaterTitle(int count);

  /// No description provided for @exportRptWaterTable.
  ///
  /// In en, this message translates to:
  /// **'| Date | ml |'**
  String get exportRptWaterTable;

  /// No description provided for @exportRptBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Body measurements ({count} entries)'**
  String exportRptBodyTitle(int count);

  /// No description provided for @exportRptNoBody.
  ///
  /// In en, this message translates to:
  /// **'No measurements in this range.'**
  String get exportRptNoBody;

  /// No description provided for @exportRptBodyTable.
  ///
  /// In en, this message translates to:
  /// **'| Date | Weight | Waist | Chest | Arm | Hip | Neck | BF% |'**
  String get exportRptBodyTable;

  /// Welcome (gate) screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Fit Pack'**
  String get authWelcomeTitle;

  /// Welcome (gate) screen tagline
  ///
  /// In en, this message translates to:
  /// **'Your workouts, nutrition and progress — all in one place.'**
  String get authWelcomeTagline;

  /// Welcome screen value bullet — workout
  ///
  /// In en, this message translates to:
  /// **'Build routines and log every set'**
  String get authValueWorkout;

  /// Welcome screen value bullet — nutrition
  ///
  /// In en, this message translates to:
  /// **'Track calories and protein day by day'**
  String get authValueNutrition;

  /// Welcome screen value bullet — progress
  ///
  /// In en, this message translates to:
  /// **'Watch weight and measurements move in charts'**
  String get authValueProgress;

  /// Welcome screen note explaining why an account is required
  ///
  /// In en, this message translates to:
  /// **'Your data is stored in your account — it stays with you when you change phones.'**
  String get authWhyAccount;

  /// Auth gate intro shown in sign-up mode
  ///
  /// In en, this message translates to:
  /// **'Create an account — your workouts, meals and measurements are saved to it automatically.'**
  String get cloudIntroSignUp;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Your data is up to date'**
  String get syncUpToDate;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// No description provided for @syncPendingOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved — {count} record(s) will upload when you\'re back online'**
  String syncPendingOffline(int count);

  /// No description provided for @syncPendingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Saved — {count} record(s) waiting to upload'**
  String syncPendingWaiting(int count);

  /// No description provided for @signOutPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Records not yet uploaded'**
  String get signOutPendingTitle;

  /// No description provided for @signOutPendingMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s) haven\'t been uploaded to the server yet. If you sign out now, they won\'t upload until your next sign-in.'**
  String signOutPendingMsg(int count);

  /// No description provided for @signOutSyncFirst.
  ///
  /// In en, this message translates to:
  /// **'Sync first'**
  String get signOutSyncFirst;

  /// No description provided for @signOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get signOutAnyway;

  /// No description provided for @signOutStillPending.
  ///
  /// In en, this message translates to:
  /// **'Still uploading — try again in a moment'**
  String get signOutStillPending;

  /// No description provided for @settingsWeightIncrement.
  ///
  /// In en, this message translates to:
  /// **'Weight increment'**
  String get settingsWeightIncrement;

  /// No description provided for @progIncrease.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets} — every set reached {max}. Ready? Try +{inc}.'**
  String progIncrease(String sets, int max, String inc);

  /// No description provided for @progAddRep.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets} (range {min}–{max}). Try one more rep per set.'**
  String progAddRep(String sets, int min, int max);

  /// No description provided for @progRepeat.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets} — some sets under {min}. Repeat the same weights.'**
  String progRepeat(String sets, int min);

  /// No description provided for @progApplyWeight.
  ///
  /// In en, this message translates to:
  /// **'+{inc}'**
  String progApplyWeight(String inc);

  /// No description provided for @progApplyReps.
  ///
  /// In en, this message translates to:
  /// **'+1 rep'**
  String get progApplyReps;

  /// No description provided for @progAppliedWeight.
  ///
  /// In en, this message translates to:
  /// **'Applied: +{inc} per set, {reps} reps'**
  String progAppliedWeight(String inc, int reps);

  /// No description provided for @progAppliedReps.
  ///
  /// In en, this message translates to:
  /// **'Applied: +1 rep per set'**
  String get progAppliedReps;

  /// No description provided for @progInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How the target works'**
  String get progInfoTitle;

  /// No description provided for @progInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Double progression: keep the weight and add reps until every set reaches the top of your range ({min}–{max}). Then add weight (+{inc}) and start again at {min} reps. Nothing changes unless you tap the button — your routine stays the same and suggested sets are never marked done.'**
  String progInfoBody(int min, int max, String inc);

  /// No description provided for @progInfoSettings.
  ///
  /// In en, this message translates to:
  /// **'Change the increment in Settings → Weight increment.'**
  String get progInfoSettings;

  /// No description provided for @progIncreaseHard.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets} — every set reached {max}, but the hardest was RPE {rpe}. Try +{inc}; reps may drop in the first set.'**
  String progIncreaseHard(String sets, int max, String inc, String rpe);

  /// No description provided for @progHoldFailure.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets} — at least one set was to failure (RPE 10). Repeat the same target before adding reps.'**
  String progHoldFailure(String sets);

  /// No description provided for @progDecrease.
  ///
  /// In en, this message translates to:
  /// **'Stuck below {min} reps two sessions in a row, last one to failure. Drop −{inc} and build back from {min} reps.'**
  String progDecrease(String sets, int min, String inc);

  /// No description provided for @progApplyDecrease.
  ///
  /// In en, this message translates to:
  /// **'−{inc}'**
  String progApplyDecrease(String inc);

  /// No description provided for @progAppliedDecrease.
  ///
  /// In en, this message translates to:
  /// **'Applied: −{inc} per set, {reps} reps'**
  String progAppliedDecrease(String inc, int reps);

  /// No description provided for @progInfoRpe.
  ///
  /// In en, this message translates to:
  /// **'RPE also counts: if a set was to failure (RPE 10) you won\'t be pushed for an extra rep; stuck two sessions in a row suggests dropping one step.'**
  String get progInfoRpe;

  /// Account screen: when data last reached the server.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {when}'**
  String syncLastBackup(String when);

  /// No description provided for @syncWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String syncWhenToday(String time);

  /// No description provided for @syncWhenYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday {time}'**
  String syncWhenYesterday(String time);

  /// Shown after 3+ days without reaching the server.
  ///
  /// In en, this message translates to:
  /// **'Not backed up for {days} days. Your data is safe on this phone.'**
  String syncLongOutage(int days);

  /// No description provided for @syncReplacedRows.
  ///
  /// In en, this message translates to:
  /// **'{count} records were replaced by a newer version from the cloud'**
  String syncReplacedRows(int count);

  /// Rows removed from the upload queue after a permanent server error.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s) couldn\'t upload — tap to retry'**
  String syncFailedRows(int count);

  /// No description provided for @wrTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get wrTitle;

  /// No description provided for @wrInProgress.
  ///
  /// In en, this message translates to:
  /// **'Week in progress — based on {days} day(s)'**
  String wrInProgress(int days);

  /// No description provided for @wrPrevWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get wrPrevWeek;

  /// No description provided for @wrNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get wrNextWeek;

  /// No description provided for @wrSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get wrSummaryTitle;

  /// No description provided for @wrFactWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count} workout(s)'**
  String wrFactWorkouts(int count);

  /// No description provided for @wrFactFoodDays.
  ///
  /// In en, this message translates to:
  /// **'food logged on {days} day(s)'**
  String wrFactFoodDays(int days);

  /// No description provided for @wrFactNoFood.
  ///
  /// In en, this message translates to:
  /// **'no food logged'**
  String get wrFactNoFood;

  /// No description provided for @wrFactWeightDelta.
  ///
  /// In en, this message translates to:
  /// **'weight {delta}'**
  String wrFactWeightDelta(String delta);

  /// No description provided for @wrFactNoPrevWeight.
  ///
  /// In en, this message translates to:
  /// **'no weigh-in last week to compare'**
  String get wrFactNoPrevWeight;

  /// No description provided for @wrFactNoWeight.
  ///
  /// In en, this message translates to:
  /// **'no weigh-in'**
  String get wrFactNoWeight;

  /// No description provided for @wrWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get wrWorkoutTitle;

  /// No description provided for @wrWorkoutPlanned.
  ///
  /// In en, this message translates to:
  /// **'{done}/{planned} planned workouts'**
  String wrWorkoutPlanned(int done, int planned);

  /// No description provided for @wrWorkoutDone.
  ///
  /// In en, this message translates to:
  /// **'{count} workout(s)'**
  String wrWorkoutDone(int count);

  /// No description provided for @wrWorkoutDetail.
  ///
  /// In en, this message translates to:
  /// **'{sets} completed sets · {minutes} min · {volume} volume'**
  String wrWorkoutDetail(int sets, int minutes, String volume);

  /// No description provided for @wrWorkoutPrev.
  ///
  /// In en, this message translates to:
  /// **'Last week: {count} workout(s)'**
  String wrWorkoutPrev(int count);

  /// No description provided for @wrWorkoutNone.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged this week'**
  String get wrWorkoutNone;

  /// No description provided for @wrWorkoutSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {count} session(s). Volume and session count use the same calculation as Home.'**
  String wrWorkoutSource(int count);

  /// No description provided for @wrProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise progress'**
  String get wrProgressTitle;

  /// No description provided for @wrProgressRow.
  ///
  /// In en, this message translates to:
  /// **'{weight} × {reps} — est. 1RM +{delta}'**
  String wrProgressRow(String weight, int reps, String delta);

  /// No description provided for @wrProgressNone.
  ///
  /// In en, this message translates to:
  /// **'No earlier record to compare, or no progress'**
  String get wrProgressNone;

  /// No description provided for @wrProgressSource.
  ///
  /// In en, this message translates to:
  /// **'Source: this week\'s best completed set vs. the exercise\'s previous record (Epley 1RM). Exercises are listed separately; no overall score.'**
  String get wrProgressSource;

  /// No description provided for @wrNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get wrNutritionTitle;

  /// No description provided for @wrNutritionLogged.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) logged'**
  String wrNutritionLogged(int days);

  /// No description provided for @wrNutritionAvg.
  ///
  /// In en, this message translates to:
  /// **'Average of logged days: {kcal} kcal · {protein} g protein'**
  String wrNutritionAvg(int kcal, int protein);

  /// No description provided for @wrNutritionGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {kcal} kcal · {protein} g protein'**
  String wrNutritionGoal(int kcal, int protein);

  /// No description provided for @wrNutritionNone.
  ///
  /// In en, this message translates to:
  /// **'No food logged this week'**
  String get wrNutritionNone;

  /// No description provided for @wrNutritionSource.
  ///
  /// In en, this message translates to:
  /// **'Source: logged days only. Unlogged days don\'t count as 0 and aren\'t judged against your goal.'**
  String get wrNutritionSource;

  /// No description provided for @wrWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get wrWeightTitle;

  /// No description provided for @wrWeightAvg.
  ///
  /// In en, this message translates to:
  /// **'Weekly average: {weight} ({count} weigh-in(s))'**
  String wrWeightAvg(String weight, int count);

  /// No description provided for @wrWeightDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs. last week'**
  String wrWeightDelta(String delta);

  /// No description provided for @wrWeightSingle.
  ///
  /// In en, this message translates to:
  /// **'Single weigh-in — not a trend'**
  String get wrWeightSingle;

  /// No description provided for @wrWeightNoPrev.
  ///
  /// In en, this message translates to:
  /// **'No weigh-in last week — can\'t compare'**
  String get wrWeightNoPrev;

  /// No description provided for @wrWeightNone.
  ///
  /// In en, this message translates to:
  /// **'No weigh-in this week'**
  String get wrWeightNone;

  /// No description provided for @wrMeaningOnTrack.
  ///
  /// In en, this message translates to:
  /// **'In line with your goal'**
  String get wrMeaningOnTrack;

  /// No description provided for @wrMeaningAgainst.
  ///
  /// In en, this message translates to:
  /// **'Against your goal — one week alone isn\'t a verdict'**
  String get wrMeaningAgainst;

  /// No description provided for @wrMeaningFlat.
  ///
  /// In en, this message translates to:
  /// **'No clear change'**
  String get wrMeaningFlat;

  /// No description provided for @wrDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your weight goal'**
  String get wrDirectionLabel;

  /// No description provided for @wrDirLose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get wrDirLose;

  /// No description provided for @wrDirMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get wrDirMaintain;

  /// No description provided for @wrDirGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get wrDirGain;

  /// No description provided for @wrDirectionUnset.
  ///
  /// In en, this message translates to:
  /// **'Pick a direction and weight changes are read against it. It won\'t be applied to past weeks.'**
  String get wrDirectionUnset;

  /// No description provided for @wrGoalConflict.
  ///
  /// In en, this message translates to:
  /// **'The direction you picked doesn\'t match your goal weight. Nothing was changed — you can check it in Profile.'**
  String get wrGoalConflict;

  /// No description provided for @wrGoalConflictAction.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get wrGoalConflictAction;

  /// No description provided for @wrWeightSource.
  ///
  /// In en, this message translates to:
  /// **'Source: weekly averages. The direction only applies to weeks after you picked it.'**
  String get wrWeightSource;

  /// No description provided for @wrMuscleTitle.
  ///
  /// In en, this message translates to:
  /// **'Muscle group split'**
  String get wrMuscleTitle;

  /// No description provided for @wrMuscleRow.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets'**
  String wrMuscleRow(int sets);

  /// No description provided for @wrMuscleNone.
  ///
  /// In en, this message translates to:
  /// **'No completed sets this week'**
  String get wrMuscleNone;

  /// No description provided for @wrMuscleSource.
  ///
  /// In en, this message translates to:
  /// **'Source: completed, non-warm-up sets; the exercise\'s primary muscle. Counts only.'**
  String get wrMuscleSource;

  /// No description provided for @wrFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get wrFocusTitle;

  /// No description provided for @wrFocusCompletePlan.
  ///
  /// In en, this message translates to:
  /// **'You completed {done} of {planned} planned workouts — the goal is to finish the plan.'**
  String wrFocusCompletePlan(int done, int planned);

  /// No description provided for @wrFocusIncrease.
  ///
  /// In en, this message translates to:
  /// **'{name} has been at the same weight for 3 weeks, above your rep range — try adding weight.'**
  String wrFocusIncrease(String name);

  /// No description provided for @wrFocusLogging.
  ///
  /// In en, this message translates to:
  /// **'Food logged on {days} day(s) — aim for a short entry every day.'**
  String wrFocusLogging(int days);

  /// No description provided for @wrFocusCalories.
  ///
  /// In en, this message translates to:
  /// **'Weight has moved against your goal for 2 weeks — consider reviewing your calorie goal.'**
  String get wrFocusCalories;

  /// No description provided for @wrFocusKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep the same rhythm.'**
  String get wrFocusKeep;

  /// No description provided for @wrFocusSource.
  ///
  /// In en, this message translates to:
  /// **'Rule: the first matching suggestion is shown. It\'s a suggestion; your goals don\'t change.'**
  String get wrFocusSource;

  /// No description provided for @wrOpen.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get wrOpen;

  /// No description provided for @notifWeeklyReview.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get notifWeeklyReview;

  /// No description provided for @notifWeeklyReviewSub.
  ///
  /// In en, this message translates to:
  /// **'When your week closes: {day} 20:00'**
  String notifWeeklyReviewSub(String day);

  /// No description provided for @notifWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week is ready'**
  String get notifWeeklyTitle;

  /// No description provided for @notifWeeklyBody.
  ///
  /// In en, this message translates to:
  /// **'This week\'s summary and one focus for next week.'**
  String get notifWeeklyBody;

  /// No description provided for @ppTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress photos'**
  String get ppTitle;

  /// No description provided for @ppEntrySub.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s) · never uploaded'**
  String ppEntrySub(int count);

  /// No description provided for @ppEntryEmpty.
  ///
  /// In en, this message translates to:
  /// **'The mirror shows change before the scale does'**
  String get ppEntryEmpty;

  /// No description provided for @ppEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get ppEmptyTitle;

  /// No description provided for @ppEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Regular photos from the same angle and in the same light show change weeks before the scale.'**
  String get ppEmptyMsg;

  /// No description provided for @ppAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get ppAdd;

  /// No description provided for @ppAngleFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get ppAngleFront;

  /// No description provided for @ppAngleSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get ppAngleSide;

  /// No description provided for @ppAngleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ppAngleBack;

  /// No description provided for @ppAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ppAll;

  /// No description provided for @ppCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get ppCamera;

  /// No description provided for @ppGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get ppGallery;

  /// No description provided for @ppAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get ppAngle;

  /// No description provided for @ppDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get ppDeleteTitle;

  /// No description provided for @ppDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This photo isn\'t backed up on our server; once deleted, it can\'t be restored in the app.'**
  String get ppDeleteMsg;

  /// No description provided for @ppCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get ppCompare;

  /// No description provided for @ppCompareHint.
  ///
  /// In en, this message translates to:
  /// **'Select two photos to compare'**
  String get ppCompareHint;

  /// No description provided for @ppSelected.
  ///
  /// In en, this message translates to:
  /// **'{count}/2 selected'**
  String ppSelected(int count);

  /// No description provided for @ppDaysApart.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) apart'**
  String ppDaysApart(int days);

  /// No description provided for @ppDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Photos are never uploaded to our server or saved to your gallery; they\'re stored on this phone. If your phone\'s own backup (iCloud / Google) is on, they\'re included in it. They\'re deleted from this phone if you switch accounts.'**
  String get ppDeviceOnly;

  /// No description provided for @ppLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load photos'**
  String get ppLoadError;

  /// No description provided for @ppSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the photo'**
  String get ppSaveError;

  /// No description provided for @ppMissingFile.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get ppMissingFile;

  /// No description provided for @homeTitleToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTitleToday;

  /// No description provided for @homeUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get homeUpNext;

  /// No description provided for @homeTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PLAN'**
  String get homeTodayPlan;

  /// No description provided for @homePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 exercise} other{{count} exercises}} · Planned routine'**
  String homePlanSubtitle(int count);

  /// No description provided for @homeInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get homeInProgress;

  /// No description provided for @homeResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume session'**
  String get homeResumeAction;

  /// No description provided for @homeRhythmKicker.
  ///
  /// In en, this message translates to:
  /// **'YOUR RHYTHM'**
  String get homeRhythmKicker;

  /// No description provided for @homeRhythmLeft.
  ///
  /// In en, this message translates to:
  /// **'This week {done}/{goal} workouts · {left} to go'**
  String homeRhythmLeft(int done, int goal, int left);

  /// No description provided for @homeRhythmDone.
  ///
  /// In en, this message translates to:
  /// **'This week\'s goal is done ({done}/{goal})'**
  String homeRhythmDone(int done, int goal);

  /// No description provided for @homeRhythmEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal: {goal} workouts · rest days don\'t break it'**
  String homeRhythmEmptySub(int goal);

  /// No description provided for @homeRhythmRestartSub.
  ///
  /// In en, this message translates to:
  /// **'Last week\'s goal was missed · this week {done}/{goal}'**
  String homeRhythmRestartSub(int done, int goal);

  /// No description provided for @homeLast30.
  ///
  /// In en, this message translates to:
  /// **'LAST 30 DAYS'**
  String get homeLast30;

  /// No description provided for @homeStatKcalEstimated.
  ///
  /// In en, this message translates to:
  /// **'est. kcal'**
  String get homeStatKcalEstimated;

  /// No description provided for @homeDayLog.
  ///
  /// In en, this message translates to:
  /// **'Today\'s log'**
  String get homeDayLog;

  /// No description provided for @calTitle.
  ///
  /// In en, this message translates to:
  /// **'CALENDAR'**
  String get calTitle;

  /// No description provided for @calBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get calBackToToday;

  /// No description provided for @calPrevWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get calPrevWeek;

  /// No description provided for @calNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get calNextWeek;

  /// No description provided for @calPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calPrevMonth;

  /// No description provided for @calNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calNextMonth;

  /// No description provided for @calOpenMonth.
  ///
  /// In en, this message translates to:
  /// **'Open month view'**
  String get calOpenMonth;

  /// No description provided for @calLegendRecord.
  ///
  /// In en, this message translates to:
  /// **'Has entries'**
  String get calLegendRecord;

  /// No description provided for @calSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {date}'**
  String calSelected(String date);

  /// No description provided for @calDayRecords.
  ///
  /// In en, this message translates to:
  /// **'Entries for this day'**
  String get calDayRecords;

  /// No description provided for @calOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get calOpen;

  /// No description provided for @calWorkoutLine.
  ///
  /// In en, this message translates to:
  /// **'{sets, plural, one{1 set} other{{sets} sets}} · {volume} volume'**
  String calWorkoutLine(int sets, String volume);

  /// No description provided for @calNutritionLine.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {protein} g protein'**
  String calNutritionLine(int kcal, int protein);

  /// No description provided for @calWaterLine.
  ///
  /// In en, this message translates to:
  /// **'{liters} L water'**
  String calWaterLine(String liters);

  /// No description provided for @asMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get asMoveUp;

  /// No description provided for @asMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get asMoveDown;

  /// No description provided for @asRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets'**
  String get asRestTitle;

  /// No description provided for @asRestRoutineNote.
  ///
  /// In en, this message translates to:
  /// **'Saved to the routine too — next time it starts with this.'**
  String get asRestRoutineNote;

  /// No description provided for @asRestSessionNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to this workout.'**
  String get asRestSessionNote;

  /// No description provided for @asRestChange.
  ///
  /// In en, this message translates to:
  /// **'Change rest time'**
  String get asRestChange;

  /// No description provided for @asRestSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the rest time to the routine'**
  String get asRestSaveError;

  /// No description provided for @asSuggestHint.
  ///
  /// In en, this message translates to:
  /// **'Tap ✓ to log {value}'**
  String asSuggestHint(String value);

  /// No description provided for @asStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight step'**
  String get asStepTitle;

  /// No description provided for @asStepHelp.
  ///
  /// In en, this message translates to:
  /// **'The − and + buttons change the weight by this amount. Remembered for this exercise.'**
  String get asStepHelp;

  /// No description provided for @asStepChange.
  ///
  /// In en, this message translates to:
  /// **'Change weight step'**
  String get asStepChange;

  /// No description provided for @asStepDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease weight by {step}'**
  String asStepDecrease(String step);

  /// No description provided for @asStepIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase weight by {step}'**
  String asStepIncrease(String step);

  /// No description provided for @wrThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get wrThisWeek;

  /// No description provided for @wrHowCalculated.
  ///
  /// In en, this message translates to:
  /// **'How it\'s calculated'**
  String get wrHowCalculated;

  /// No description provided for @wrKpiWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get wrKpiWorkouts;

  /// No description provided for @wrKpiVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get wrKpiVolume;

  /// No description provided for @wrKpiKcal.
  ///
  /// In en, this message translates to:
  /// **'Avg. calories'**
  String get wrKpiKcal;

  /// No description provided for @wrKpiWeight.
  ///
  /// In en, this message translates to:
  /// **'Avg. weight'**
  String get wrKpiWeight;

  /// No description provided for @wrPrevValue.
  ///
  /// In en, this message translates to:
  /// **'Last week: {value}'**
  String wrPrevValue(String value);

  /// No description provided for @wrPlannedOf.
  ///
  /// In en, this message translates to:
  /// **'of {planned} planned'**
  String wrPlannedOf(int planned);

  /// No description provided for @wrLoggedOf.
  ///
  /// In en, this message translates to:
  /// **'{days}/{total} days logged'**
  String wrLoggedOf(int days, int total);

  /// No description provided for @wrProteinAvg.
  ///
  /// In en, this message translates to:
  /// **'{protein} g protein'**
  String wrProteinAvg(int protein);

  /// No description provided for @wrGoalShort.
  ///
  /// In en, this message translates to:
  /// **'Goal {kcal}'**
  String wrGoalShort(int kcal);

  /// No description provided for @wrMeasureCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 weigh-in} other{{count} weigh-ins}}'**
  String wrMeasureCount(int count);

  /// No description provided for @wrSingleShort.
  ///
  /// In en, this message translates to:
  /// **'Single weigh-in — not a trend'**
  String get wrSingleShort;

  /// No description provided for @wrNoPrevShort.
  ///
  /// In en, this message translates to:
  /// **'No weigh-in last week'**
  String get wrNoPrevShort;

  /// No description provided for @wrNoRecord.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get wrNoRecord;

  /// No description provided for @wrProgressDelta.
  ///
  /// In en, this message translates to:
  /// **'1RM +{delta}'**
  String wrProgressDelta(String delta);

  /// No description provided for @wrVsPrev.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get wrVsPrev;

  /// No description provided for @rhythmStart.
  ///
  /// In en, this message translates to:
  /// **'Start your rhythm'**
  String get rhythmStart;

  /// No description provided for @rhythmFirstWeek.
  ///
  /// In en, this message translates to:
  /// **'Complete your first week'**
  String get rhythmFirstWeek;

  /// No description provided for @rhythmFirstWeekLastOne.
  ///
  /// In en, this message translates to:
  /// **'One more workout and week one is yours'**
  String get rhythmFirstWeekLastOne;

  /// No description provided for @rhythmWeek1.
  ///
  /// In en, this message translates to:
  /// **'Week one: done!'**
  String get rhythmWeek1;

  /// No description provided for @rhythmWeek2.
  ///
  /// In en, this message translates to:
  /// **'2 weeks in a row, a habit is forming'**
  String get rhythmWeek2;

  /// No description provided for @rhythmWeek3.
  ///
  /// In en, this message translates to:
  /// **'3 weeks! You\'ve found your rhythm'**
  String get rhythmWeek3;

  /// No description provided for @rhythmMonth1.
  ///
  /// In en, this message translates to:
  /// **'One month strong, this is your routine now'**
  String get rhythmMonth1;

  /// No description provided for @rhythmMonth2.
  ///
  /// In en, this message translates to:
  /// **'2 months without a break, serious work'**
  String get rhythmMonth2;

  /// No description provided for @rhythmMonth3.
  ///
  /// In en, this message translates to:
  /// **'3 months! Discipline is winning'**
  String get rhythmMonth3;

  /// No description provided for @rhythmHalfYear.
  ///
  /// In en, this message translates to:
  /// **'Half a year unbroken, legendary streak'**
  String get rhythmHalfYear;

  /// No description provided for @rhythmYear1.
  ///
  /// In en, this message translates to:
  /// **'A full year. Hats off'**
  String get rhythmYear1;

  /// No description provided for @rhythmDoneA.
  ///
  /// In en, this message translates to:
  /// **'Week {n}, in the bag'**
  String rhythmDoneA(int n);

  /// No description provided for @rhythmDoneB.
  ///
  /// In en, this message translates to:
  /// **'{n} weeks and no stopping'**
  String rhythmDoneB(int n);

  /// No description provided for @rhythmDoneC.
  ///
  /// In en, this message translates to:
  /// **'{n}-week streak, on fire'**
  String rhythmDoneC(int n);

  /// No description provided for @rhythmDoneD.
  ///
  /// In en, this message translates to:
  /// **'{n} weeks, not a single miss'**
  String rhythmDoneD(int n);

  /// No description provided for @rhythmOngoingA.
  ///
  /// In en, this message translates to:
  /// **'{n}-week streak, take this week too'**
  String rhythmOngoingA(int n);

  /// No description provided for @rhythmOngoingB.
  ///
  /// In en, this message translates to:
  /// **'Carry the streak into week {next}'**
  String rhythmOngoingB(int next);

  /// No description provided for @rhythmOngoingC.
  ///
  /// In en, this message translates to:
  /// **'{n} weeks in, no quitting now'**
  String rhythmOngoingC(int n);

  /// No description provided for @rhythmOngoingLastOne.
  ///
  /// In en, this message translates to:
  /// **'One more workout, then week {next}'**
  String rhythmOngoingLastOne(int next);

  /// No description provided for @rhythmRestartA.
  ///
  /// In en, this message translates to:
  /// **'A new streak starts'**
  String get rhythmRestartA;

  /// No description provided for @rhythmRestartB.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get rhythmRestartB;

  /// No description provided for @rhythmRestartC.
  ///
  /// In en, this message translates to:
  /// **'Every streak starts with one workout'**
  String get rhythmRestartC;

  /// No description provided for @nhUsualBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Your usual breakfast'**
  String get nhUsualBreakfast;

  /// No description provided for @nhUsualLunch.
  ///
  /// In en, this message translates to:
  /// **'Your usual lunch'**
  String get nhUsualLunch;

  /// No description provided for @nhUsualDinner.
  ///
  /// In en, this message translates to:
  /// **'Your usual dinner'**
  String get nhUsualDinner;

  /// No description provided for @nhUsualSnack.
  ///
  /// In en, this message translates to:
  /// **'Your usual snack'**
  String get nhUsualSnack;

  /// No description provided for @nhUsualSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 food} other{{count} foods}} · {kcal} kcal · {protein} g protein'**
  String nhUsualSub(int count, int kcal, int protein);

  /// No description provided for @nhUsualAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get nhUsualAdd;

  /// No description provided for @nhUsualLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get nhUsualLater;

  /// No description provided for @nhUsualAdded.
  ///
  /// In en, this message translates to:
  /// **'{meal} added'**
  String nhUsualAdded(String meal);

  /// No description provided for @nhWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Log your first day this week · goal {goal} days'**
  String nhWeekStart(int goal);

  /// No description provided for @nhWeekGoing.
  ///
  /// In en, this message translates to:
  /// **'This week {done}/{goal} days logged · {left} to go'**
  String nhWeekGoing(int done, int goal, int left);

  /// No description provided for @nhWeekLastOne.
  ///
  /// In en, this message translates to:
  /// **'This week {done}/{goal} days · one more and the week is done'**
  String nhWeekLastOne(int done, int goal);

  /// No description provided for @nhWeekDone.
  ///
  /// In en, this message translates to:
  /// **'This week\'s logging goal is done ({done}/{goal})'**
  String nhWeekDone(int done, int goal);

  /// No description provided for @nhQuickButton.
  ///
  /// In en, this message translates to:
  /// **'Quick: kcal + protein'**
  String get nhQuickButton;

  /// No description provided for @nhQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick entry'**
  String get nhQuickTitle;

  /// No description provided for @nhQuickHint.
  ///
  /// In en, this message translates to:
  /// **'For meals you can\'t weigh: just calories and protein. It\'s also saved to your foods so you can find it next time.'**
  String get nhQuickHint;

  /// No description provided for @nhQuickName.
  ///
  /// In en, this message translates to:
  /// **'What did you eat? (optional)'**
  String get nhQuickName;

  /// No description provided for @nhQuickDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Quick entry'**
  String get nhQuickDefaultName;

  /// No description provided for @nhQuickKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get nhQuickKcal;

  /// No description provided for @nhQuickProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g, optional)'**
  String get nhQuickProtein;

  /// No description provided for @nhQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'quick entry'**
  String get nhQuickEntry;

  /// No description provided for @nhQuickAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String nhQuickAdded(String name);

  /// No description provided for @nhReminderCta.
  ///
  /// In en, this message translates to:
  /// **'Turn on meal reminders — no notification for meals you\'ve already logged.'**
  String get nhReminderCta;

  /// No description provided for @nhReminderEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get nhReminderEnable;

  /// No description provided for @nhReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders are on'**
  String get nhReminderEnabled;

  /// No description provided for @notifMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get notifMealLabel;

  /// No description provided for @notifMealSub.
  ///
  /// In en, this message translates to:
  /// **'If you haven\'t logged a meal, a bit after you usually do. Logged meals get no notification.'**
  String get notifMealSub;

  /// No description provided for @notifMealBreakfastTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged your breakfast?'**
  String get notifMealBreakfastTitle;

  /// No description provided for @notifMealLunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged your lunch?'**
  String get notifMealLunchTitle;

  /// No description provided for @notifMealDinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged your dinner?'**
  String get notifMealDinnerTitle;

  /// No description provided for @notifMealBody.
  ///
  /// In en, this message translates to:
  /// **'It takes 10 seconds.'**
  String get notifMealBody;

  /// No description provided for @notifMealBreakfastTitle2.
  ///
  /// In en, this message translates to:
  /// **'Start the day with one entry'**
  String get notifMealBreakfastTitle2;

  /// No description provided for @notifMealBreakfastTitle3.
  ///
  /// In en, this message translates to:
  /// **'What fueled your morning?'**
  String get notifMealBreakfastTitle3;

  /// No description provided for @notifMealLunchTitle2.
  ///
  /// In en, this message translates to:
  /// **'What was on your lunch plate?'**
  String get notifMealLunchTitle2;

  /// No description provided for @notifMealLunchTitle3.
  ///
  /// In en, this message translates to:
  /// **'Lunch break: a 10-second log'**
  String get notifMealLunchTitle3;

  /// No description provided for @notifMealDinnerTitle2.
  ///
  /// In en, this message translates to:
  /// **'One last entry before the day ends'**
  String get notifMealDinnerTitle2;

  /// No description provided for @notifMealDinnerTitle3.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget your dinner plate'**
  String get notifMealDinnerTitle3;

  /// No description provided for @notifMealBody2.
  ///
  /// In en, this message translates to:
  /// **'Log it while it\'s fresh and you won\'t forget the portion.'**
  String get notifMealBody2;

  /// No description provided for @notifMealBody3.
  ///
  /// In en, this message translates to:
  /// **'Not sure? A quick estimated calorie entry is enough.'**
  String get notifMealBody3;

  /// No description provided for @notifMealBody4.
  ///
  /// In en, this message translates to:
  /// **'This meal completes today\'s picture.'**
  String get notifMealBody4;

  /// No description provided for @notifMealBody5.
  ///
  /// In en, this message translates to:
  /// **'Seeing what you eat is half the way to your goal.'**
  String get notifMealBody5;

  /// No description provided for @notifMealBody6.
  ///
  /// In en, this message translates to:
  /// **'Your protein goal is waiting on this meal.'**
  String get notifMealBody6;

  /// No description provided for @notifMealUsualBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Your usual breakfast: {foods}. Add it with one tap.'**
  String notifMealUsualBreakfast(String foods);

  /// No description provided for @notifMealUsualLunch.
  ///
  /// In en, this message translates to:
  /// **'Your usual lunch: {foods}. Add it with one tap.'**
  String notifMealUsualLunch(String foods);

  /// No description provided for @notifMealUsualDinner.
  ///
  /// In en, this message translates to:
  /// **'Your usual dinner: {foods}. Add it with one tap.'**
  String notifMealUsualDinner(String foods);

  /// No description provided for @notifMealWeekStart.
  ///
  /// In en, this message translates to:
  /// **'This week\'s first log is waiting for you.'**
  String get notifMealWeekStart;

  /// No description provided for @notifMealWeekProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{goal} days logged this week. Log today to make it {next}/{goal}.'**
  String notifMealWeekProgress(int done, int goal, int next);

  /// No description provided for @notifMealWeekMet.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal reached. Log today too and keep the picture complete.'**
  String get notifMealWeekMet;

  /// No description provided for @nhPortion.
  ///
  /// In en, this message translates to:
  /// **'portion'**
  String get nhPortion;

  /// No description provided for @foodCatSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweets & snacks'**
  String get foodCatSweet;

  /// No description provided for @foodCatDrink.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get foodCatDrink;

  /// No description provided for @attribUsdaDesc.
  ///
  /// In en, this message translates to:
  /// **'Basic food nutrition values; Turkish dishes are estimated from their ingredients'**
  String get attribUsdaDesc;

  /// No description provided for @afScan.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get afScan;

  /// No description provided for @afQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick calories'**
  String get afQuick;

  /// No description provided for @afCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own food'**
  String get afCustom;

  /// No description provided for @afRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get afRecent;

  /// No description provided for @afAllCount.
  ///
  /// In en, this message translates to:
  /// **'All foods · {count}'**
  String afAllCount(int count);

  /// No description provided for @afResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String afResults(int count);

  /// No description provided for @afCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get afCatAll;

  /// No description provided for @afAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String afAdded(String name);

  /// No description provided for @afSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry added} other{{count} entries added}}'**
  String afSessionCount(int count);

  /// No description provided for @afDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get afDone;

  /// No description provided for @afAddBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Add to breakfast'**
  String get afAddBreakfast;

  /// No description provided for @afAddLunch.
  ///
  /// In en, this message translates to:
  /// **'Add to lunch'**
  String get afAddLunch;

  /// No description provided for @afAddDinner.
  ///
  /// In en, this message translates to:
  /// **'Add to dinner'**
  String get afAddDinner;

  /// No description provided for @afAddSnack.
  ///
  /// In en, this message translates to:
  /// **'Add to snack'**
  String get afAddSnack;

  /// No description provided for @afQuickAddTip.
  ///
  /// In en, this message translates to:
  /// **'Add now: {portion}'**
  String afQuickAddTip(String portion);

  /// No description provided for @afChangeMeal.
  ///
  /// In en, this message translates to:
  /// **'Change meal'**
  String get afChangeMeal;

  /// No description provided for @afEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to change the amount, + to add right away'**
  String get afEditHint;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'One step further today.'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Performance journal'**
  String get journalSubtitle;

  /// No description provided for @journalEnergyMacros.
  ///
  /// In en, this message translates to:
  /// **'Energy & macros'**
  String get journalEnergyMacros;

  /// No description provided for @journalEnergyLogged.
  ///
  /// In en, this message translates to:
  /// **'Energy logged'**
  String get journalEnergyLogged;

  /// No description provided for @journalEnergyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get journalEnergyGoal;

  /// No description provided for @journalProteinRing.
  ///
  /// In en, this message translates to:
  /// **'Inner ring: protein'**
  String get journalProteinRing;

  /// No description provided for @journalMeals.
  ///
  /// In en, this message translates to:
  /// **'Your meal journal'**
  String get journalMeals;

  /// No description provided for @journalMealAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get journalMealAdd;

  /// No description provided for @journalActivity.
  ///
  /// In en, this message translates to:
  /// **'Workout activity'**
  String get journalActivity;

  /// No description provided for @journalActivityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days · estimated kcal'**
  String get journalActivityPeriod;

  /// No description provided for @journalActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged in the last 7 days.'**
  String get journalActivityEmpty;

  /// No description provided for @journalEstimateMissing.
  ///
  /// In en, this message translates to:
  /// **'Weight and duration are needed to estimate calories.'**
  String get journalEstimateMissing;

  /// No description provided for @journalNoWorkout.
  ///
  /// In en, this message translates to:
  /// **'No workout logged on this day.'**
  String get journalNoWorkout;

  /// No description provided for @journalActivitySessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 logged workout} other{{count} logged workouts}}'**
  String journalActivitySessions(int count);

  /// No description provided for @nutritionDailyEnergy.
  ///
  /// In en, this message translates to:
  /// **'Daily energy'**
  String get nutritionDailyEnergy;

  /// No description provided for @nutritionKcalRemaining.
  ///
  /// In en, this message translates to:
  /// **'kcal remaining'**
  String get nutritionKcalRemaining;

  /// No description provided for @nutritionKcalAboveGoal.
  ///
  /// In en, this message translates to:
  /// **'kcal above goal'**
  String get nutritionKcalAboveGoal;

  /// No description provided for @nutritionKcalAtGoal.
  ///
  /// In en, this message translates to:
  /// **'kcal to goal'**
  String get nutritionKcalAtGoal;

  /// No description provided for @nutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'Meal journal'**
  String get nutritionDiary;

  /// No description provided for @nutritionFoodCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 food} other{{count} foods}}'**
  String nutritionFoodCount(int count);

  /// No description provided for @nutritionDayCompleteToday.
  ///
  /// In en, this message translates to:
  /// **'I logged all of today’s meals'**
  String get nutritionDayCompleteToday;

  /// No description provided for @nutritionDayCompletePast.
  ///
  /// In en, this message translates to:
  /// **'I logged all meals for this day'**
  String get nutritionDayCompletePast;

  /// No description provided for @nutritionDayCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Tick it so the weekly review and assistant don’t treat this day as incomplete.'**
  String get nutritionDayCompleteHint;

  /// No description provided for @nutritionDayCompleted.
  ///
  /// In en, this message translates to:
  /// **'All meals logged'**
  String get nutritionDayCompleted;

  /// No description provided for @nutritionDayCompletedSub.
  ///
  /// In en, this message translates to:
  /// **'This day counts as complete in your weekly review.'**
  String get nutritionDayCompletedSub;

  /// No description provided for @nutritionDayChangedAfter.
  ///
  /// In en, this message translates to:
  /// **'Changed after completion'**
  String get nutritionDayChangedAfter;

  /// No description provided for @nutritionDayReopen.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get nutritionDayReopen;

  /// No description provided for @wrCompletedDays.
  ///
  /// In en, this message translates to:
  /// **'{days} completed days'**
  String wrCompletedDays(int days);

  /// No description provided for @wrExcludedDays.
  ///
  /// In en, this message translates to:
  /// **'{days} not counted'**
  String wrExcludedDays(int days);

  /// No description provided for @wrProteinHit.
  ///
  /// In en, this message translates to:
  /// **'Protein goal {hit}/{total} days'**
  String wrProteinHit(int hit, int total);

  /// No description provided for @healthSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get healthSteps;

  /// No description provided for @healthInstall.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect'**
  String get healthInstall;

  /// No description provided for @healthSeeSteps.
  ///
  /// In en, this message translates to:
  /// **'See your steps'**
  String get healthSeeSteps;

  /// No description provided for @healthNoData.
  ///
  /// In en, this message translates to:
  /// **'No data — check your health permissions'**
  String get healthNoData;

  /// No description provided for @healthReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read your steps. Try again.'**
  String get healthReadError;

  /// No description provided for @healthStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily step goal'**
  String get healthStepGoal;

  /// No description provided for @healthPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your steps on Home'**
  String get healthPermissionTitle;

  /// No description provided for @healthPermissionStepsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only your step count is read.'**
  String get healthPermissionStepsOnly;

  /// No description provided for @healthPermissionOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Your steps stay on this phone.'**
  String get healthPermissionOnDevice;

  /// No description provided for @healthPermissionNoSharing.
  ///
  /// In en, this message translates to:
  /// **'Your calorie goal stays the same. Nothing is shared.'**
  String get healthPermissionNoSharing;

  /// No description provided for @healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get healthConnect;

  /// No description provided for @healthNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get healthNotNow;

  /// No description provided for @healthConnectError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t connect. Check your health permissions and try again.'**
  String get healthConnectError;

  /// No description provided for @healthWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get healthWeekTitle;

  /// No description provided for @healthRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get healthRetry;

  /// No description provided for @healthNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected · see your steps'**
  String get healthNotConnected;

  /// No description provided for @healthAverage.
  ///
  /// In en, this message translates to:
  /// **'Average of days with data'**
  String get healthAverage;

  /// No description provided for @healthStepCount.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String healthStepCount(String count);

  /// No description provided for @healthGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank or enter 0 for no goal.'**
  String get healthGoalHint;

  /// No description provided for @healthGoalSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save your goal. Try again.'**
  String get healthGoalSaveError;

  /// No description provided for @healthSection.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthSection;

  /// No description provided for @healthConnection.
  ///
  /// In en, this message translates to:
  /// **'Step connection'**
  String get healthConnection;

  /// No description provided for @healthConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get healthConnected;

  /// No description provided for @healthDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get healthDisconnect;

  /// No description provided for @healthDisconnectNote.
  ///
  /// In en, this message translates to:
  /// **'You can also revoke access in Health or Health Connect settings.'**
  String get healthDisconnectNote;

  /// No description provided for @healthNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No goal'**
  String get healthNoGoal;

  /// No description provided for @healthInstallError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open Health Connect. Try again.'**
  String get healthInstallError;

  /// No description provided for @healthDisconnectError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t disconnect. Try again.'**
  String get healthDisconnectError;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask my data'**
  String get assistantTitle;

  /// No description provided for @assistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers from your records. Pick a question to explore.'**
  String get assistantSubtitle;

  /// No description provided for @assistantQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'How were my workouts this week?'**
  String get assistantQuestionHint;

  /// No description provided for @assistantAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get assistantAsk;

  /// No description provided for @assistantReady.
  ///
  /// In en, this message translates to:
  /// **'Ready questions'**
  String get assistantReady;

  /// No description provided for @assistantAll.
  ///
  /// In en, this message translates to:
  /// **'All questions'**
  String get assistantAll;

  /// No description provided for @assistantLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get assistantLess;

  /// No description provided for @assistantUnderstood.
  ///
  /// In en, this message translates to:
  /// **'My understanding'**
  String get assistantUnderstood;

  /// No description provided for @assistantChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get assistantChange;

  /// No description provided for @assistantApply.
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get assistantApply;

  /// No description provided for @assistantPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get assistantPeriod;

  /// No description provided for @assistantExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get assistantExercise;

  /// No description provided for @assistantChooseExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise'**
  String get assistantChooseExercise;

  /// No description provided for @assistantInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Explain the numbers too'**
  String get assistantInterpretation;

  /// No description provided for @assistantMeal.
  ///
  /// In en, this message translates to:
  /// **'Choose a meal for food examples'**
  String get assistantMeal;

  /// No description provided for @assistantNoMeal.
  ///
  /// In en, this message translates to:
  /// **'Remaining amounts only'**
  String get assistantNoMeal;

  /// No description provided for @assistantPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your question will be sent to Google'**
  String get assistantPrivacyTitle;

  /// No description provided for @assistantPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only your question and fixed routing definitions go to Gemini; your workout, nutrition and measurement records are not sent to Google. With free Gemini, Google may use the text and model output to improve products, with possible human review. Do not enter identity, contact or private health information. Ready questions run on your device.'**
  String get assistantPrivacy;

  /// No description provided for @assistantPrivacyAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand, send question'**
  String get assistantPrivacyAccept;

  /// No description provided for @assistantPrivacyCancel.
  ///
  /// In en, this message translates to:
  /// **'Use ready questions'**
  String get assistantPrivacyCancel;

  /// No description provided for @assistantUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Free-text routing is unavailable. You can continue with ready questions.'**
  String get assistantUnavailable;

  /// No description provided for @assistantSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in to ask a free-text question. Ready questions run on your device.'**
  String get assistantSignedOut;

  /// No description provided for @assistantPrivateBlocked.
  ///
  /// In en, this message translates to:
  /// **'This question may contain private information. Remove identity, contact or health details, or choose a ready question.'**
  String get assistantPrivateBlocked;

  /// No description provided for @assistantFallback.
  ///
  /// In en, this message translates to:
  /// **'I could not reliably route this question. Choose a ready question to explore your records.'**
  String get assistantFallback;

  /// No description provided for @assistantClarify.
  ///
  /// In en, this message translates to:
  /// **'Choose a period or exercise before opening the result.'**
  String get assistantClarify;

  /// No description provided for @assistantMulti.
  ///
  /// In en, this message translates to:
  /// **'There are several topics. Which one should we explore first?'**
  String get assistantMulti;

  /// No description provided for @assistantQuota.
  ///
  /// In en, this message translates to:
  /// **'Question limit reached. Resets: {time}. Ready questions remain available.'**
  String assistantQuota(String time);

  /// No description provided for @assistantError.
  ///
  /// In en, this message translates to:
  /// **'Could not read records. Try again.'**
  String get assistantError;

  /// No description provided for @assistantRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get assistantRetry;

  /// No description provided for @assistantOpenRecords.
  ///
  /// In en, this message translates to:
  /// **'Open records'**
  String get assistantOpenRecords;

  /// No description provided for @assistantRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String assistantRecords(String count);

  /// No description provided for @assistantSoFar.
  ///
  /// In en, this message translates to:
  /// **'So far'**
  String get assistantSoFar;

  /// No description provided for @assistantUnknownStart.
  ///
  /// In en, this message translates to:
  /// **'Since the first record'**
  String get assistantUnknownStart;

  /// No description provided for @assistantNoData.
  ///
  /// In en, this message translates to:
  /// **'No records in this period. Missing data is not a zero result.'**
  String get assistantNoData;

  /// No description provided for @assistantInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Numbers are available; there is not enough data for a trend interpretation yet.'**
  String get assistantInsufficient;

  /// No description provided for @assistantNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No goal has been set for this calculation.'**
  String get assistantNoGoal;

  /// No description provided for @assistantNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No workout days are scheduled.'**
  String get assistantNoPlan;

  /// No description provided for @assistantIncompleteDays.
  ///
  /// In en, this message translates to:
  /// **'No completed days; protein-goal success cannot be calculated.'**
  String get assistantIncompleteDays;

  /// No description provided for @assistantLoggedBasis.
  ///
  /// In en, this message translates to:
  /// **'Logged days only; records may be incomplete.'**
  String get assistantLoggedBasis;

  /// No description provided for @assistantCompletedBasis.
  ///
  /// In en, this message translates to:
  /// **'Average uses completed days only; a completed empty day counts as zero.'**
  String get assistantCompletedBasis;

  /// No description provided for @assistantCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Uses your current plan; past plan changes are unknown.'**
  String get assistantCurrentPlan;

  /// No description provided for @assistantFoodBasis.
  ///
  /// In en, this message translates to:
  /// **'Examples use past portions for the selected meal. Filtered by remaining calories only; nothing is logged automatically.'**
  String get assistantFoodBasis;

  /// No description provided for @assistantUnknownExercise.
  ///
  /// In en, this message translates to:
  /// **'Unknown exercise'**
  String get assistantUnknownExercise;

  /// No description provided for @assistantOwnHistory.
  ///
  /// In en, this message translates to:
  /// **'Your own history'**
  String get assistantOwnHistory;

  /// No description provided for @assistantGuideline.
  ///
  /// In en, this message translates to:
  /// **'General research finding'**
  String get assistantGuideline;

  /// No description provided for @assistantSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get assistantSources;

  /// No description provided for @assistantDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get assistantDeveloper;

  /// No description provided for @assistantQuality.
  ///
  /// In en, this message translates to:
  /// **'Assistant quality'**
  String get assistantQuality;

  /// No description provided for @assistantQualityInfo.
  ///
  /// In en, this message translates to:
  /// **'Text-free events on this device only. Correction rate is not accuracy; no correction does not prove a correct route.'**
  String get assistantQualityInfo;

  /// No description provided for @assistantQualityAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic answers'**
  String get assistantQualityAuto;

  /// No description provided for @assistantQualityCorrections.
  ///
  /// In en, this message translates to:
  /// **'Changed selections'**
  String get assistantQualityCorrections;

  /// No description provided for @assistantQualityLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency: median / 95th percentile'**
  String get assistantQualityLatency;

  /// No description provided for @assistantQualityTokens.
  ///
  /// In en, this message translates to:
  /// **'Input / output tokens'**
  String get assistantQualityTokens;

  /// No description provided for @assistantQualityFree.
  ///
  /// In en, this message translates to:
  /// **'Gemini free tier · cost \$0'**
  String get assistantQualityFree;

  /// No description provided for @assistantQualityClear.
  ///
  /// In en, this message translates to:
  /// **'Clear local quality events'**
  String get assistantQualityClear;

  /// No description provided for @assistantQualityClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete assistant quality events? Your fitness records are preserved.'**
  String get assistantQualityClearConfirm;

  /// No description provided for @assistantQualitySmall.
  ///
  /// In en, this message translates to:
  /// **'Small sample; interpret the rate cautiously.'**
  String get assistantQualitySmall;

  /// No description provided for @assistantQualityWarning.
  ///
  /// In en, this message translates to:
  /// **'Correction rate exceeded 3% in two consecutive weeks. Review routing.'**
  String get assistantQualityWarning;

  /// No description provided for @assistantQualityTransitions.
  ///
  /// In en, this message translates to:
  /// **'Query changes'**
  String get assistantQualityTransitions;

  /// No description provided for @assistantQualityDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get assistantQualityDays;

  /// No description provided for @assistantNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get assistantNotAvailable;

  /// No description provided for @assistantPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get assistantPeriodToday;

  /// No description provided for @assistantPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get assistantPeriodThisWeek;

  /// No description provided for @assistantPeriodLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get assistantPeriodLastWeek;

  /// No description provided for @assistantPeriodLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get assistantPeriodLast30Days;

  /// No description provided for @assistantPeriodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get assistantPeriodAllTime;

  /// No description provided for @assistantQueryWorkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'How were my workouts?'**
  String get assistantQueryWorkoutSummary;

  /// No description provided for @assistantQueryPlanAdherence.
  ///
  /// In en, this message translates to:
  /// **'How closely did I follow scheduled days?'**
  String get assistantQueryPlanAdherence;

  /// No description provided for @assistantQueryStrengthProgress.
  ///
  /// In en, this message translates to:
  /// **'Which exercises improved?'**
  String get assistantQueryStrengthProgress;

  /// No description provided for @assistantQueryExerciseHistory.
  ///
  /// In en, this message translates to:
  /// **'How did I progress in this exercise?'**
  String get assistantQueryExerciseHistory;

  /// No description provided for @assistantQueryNutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'What do my nutrition records show?'**
  String get assistantQueryNutritionSummary;

  /// No description provided for @assistantQueryProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'How many days did I reach my protein goal?'**
  String get assistantQueryProteinGoal;

  /// No description provided for @assistantQueryWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'How did my weight change?'**
  String get assistantQueryWeightTrend;

  /// No description provided for @assistantQueryMuscleBalance.
  ///
  /// In en, this message translates to:
  /// **'How many sets per muscle group?'**
  String get assistantQueryMuscleBalance;

  /// No description provided for @assistantQueryStreak.
  ///
  /// In en, this message translates to:
  /// **'How many consistent weeks?'**
  String get assistantQueryStreak;

  /// No description provided for @assistantQueryTodayRemaining.
  ///
  /// In en, this message translates to:
  /// **'What remains of my goals today?'**
  String get assistantQueryTodayRemaining;

  /// No description provided for @assistantQueryTopExercises.
  ///
  /// In en, this message translates to:
  /// **'Which exercises did I do most?'**
  String get assistantQueryTopExercises;

  /// No description provided for @assistantMetricSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get assistantMetricSessions;

  /// No description provided for @assistantMetricSets.
  ///
  /// In en, this message translates to:
  /// **'Completed sets'**
  String get assistantMetricSets;

  /// No description provided for @assistantMetricMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get assistantMetricMinutes;

  /// No description provided for @assistantMetricVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get assistantMetricVolume;

  /// No description provided for @assistantMetricPlannedDays.
  ///
  /// In en, this message translates to:
  /// **'Scheduled days'**
  String get assistantMetricPlannedDays;

  /// No description provided for @assistantMetricDoneDays.
  ///
  /// In en, this message translates to:
  /// **'Scheduled days completed'**
  String get assistantMetricDoneDays;

  /// No description provided for @assistantMetricLoggedDays.
  ///
  /// In en, this message translates to:
  /// **'Logged days'**
  String get assistantMetricLoggedDays;

  /// No description provided for @assistantMetricCompletedDays.
  ///
  /// In en, this message translates to:
  /// **'Completed days'**
  String get assistantMetricCompletedDays;

  /// No description provided for @assistantMetricExcludedDays.
  ///
  /// In en, this message translates to:
  /// **'Excluded days'**
  String get assistantMetricExcludedDays;

  /// No description provided for @assistantMetricAvgKcal.
  ///
  /// In en, this message translates to:
  /// **'Average energy'**
  String get assistantMetricAvgKcal;

  /// No description provided for @assistantMetricAvgProtein.
  ///
  /// In en, this message translates to:
  /// **'Average protein'**
  String get assistantMetricAvgProtein;

  /// No description provided for @assistantMetricProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein goal'**
  String get assistantMetricProteinGoal;

  /// No description provided for @assistantMetricHitDays.
  ///
  /// In en, this message translates to:
  /// **'Completed days reaching goal'**
  String get assistantMetricHitDays;

  /// No description provided for @assistantMetricMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get assistantMetricMeasurements;

  /// No description provided for @assistantMetricFirstWeight.
  ///
  /// In en, this message translates to:
  /// **'First weight'**
  String get assistantMetricFirstWeight;

  /// No description provided for @assistantMetricLastWeight.
  ///
  /// In en, this message translates to:
  /// **'Last weight'**
  String get assistantMetricLastWeight;

  /// No description provided for @assistantMetricChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get assistantMetricChange;

  /// No description provided for @assistantMetricWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weekly streak'**
  String get assistantMetricWeeks;

  /// No description provided for @assistantMetricWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly day goal'**
  String get assistantMetricWeeklyGoal;

  /// No description provided for @assistantMetricRemainingKcal.
  ///
  /// In en, this message translates to:
  /// **'Remaining energy'**
  String get assistantMetricRemainingKcal;

  /// No description provided for @assistantMetricRemainingProtein.
  ///
  /// In en, this message translates to:
  /// **'Remaining protein'**
  String get assistantMetricRemainingProtein;

  /// No description provided for @assistantMetricFirstE1rm.
  ///
  /// In en, this message translates to:
  /// **'First estimated one-rep maximum'**
  String get assistantMetricFirstE1rm;

  /// No description provided for @assistantMetricLastE1rm.
  ///
  /// In en, this message translates to:
  /// **'Last estimated one-rep maximum'**
  String get assistantMetricLastE1rm;

  /// No description provided for @assistantMetricPortion.
  ///
  /// In en, this message translates to:
  /// **'Past portion'**
  String get assistantMetricPortion;

  /// No description provided for @assistantMetricPortionKcal.
  ///
  /// In en, this message translates to:
  /// **'Portion energy'**
  String get assistantMetricPortionKcal;

  /// No description provided for @assistantMetricPortionProtein.
  ///
  /// In en, this message translates to:
  /// **'Portion protein'**
  String get assistantMetricPortionProtein;

  /// No description provided for @insightMuscleBelowTen.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: {sets} sets, below the roughly {level} weekly-set level studied.'**
  String insightMuscleBelowTen(String muscle, String sets, String level);

  /// No description provided for @insightMuscleAtTen.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: {sets} sets, at or above the roughly {level}-set level studied.'**
  String insightMuscleAtTen(String muscle, String sets, String level);

  /// No description provided for @insightMuscleBeyondTwenty.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: {sets} sets. Evidence for added gains beyond {limitedEvidenceAbove} sets is limited.'**
  String insightMuscleBeyondTwenty(
    String muscle,
    String sets,
    String limitedEvidenceAbove,
  );

  /// No description provided for @insightWeightNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'{count} measurements spanning {spanDays} days. Trend interpretation needs at least two measurements over {minDays} days.'**
  String insightWeightNotEnoughData(
    String count,
    String spanDays,
    String minDays,
  );

  /// No description provided for @insightWeightAgainstGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly change is {weeklyChangeKg}, opposite your selected goal direction.'**
  String insightWeightAgainstGoal(String weeklyChangeKg);

  /// No description provided for @insightWeightNoClearChange.
  ///
  /// In en, this message translates to:
  /// **'Weekly change is {weeklyChangeKg}; no clear trend is visible.'**
  String insightWeightNoClearChange(String weeklyChangeKg);

  /// No description provided for @insightWeightLossSlower.
  ///
  /// In en, this message translates to:
  /// **'Weekly change is {weeklyChangeKg}; slower than the CDC general loss range of {rangeMinKg}–{rangeMaxKg}.'**
  String insightWeightLossSlower(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  );

  /// No description provided for @insightWeightLossInRange.
  ///
  /// In en, this message translates to:
  /// **'Weekly change is {weeklyChangeKg}; within the CDC general loss range of {rangeMinKg}–{rangeMaxKg}.'**
  String insightWeightLossInRange(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  );

  /// No description provided for @insightWeightLossFaster.
  ///
  /// In en, this message translates to:
  /// **'Weekly change is {weeklyChangeKg}; faster than the CDC general loss range of {rangeMinKg}–{rangeMaxKg}.'**
  String insightWeightLossFaster(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  );

  /// No description provided for @insightWeightGainSlower.
  ///
  /// In en, this message translates to:
  /// **'Weekly gain is {pctPerWeek}%, slower than the {rangeMinPct}–{rangeMaxPct}% level studied.'**
  String insightWeightGainSlower(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  );

  /// No description provided for @insightWeightGainInRange.
  ///
  /// In en, this message translates to:
  /// **'Weekly gain is {pctPerWeek}%, within the {rangeMinPct}–{rangeMaxPct}% level studied.'**
  String insightWeightGainInRange(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  );

  /// No description provided for @insightWeightGainFaster.
  ///
  /// In en, this message translates to:
  /// **'Weekly gain is {pctPerWeek}%, faster than the {rangeMinPct}–{rangeMaxPct}% level studied.'**
  String insightWeightGainFaster(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  );

  /// No description provided for @insightWeightStable.
  ///
  /// In en, this message translates to:
  /// **'Estimated change over the period is {totalChangePct}%, within ±{stablePct}% of the mean.'**
  String insightWeightStable(String totalChangePct, String stablePct);

  /// No description provided for @insightWeightDriftUp.
  ///
  /// In en, this message translates to:
  /// **'Estimated increase over the period is {totalChangePct}%.'**
  String insightWeightDriftUp(String totalChangePct);

  /// No description provided for @insightWeightDriftDown.
  ///
  /// In en, this message translates to:
  /// **'Estimated change over the period is {totalChangePct}%.'**
  String insightWeightDriftDown(String totalChangePct);

  /// No description provided for @insightWorkoutNotEnoughHistory.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value}. Comparison with your history needs at least {minWeeks} complete weeks; you have {baselineWeeks}.'**
  String insightWorkoutNotEnoughHistory(
    String metric,
    String value,
    String minWeeks,
    String baselineWeeks,
  );

  /// No description provided for @insightWorkoutNoBaseline.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value}. Historical median is 0; percentage comparison is unavailable.'**
  String insightWorkoutNoBaseline(String metric, String value);

  /// No description provided for @insightWorkoutSoFar.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value} so far. Median of the prior {baselineWeeks} weeks is {median}; an ongoing week is not compared as a full week.'**
  String insightWorkoutSoFar(
    String metric,
    String value,
    String baselineWeeks,
    String median,
  );

  /// No description provided for @insightWorkoutAboveMedian.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value}, historical median {median}; {pct}% above.'**
  String insightWorkoutAboveMedian(
    String metric,
    String value,
    String median,
    String pct,
  );

  /// No description provided for @insightWorkoutAtMedian.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value}, equal to the historical median ({median}).'**
  String insightWorkoutAtMedian(String metric, String value, String median);

  /// No description provided for @insightWorkoutBelowMedian.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {value}, historical median {median}; difference {pct}%.'**
  String insightWorkoutBelowMedian(
    String metric,
    String value,
    String median,
    String pct,
  );

  /// No description provided for @insightStrengthNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'No suitable weight/repetition sets; estimated one-rep maximum is unavailable.'**
  String get insightStrengthNotApplicable;

  /// No description provided for @insightStrengthNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Suitable sets on {days} distinct days; progress needs at least two days.'**
  String insightStrengthNotEnoughData(String days);

  /// No description provided for @insightStrengthUp.
  ///
  /// In en, this message translates to:
  /// **'Estimated one-rep maximum: {firstE1rm} → {lastE1rm}; {pct}% increase.'**
  String insightStrengthUp(String firstE1rm, String lastE1rm, String pct);

  /// No description provided for @insightStrengthStable.
  ///
  /// In en, this message translates to:
  /// **'Estimated one-rep maximum: {firstE1rm} → {lastE1rm}; change within ±1%.'**
  String insightStrengthStable(String firstE1rm, String lastE1rm);

  /// No description provided for @insightStrengthDown.
  ///
  /// In en, this message translates to:
  /// **'Estimated one-rep maximum: {firstE1rm} → {lastE1rm}; change {pct}%.'**
  String insightStrengthDown(String firstE1rm, String lastE1rm, String pct);

  /// No description provided for @insightStrengthPlateau.
  ///
  /// In en, this message translates to:
  /// **'Heaviest set was {topKg} in each of the last {weeks} consecutive data weeks.'**
  String insightStrengthPlateau(String topKg, String weeks);

  /// No description provided for @insightNutritionNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No nutrition data for this period.'**
  String get insightNutritionNoLogs;

  /// No description provided for @insightProteinGoalDays.
  ///
  /// In en, this message translates to:
  /// **'Protein goal of {goal} g reached on {hitDays}/{loggedDays} completed days.'**
  String insightProteinGoalDays(String goal, String hitDays, String loggedDays);

  /// No description provided for @insightKcalVsGoal.
  ///
  /// In en, this message translates to:
  /// **'Average across {loggedDays} days: {avgKcal} kcal; goal {goal} kcal ({pctOfGoal}%).'**
  String insightKcalVsGoal(
    String loggedDays,
    String avgKcal,
    String goal,
    String pctOfGoal,
  );

  /// No description provided for @insightProteinPerKgBelow.
  ///
  /// In en, this message translates to:
  /// **'Recorded average is {gPerKg} g/kg, below the roughly {breakpoint} g/kg level studied. Weight used: {bodyWeightKg} ({bodyWeightDate}).'**
  String insightProteinPerKgBelow(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  );

  /// No description provided for @insightProteinPerKgInRange.
  ///
  /// In en, this message translates to:
  /// **'Recorded average is {gPerKg} g/kg, within the {breakpoint}–{upper} g/kg range studied. Weight used: {bodyWeightKg} ({bodyWeightDate}).'**
  String insightProteinPerKgInRange(
    String gPerKg,
    String breakpoint,
    String upper,
    String bodyWeightKg,
    String bodyWeightDate,
  );

  /// No description provided for @insightProteinPerKgAbove.
  ///
  /// In en, this message translates to:
  /// **'Recorded average is {gPerKg} g/kg. Research found no additional lean-mass gains above roughly {breakpoint} g/kg; this is not a safety limit. Weight used: {bodyWeightKg} ({bodyWeightDate}).'**
  String insightProteinPerKgAbove(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  );

  /// No description provided for @insightTodayNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No energy goal; {loggedKcal} kcal and {loggedProtein} g protein recorded today.'**
  String insightTodayNoGoal(String loggedKcal, String loggedProtein);

  /// No description provided for @insightTodayRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remainingKcal} kcal remain to your energy goal. Records may be incomplete.'**
  String insightTodayRemaining(String remainingKcal);

  /// No description provided for @insightTodayGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Remaining energy is {remainingKcal} kcal; zero or a negative value means the recorded goal has been reached.'**
  String insightTodayGoalReached(String remainingKcal);

  /// No description provided for @assistantNoteGeneralGuideline.
  ///
  /// In en, this message translates to:
  /// **'General guidance, not personal medical advice.'**
  String get assistantNoteGeneralGuideline;

  /// No description provided for @assistantNoteConsultProfessional.
  ///
  /// In en, this message translates to:
  /// **'Consult a professional for medical assessment.'**
  String get assistantNoteConsultProfessional;

  /// No description provided for @assistantNoteSoFar.
  ///
  /// In en, this message translates to:
  /// **'Records so far in the ongoing period.'**
  String get assistantNoteSoFar;

  /// No description provided for @assistantNoteCompletedSetsCounted.
  ///
  /// In en, this message translates to:
  /// **'Completed non-warm-up sets count toward the primary muscle; studies examine challenging sets.'**
  String get assistantNoteCompletedSetsCounted;

  /// No description provided for @assistantNoteFastLossCaution.
  ///
  /// In en, this message translates to:
  /// **'Weekly loss exceeded 1.5%. This caution threshold is a product choice.'**
  String get assistantNoteFastLossCaution;

  /// No description provided for @assistantNoteLeanMassInfo.
  ///
  /// In en, this message translates to:
  /// **'In one study of strength athletes, roughly 0.7% weekly loss preserved lean mass better.'**
  String get assistantNoteLeanMassInfo;

  /// No description provided for @assistantNoteBeginnerIntermediateRange.
  ///
  /// In en, this message translates to:
  /// **'This range was studied for beginner/intermediate athletes.'**
  String get assistantNoteBeginnerIntermediateRange;

  /// No description provided for @assistantNoteLoggedOnly.
  ///
  /// In en, this message translates to:
  /// **'Recorded amounts only; records may be incomplete.'**
  String get assistantNoteLoggedOnly;

  /// No description provided for @assistantNoteCompletedDaysOnly.
  ///
  /// In en, this message translates to:
  /// **'Only completed days were included.'**
  String get assistantNoteCompletedDaysOnly;

  /// No description provided for @assistantNoteChooseGoalDirection.
  ///
  /// In en, this message translates to:
  /// **'Select a goal direction for direction-specific interpretation.'**
  String get assistantNoteChooseGoalDirection;

  /// No description provided for @assistantQualityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not write local quality event. You can still use your results.'**
  String get assistantQualityUnavailable;

  /// No description provided for @assistantDecisionAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get assistantDecisionAuto;

  /// No description provided for @assistantDecisionClarify.
  ///
  /// In en, this message translates to:
  /// **'Clarification'**
  String get assistantDecisionClarify;

  /// No description provided for @assistantDecisionMulti.
  ///
  /// In en, this message translates to:
  /// **'Multiple topics'**
  String get assistantDecisionMulti;

  /// No description provided for @assistantDecisionFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback to ready questions'**
  String get assistantDecisionFallback;

  /// No description provided for @assistantDecisionError.
  ///
  /// In en, this message translates to:
  /// **'Network / quota error'**
  String get assistantDecisionError;

  /// No description provided for @assistantMuscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get assistantMuscleChest;

  /// No description provided for @assistantMuscleUpperChest.
  ///
  /// In en, this message translates to:
  /// **'Upper chest'**
  String get assistantMuscleUpperChest;

  /// No description provided for @assistantMuscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get assistantMuscleBack;

  /// No description provided for @assistantMuscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get assistantMuscleShoulders;

  /// No description provided for @assistantMuscleFrontDelt.
  ///
  /// In en, this message translates to:
  /// **'Front delts'**
  String get assistantMuscleFrontDelt;

  /// No description provided for @assistantMuscleRearDelt.
  ///
  /// In en, this message translates to:
  /// **'Rear delts'**
  String get assistantMuscleRearDelt;

  /// No description provided for @assistantMuscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get assistantMuscleBiceps;

  /// No description provided for @assistantMuscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get assistantMuscleTriceps;

  /// No description provided for @assistantMuscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get assistantMuscleForearms;

  /// No description provided for @assistantMuscleLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get assistantMuscleLegs;

  /// No description provided for @assistantMuscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get assistantMuscleQuads;

  /// No description provided for @assistantMuscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get assistantMuscleHamstrings;

  /// No description provided for @assistantMuscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get assistantMuscleGlutes;

  /// No description provided for @assistantMuscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get assistantMuscleCalves;

  /// No description provided for @assistantMuscleCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get assistantMuscleCore;

  /// No description provided for @assistantMuscleFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full body'**
  String get assistantMuscleFullBody;

  /// No description provided for @assistantMuscleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get assistantMuscleOther;

  /// No description provided for @bmFromHealth.
  ///
  /// In en, this message translates to:
  /// **'Health · {app}'**
  String bmFromHealth(String app);

  /// No description provided for @bmHideTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide measurement'**
  String get bmHideTitle;

  /// No description provided for @bmHideMsg.
  ///
  /// In en, this message translates to:
  /// **'Hide the scale measurement from {date}? The record in your health app stays unchanged.'**
  String bmHideMsg(String date);

  /// No description provided for @healthWeightRow.
  ///
  /// In en, this message translates to:
  /// **'Weight and body fat'**
  String get healthWeightRow;

  /// No description provided for @healthWeightOn.
  ///
  /// In en, this message translates to:
  /// **'On · from your scale apps'**
  String get healthWeightOn;

  /// No description provided for @healthWeightOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get healthWeightOff;

  /// No description provided for @healthConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring in your scale measurements'**
  String get healthConsentTitle;

  /// No description provided for @healthConsentWhat.
  ///
  /// In en, this message translates to:
  /// **'Read: weight and body fat percentage that your scale apps write to Apple Health / Health Connect. Nothing else.'**
  String get healthConsentWhat;

  /// No description provided for @healthConsentWhere.
  ///
  /// In en, this message translates to:
  /// **'Stored in your Fit Pack account; servers are in the European Union (Germany).'**
  String get healthConsentWhere;

  /// No description provided for @healthConsentWhy.
  ///
  /// In en, this message translates to:
  /// **'Used only for your progress chart, weight trend and weekly review.'**
  String get healthConsentWhy;

  /// No description provided for @healthConsentNoShare.
  ///
  /// In en, this message translates to:
  /// **'Never used for ads, never sold or shared with third parties.'**
  String get healthConsentNoShare;

  /// No description provided for @healthConsentWithdraw.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw anytime in Settings → Health; imported measurements are then deleted.'**
  String get healthConsentWithdraw;

  /// No description provided for @healthConsentLegal.
  ///
  /// In en, this message translates to:
  /// **'This is your explicit consent to the processing of health data (GDPR Art. 9, KVKK Art. 6).'**
  String get healthConsentLegal;

  /// No description provided for @healthConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get healthConsentAccept;

  /// No description provided for @healthConsentDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get healthConsentDecline;

  /// No description provided for @healthWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get healthWithdrawTitle;

  /// No description provided for @healthWithdrawMsg.
  ///
  /// In en, this message translates to:
  /// **'Importing from your scale stops and the measurements already imported are deleted (also from the cloud). If you consent again later, only new measurements are imported.'**
  String get healthWithdrawMsg;

  /// No description provided for @healthWithdrawDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete measurements'**
  String get healthWithdrawDelete;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What data we process, where, and your rights'**
  String get privacySubtitle;

  /// No description provided for @privacyAuthLink.
  ///
  /// In en, this message translates to:
  /// **'How we use your data (privacy policy)'**
  String get privacyAuthLink;

  /// No description provided for @homeWeightTrend7d.
  ///
  /// In en, this message translates to:
  /// **'7-day trend'**
  String get homeWeightTrend7d;

  /// No description provided for @bmTrendLegend.
  ///
  /// In en, this message translates to:
  /// **'dots: daily · line: trend'**
  String get bmTrendLegend;

  /// No description provided for @adaptiveTdeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your actual expenditure (estimate)'**
  String get adaptiveTdeeTitle;

  /// No description provided for @adaptiveTdeeValue.
  ///
  /// In en, this message translates to:
  /// **'~{kcal} kcal/day · from {days} completed days and your weight trend'**
  String adaptiveTdeeValue(int kcal, int days);

  /// No description provided for @adaptiveTdeeAtGoal.
  ///
  /// In en, this message translates to:
  /// **'With your {goal} kcal goal: about {change} per week'**
  String adaptiveTdeeAtGoal(int goal, String change);

  /// No description provided for @adaptiveTdeeNeedDays.
  ///
  /// In en, this message translates to:
  /// **'Needs {need} days marked complete in the last 4 weeks (you have {have}).'**
  String adaptiveTdeeNeedDays(int need, int have);

  /// No description provided for @adaptiveTdeeNeedWeighIns.
  ///
  /// In en, this message translates to:
  /// **'Needs at least {count} weigh-ins spread over {days} days.'**
  String adaptiveTdeeNeedWeighIns(int count, int days);

  /// No description provided for @adaptiveTdeeInconsistent.
  ///
  /// In en, this message translates to:
  /// **'Logs look incomplete for an estimate — check that completed days are fully logged.'**
  String get adaptiveTdeeInconsistent;

  /// No description provided for @adaptiveTdeeNote.
  ///
  /// In en, this message translates to:
  /// **'Estimate (1 kg ≈ 7,700 kcal). Your goal is not changed automatically.'**
  String get adaptiveTdeeNote;

  /// No description provided for @healthWriteWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Save workouts to Health'**
  String get healthWriteWorkouts;

  /// No description provided for @healthWriteWorkoutsNote.
  ///
  /// In en, this message translates to:
  /// **'Live sessions appear in Apple Health / Health Connect (time and name; no calories).'**
  String get healthWriteWorkoutsNote;

  /// No description provided for @expDraftError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your workout in progress. Try again.'**
  String get expDraftError;

  /// No description provided for @expFirstMeal.
  ///
  /// In en, this message translates to:
  /// **'Today 0 / {goal} kcal'**
  String expFirstMeal(String goal);

  /// No description provided for @expPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your goal — adjust freely. You can change these anytime in Profile.'**
  String get expPlanSubtitle;

  /// No description provided for @expMeasurementError.
  ///
  /// In en, this message translates to:
  /// **'Could not change the measurement. Try again.'**
  String get expMeasurementError;

  /// No description provided for @expAuthConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet and try again.'**
  String get expAuthConnection;

  /// No description provided for @expAuthCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get expAuthCredentials;

  /// No description provided for @expAuthUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email before signing in.'**
  String get expAuthUnconfirmed;

  /// No description provided for @expAuthExists.
  ///
  /// In en, this message translates to:
  /// **'An account already uses this email. Try signing in.'**
  String get expAuthExists;

  /// No description provided for @expAuthRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get expAuthRateLimit;

  /// No description provided for @expAuthPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a different password with at least 6 characters.'**
  String get expAuthPassword;

  /// No description provided for @expAuthGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Try again.'**
  String get expAuthGeneric;

  /// No description provided for @expConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get expConfirmTitle;

  /// No description provided for @expConfirmHelp.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and spam folder. If you opened the link on another device, return here and sign in. You can also continue with Google.'**
  String get expConfirmHelp;

  /// No description provided for @expResend.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get expResend;

  /// No description provided for @expChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get expChangeEmail;

  /// No description provided for @expEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent.'**
  String get expEmailSent;

  /// No description provided for @expAmountDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease amount'**
  String get expAmountDecrease;

  /// No description provided for @expAmountIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase amount'**
  String get expAmountIncrease;

  /// No description provided for @expAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expAmount;

  /// No description provided for @expUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get expUpdate;

  /// No description provided for @expBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get expBarcode;

  /// No description provided for @expCreateFood.
  ///
  /// In en, this message translates to:
  /// **'Create your own food'**
  String get expCreateFood;

  /// No description provided for @expYesterdayMeal.
  ///
  /// In en, this message translates to:
  /// **'Add yesterday’s meal'**
  String get expYesterdayMeal;

  /// No description provided for @expProteinRemaining.
  ///
  /// In en, this message translates to:
  /// **'{grams} g protein left'**
  String expProteinRemaining(String grams);

  /// No description provided for @expTodayLeftBoth.
  ///
  /// In en, this message translates to:
  /// **'Today: {protein} g protein and {kcal} kcal left.'**
  String expTodayLeftBoth(String protein, String kcal);

  /// No description provided for @expTodayLeftProtein.
  ///
  /// In en, this message translates to:
  /// **'Today: {protein} g protein left.'**
  String expTodayLeftProtein(String protein);

  /// No description provided for @expTodayLeftKcal.
  ///
  /// In en, this message translates to:
  /// **'Today: {kcal} kcal left.'**
  String expTodayLeftKcal(String kcal);

  /// No description provided for @asExitMsg2.
  ///
  /// In en, this message translates to:
  /// **'If you save, pick up where you left off from the Continue card on Home. The rest timer and lock screen card stop.'**
  String get asExitMsg2;

  /// No description provided for @asSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and exit'**
  String get asSaveAndExit;

  /// No description provided for @asDiscardAndExit.
  ///
  /// In en, this message translates to:
  /// **'Discard and exit'**
  String get asDiscardAndExit;

  /// No description provided for @asDraftSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the workout — try again before leaving'**
  String get asDraftSaveError;

  /// No description provided for @asFinishIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish workout?'**
  String get asFinishIncompleteTitle;

  /// No description provided for @asFinishIncompleteMsg.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set isn\'t done.} other{{count} sets aren\'t done.}} Entered values are saved, empty sets are skipped.'**
  String asFinishIncompleteMsg(int count);

  /// No description provided for @asFinishAnyway.
  ///
  /// In en, this message translates to:
  /// **'Finish with completed'**
  String get asFinishAnyway;

  /// No description provided for @asEnterValueFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter this set\'s value first'**
  String get asEnterValueFirst;

  /// No description provided for @asSuggestWithPrev.
  ///
  /// In en, this message translates to:
  /// **'✓ logs {value} · last time {prev}'**
  String asSuggestWithPrev(String value, String prev);

  /// No description provided for @asPrevOnly.
  ///
  /// In en, this message translates to:
  /// **'Last time {prev}'**
  String asPrevOnly(String prev);

  /// No description provided for @asRestMinus.
  ///
  /// In en, this message translates to:
  /// **'−15 s'**
  String get asRestMinus;

  /// No description provided for @asRestPlus.
  ///
  /// In en, this message translates to:
  /// **'+15 s'**
  String get asRestPlus;

  /// No description provided for @asRestMinusHint.
  ///
  /// In en, this message translates to:
  /// **'Shorten rest by 15 seconds'**
  String get asRestMinusHint;

  /// No description provided for @asRestPlusHint.
  ///
  /// In en, this message translates to:
  /// **'Extend rest by 15 seconds'**
  String get asRestPlusHint;

  /// No description provided for @asRestStarted.
  ///
  /// In en, this message translates to:
  /// **'Rest started, {time}'**
  String asRestStarted(String time);

  /// No description provided for @asSemCompleteSet.
  ///
  /// In en, this message translates to:
  /// **'Complete set {n}: {value}'**
  String asSemCompleteSet(int n, String value);

  /// No description provided for @asSemCompleteSetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Complete set {n}'**
  String asSemCompleteSetEmpty(int n);

  /// No description provided for @asSemUndoSet.
  ///
  /// In en, this message translates to:
  /// **'Set {n} done. Tap to undo'**
  String asSemUndoSet(int n);

  /// No description provided for @asSemField.
  ///
  /// In en, this message translates to:
  /// **'Set {n} {field}'**
  String asSemField(int n, String field);

  /// No description provided for @asSemSuggestion.
  ///
  /// In en, this message translates to:
  /// **'suggested {value}'**
  String asSemSuggestion(String value);

  /// No description provided for @asSemSetOptions.
  ///
  /// In en, this message translates to:
  /// **'Set {n}, {type}. Set type and RPE'**
  String asSemSetOptions(int n, String type);

  /// No description provided for @asSetOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String asSetOptionsTitle(int n);

  /// No description provided for @asTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get asTypeNormal;

  /// No description provided for @asTypeWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get asTypeWarmup;

  /// No description provided for @asTypeDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get asTypeDrop;

  /// No description provided for @asTypeFailure.
  ///
  /// In en, this message translates to:
  /// **'To failure'**
  String get asTypeFailure;

  /// No description provided for @asSetType.
  ///
  /// In en, this message translates to:
  /// **'Set type'**
  String get asSetType;

  /// No description provided for @asKbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get asKbNext;

  /// No description provided for @asKbDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get asKbDone;

  /// No description provided for @today3aFinishedKicker.
  ///
  /// In en, this message translates to:
  /// **'DONE TODAY'**
  String get today3aFinishedKicker;

  /// No description provided for @today3aFinishedSub.
  ///
  /// In en, this message translates to:
  /// **'Saved · {mins} min'**
  String today3aFinishedSub(int mins);

  /// No description provided for @today3aFinishedSubNoTime.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get today3aFinishedSubNoTime;

  /// No description provided for @today3aViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View summary'**
  String get today3aViewSummary;

  /// No description provided for @today3aTrainAnyway.
  ///
  /// In en, this message translates to:
  /// **'Train anyway'**
  String get today3aTrainAnyway;

  /// No description provided for @today3aAddMealHint.
  ///
  /// In en, this message translates to:
  /// **'Add meal: {meal}'**
  String today3aAddMealHint(String meal);

  /// No description provided for @prog3cSegTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get prog3cSegTraining;

  /// No description provided for @prog3cSegBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get prog3cSegBody;

  /// No description provided for @prog3cSegWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get prog3cSegWeek;

  /// No description provided for @prog3cSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress section'**
  String get prog3cSegmentLabel;

  /// No description provided for @prog3cTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Main lifts'**
  String get prog3cTopTitle;

  /// No description provided for @prog3cTopNote.
  ///
  /// In en, this message translates to:
  /// **'Daily best estimated 1RM · last 8 weeks'**
  String get prog3cTopNote;

  /// No description provided for @prog3cE1rm.
  ///
  /// In en, this message translates to:
  /// **'est. 1RM'**
  String get prog3cE1rm;

  /// No description provided for @prog3cLatest.
  ///
  /// In en, this message translates to:
  /// **'latest {value}'**
  String prog3cLatest(String value);

  /// No description provided for @prog3cDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} · 4 weeks'**
  String prog3cDelta(String delta);

  /// No description provided for @prog3cNoCurve.
  ///
  /// In en, this message translates to:
  /// **'One more training day for a trend'**
  String get prog3cNoCurve;

  /// No description provided for @prog3cRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records in the last 30 days'**
  String get prog3cRecordsTitle;

  /// No description provided for @prog3cNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No new records in the last 30 days'**
  String get prog3cNoRecords;

  /// No description provided for @prog3cVolumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly volume'**
  String get prog3cVolumeTitle;

  /// No description provided for @prog3cVolumeNote.
  ///
  /// In en, this message translates to:
  /// **'Last 8 weeks · weeks without logs stay empty'**
  String get prog3cVolumeNote;

  /// No description provided for @prog3cNoData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get prog3cNoData;

  /// No description provided for @prog3cEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more workout to compare} other{{count} more workouts to compare}}'**
  String prog3cEmptyTitle(int count);

  /// No description provided for @prog3cEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Log workouts on two different days and your progress shows up here.'**
  String get prog3cEmptyMsg;

  /// No description provided for @prog3cStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Go to training'**
  String get prog3cStartWorkout;
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
