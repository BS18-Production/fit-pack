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

  /// No description provided for @whSetsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load sets'**
  String get whSetsLoadError;

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
  /// **'Remove this routine from the list? Past workouts are kept.'**
  String get rpArchiveMsg;

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

  /// No description provided for @notifWorkout.
  ///
  /// In en, this message translates to:
  /// **'Daily workout reminder'**
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
  /// **'{count} photo(s) · on this device only'**
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
  /// **'This photo has no backup; it can\'t be restored once deleted.'**
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
  /// **'Photos are stored on this device only: not backed up, not saved to your gallery, and deleted if you switch accounts.'**
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

  /// No description provided for @journalMealIdea.
  ///
  /// In en, this message translates to:
  /// **'Meal idea · illustrative photo'**
  String get journalMealIdea;

  /// No description provided for @journalSalmonSalad.
  ///
  /// In en, this message translates to:
  /// **'Salmon salad'**
  String get journalSalmonSalad;

  /// No description provided for @journalMealPhoto.
  ///
  /// In en, this message translates to:
  /// **'Illustrative photo of grilled salmon with greens, avocado and lemon'**
  String get journalMealPhoto;

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
