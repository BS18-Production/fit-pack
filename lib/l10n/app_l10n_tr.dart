// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppL10nTr extends AppL10n {
  AppL10nTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Fit Pack';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonSaved => 'Kaydedildi';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonNext => 'İleri';

  @override
  String get commonDone => 'Tamamla';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get accountErrorTitle => 'Hesap doğrulanamadı';

  @override
  String get accountErrorBody =>
      'Bu cihazdaki verinin sana ait olduğunu doğrulayamadık. Güvenlik için uygulamaya girilmedi — başka bir hesabın verisi görünebilirdi. Bağlantını kontrol edip tekrar dene.';

  @override
  String get accountConflictTitle => 'Yüklenmemiş kayıtlar var';

  @override
  String accountConflictBody(int count) {
    return 'Bu cihazda önceki hesaba ait $count kayıt henüz yüklenmedi. Yeni hesapla devam edersen bu kayıtlar silinir.';
  }

  @override
  String get accountConflictGoBack => 'Önceki hesaba geri dön';

  @override
  String get accountConflictDiscard => 'Kayıtları silip devam et';

  @override
  String get accountConflictDiscardTitle => 'Kayıtlar silinsin mi?';

  @override
  String accountConflictDiscardBody(int count) {
    return '$count kayıt kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get commonInvalidNumber => 'Geçersiz sayı';

  @override
  String commonRangeHint(String min, String max) {
    return 'Aralık: $min – $max';
  }

  @override
  String commonRangeError(String min, String max) {
    return '$min – $max aralığında olmalı';
  }

  @override
  String get commonSaveFailed => 'Kaydedilemedi, tekrar dene';

  @override
  String get commonDeleteFailed => 'Silinemedi, tekrar dene';

  @override
  String get commonUndoFailed => 'Geri alınamadı, tekrar dene';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Karbonhidrat';

  @override
  String get macroFat => 'Yağ';

  @override
  String get macroCalories => 'Kalori';

  @override
  String get macroProteinAbbr => 'P';

  @override
  String get macroCarbsAbbr => 'K';

  @override
  String get macroFatAbbr => 'Y';

  @override
  String get commonUndo => 'Geri al';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navWorkout => 'Antrenman';

  @override
  String get navNutrition => 'Beslenme';

  @override
  String get navProgress => 'İlerleme';

  @override
  String get homeStatWorkouts => 'antrenman';

  @override
  String homeStatVolume(String unit) {
    return '$unit hacim';
  }

  @override
  String get homeStart => 'Antrenmanı başlat';

  @override
  String get homeStartTitle => 'Antrenmana başla';

  @override
  String get homeStartSubtitle => 'Rutin oluştur ya da boş antrenman başlat';

  @override
  String homeUpNextSubtitle(int count, int mins) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hareket',
    );
    return '$_temp0 · ~$mins dk';
  }

  @override
  String get homeNoRoutineTitle => 'İlk antrenmanını seç';

  @override
  String get homeNoRoutineSubtitle =>
      'Hazır bir programla hemen başla ya da kendi rutinini kur.';

  @override
  String get homePickProgram => 'Hazır program seç';

  @override
  String get homeBuildRoutine => 'Kendi rutinini kur';

  @override
  String get homeFirstWeekTitle => 'İLK HAFTA';

  @override
  String homeFirstWeekProgress(int done) {
    return '$done/3 tamam';
  }

  @override
  String get homeFirstWeekWorkout => 'İlk antrenmanını bitir';

  @override
  String get homeFirstWeekMeal => 'İlk öğününü ekle';

  @override
  String get homeFirstWeekWeight => 'İlk kilonu gir';

  @override
  String homeTodayLiftIncrease(String exercise, String weight) {
    return '$exercise: bu sefer $weight dene.';
  }

  @override
  String homeTodayLiftAddRep(String exercise, String weight) {
    return '$exercise: $weight ile her sete +1 tekrar dene.';
  }

  @override
  String get homeTodayFirstMeal => 'İlk öğününü ekle.';

  @override
  String homeTodayLeftBoth(int protein, int kcal) {
    return 'Bugün $protein g protein, $kcal kcal kaldı.';
  }

  @override
  String homeTodayLeftProtein(int protein) {
    return 'Bugün $protein g protein kaldı.';
  }

  @override
  String homeTodayLeftKcal(int kcal) {
    return 'Bugün $kcal kcal kaldı.';
  }

  @override
  String get homeWeekReadyKicker => 'HAFTAN HAZIR';

  @override
  String get homeWeekReadyTitle => 'Haftalık değerlendirmen hazır';

  @override
  String get homeWeekReadyOpen => 'Aç';

  @override
  String get homeRestTitle => 'Bugün dinlenme günü';

  @override
  String homeRestNext(String name) {
    return 'Sıradaki: $name';
  }

  @override
  String get homeWorkoutAnyway => 'Yine de antrenman yap';

  @override
  String get nutritionKcalLeft => 'kcal kaldı';

  @override
  String get nutritionKcalOver => 'kcal fazla';

  @override
  String get commonToday => 'Bugün';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonRequired => 'Zorunlu';

  @override
  String get commonMustBePositive => '0\'dan büyük olmalı';

  @override
  String get commonNotNegative => 'Negatif olamaz';

  @override
  String get commonEnterName => 'Ad gir';

  @override
  String get nutritionPickDate => 'Tarih seç';

  @override
  String get nutritionAddFood => 'Yemek Ekle';

  @override
  String get nutritionLoadError => 'Beslenme kayıtları yüklenemedi';

  @override
  String get nutritionCopyYesterday => 'Dünün öğünlerini kopyala';

  @override
  String get nutritionCopyPrevDay => 'Önceki günün öğünlerini kopyala';

  @override
  String get nutritionCopyEmpty => 'Önceki günde kayıt yok';

  @override
  String nutritionCopied(int count) {
    return '$count kayıt kopyalandı';
  }

  @override
  String get nutritionCopyFailed => 'Kopyalanamadı, tekrar dene';

  @override
  String get nutritionMealMenu => 'Öğün seçenekleri';

  @override
  String get nutritionCopyFromDay => 'Başka günden kopyala';

  @override
  String nutritionCopyMealTitle(String meal) {
    return '$meal kopyala';
  }

  @override
  String get nutritionCopyPickDay => 'Hangi günden kopyalanacak?';

  @override
  String nutritionCopyNoHistory(int days) {
    return 'Son $days günde bu öğünde kayıt yok';
  }

  @override
  String get nutritionCopyEditHint => 'Miktarları değiştir, istemediğini çıkar';

  @override
  String nutritionCopyAddCount(int count) {
    return 'Ekle ($count)';
  }

  @override
  String get nutritionCopyRemove => 'Listeden çıkar';

  @override
  String get nutritionPrevDay => 'Önceki gün';

  @override
  String get nutritionNextDay => 'Sonraki gün';

  @override
  String get mealBreakfast => 'Kahvaltı';

  @override
  String get mealLunch => 'Öğle';

  @override
  String get mealDinner => 'Akşam';

  @override
  String get mealSnack => 'Atıştırma';

  @override
  String get mealSnackShort => 'Atıştırma';

  @override
  String nutritionAddTo(String meal) {
    return '$meal ekle';
  }

  @override
  String get nutritionNoEntries => 'Henüz kayıt yok';

  @override
  String get nutritionAddFailed => 'Eklenemedi, tekrar dene';

  @override
  String get nutritionOffNoResults =>
      'OpenFoodFacts\'te sonuç yok. Elle ekleyebilirsin.';

  @override
  String get nutritionMultiAddHint => 'Birden fazla ekleyebilirsin';

  @override
  String nutritionSessionAdded(int count, String name) {
    return '$count eklendi · son: $name';
  }

  @override
  String get nutritionSearchHint => 'Yemek ara…';

  @override
  String get nutritionScanBarcode => 'Barkod tara';

  @override
  String get nutritionAddCustom => 'Kendi yemeğini ekle';

  @override
  String get nutritionOffSearching => 'OpenFoodFacts aranıyor…';

  @override
  String nutritionOffSearchFor(String query) {
    return 'Paketli ürünü internette ara: \"$query\"';
  }

  @override
  String nutritionOffHeader(String query, int count) {
    return 'OpenFoodFacts · \"$query\" ($count)';
  }

  @override
  String get nutritionNoFoods => 'Yemek yok';

  @override
  String nutritionNotFound(String query) {
    return '\"$query\" bulunamadı';
  }

  @override
  String get nutritionNotInListHint => 'Listede yoksa kendin ekleyebilirsin';

  @override
  String nutritionUnitApprox(String unit, int grams) {
    return '1 $unit ≈ $grams g';
  }

  @override
  String get nutritionCustomTitle => 'Kendi yemeğin';

  @override
  String get nutritionCustomHelp =>
      'Bir birimin (örn. 1 porsiyon \"3 Yumurtalı Omlet\") değerlerini gir: kaç gram + o miktarın kcal/makrosu. /100g\'a çevrilip kaydedilir, tekrar kullanılır. Birim yoksa \"(birim yok)\" seç.';

  @override
  String get nutritionFoodName => 'Yemek adı';

  @override
  String get nutritionUnit => 'Birim';

  @override
  String get nutritionNoUnitOption => '(birim yok — sadece gram)';

  @override
  String nutritionOneUnit(String unit) {
    return '1 $unit';
  }

  @override
  String get nutritionPortionGrams => 'Porsiyon (g)';

  @override
  String nutritionUnitGramsQuestion(String unit) {
    return '1 $unit kaç gram?';
  }

  @override
  String get nutritionTotalKcal => 'Toplam kcal';

  @override
  String get nutritionAdding => 'Ekleniyor…';

  @override
  String nutritionAlreadySaved(String name) {
    return '$name (zaten kayıtlı)';
  }

  @override
  String get nutritionOffQuerying => 'OpenFoodFacts sorgulanıyor…';

  @override
  String nutritionProductNotFound(String code) {
    return 'Ürün bulunamadı ($code). Elle ekleyebilirsin.';
  }

  @override
  String nutritionAddedFromOff(String name) {
    return '$name eklendi (OpenFoodFacts)';
  }

  @override
  String get scanTitle => 'Barkod Tara';

  @override
  String get scanTorchOn => 'Fener';

  @override
  String get scanTorchOff => 'Feneri kapat';

  @override
  String get scanPermissionDenied =>
      'Kamera izni verilmedi. Ayarlar\'dan izin ver veya yemeği elle ekle.';

  @override
  String get scanCameraError => 'Kamera açılamadı. Yemeği elle ekleyebilirsin.';

  @override
  String get scanFrameHint => 'Barkodu çerçeveye getir';

  @override
  String get scanManualAdd => 'Elle ekle';

  @override
  String get foodsNew => 'Yeni yemek';

  @override
  String get foodCatMeat => 'Et, balık, yumurta';

  @override
  String get foodCatDairy => 'Süt ürünleri';

  @override
  String get foodCatGrain => 'Tahıl ve nişasta';

  @override
  String get foodCatLegume => 'Baklagil';

  @override
  String get foodCatVegetable => 'Sebze';

  @override
  String get foodCatFruit => 'Meyve';

  @override
  String get foodCatFat => 'Yağ ve kuruyemiş';

  @override
  String get foodCatDish => 'Hazır yemek';

  @override
  String get foodCatOther => 'Diğer';

  @override
  String foodsAdded(String name) {
    return '$name eklendi';
  }

  @override
  String get foodsUpdated => 'Güncellendi';

  @override
  String foodsHasLogs(String name, int count) {
    return '\"$name\" için $count kayıt var — önce o kayıtları sil';
  }

  @override
  String get foodsDeleteTitle => 'Yemeği sil';

  @override
  String foodsDeleteMessage(String name) {
    return '\"$name\" besin veritabanından silinsin mi?';
  }

  @override
  String foodsDeleted(String name) {
    return '$name silindi';
  }

  @override
  String get foodsPer100g => '100 g\'da';

  @override
  String get foodsReadOnlyNote =>
      'Hazır yemek — düzenlenemez (veritabanı korunur).';

  @override
  String get foodsLoadError => 'Yemekler yüklenemedi';

  @override
  String get foodsEmptyHint => 'Sağ alttan yeni yemek ekleyebilirsin';

  @override
  String get foodsEditTitle => 'Yemeği düzenle';

  @override
  String get foodsFormHelp =>
      'Değerler 100 gram için girilir. Birim seçersen \"1 birim kaç gram\" de yaz — loglarken adet/dilim ile girebilirsin.';

  @override
  String get foodsKcalPer100 => 'Kalori /100g (kcal)';

  @override
  String get foodsProteinPer100 => 'Protein /100g (g)';

  @override
  String get foodsCarbPer100 => 'Karbonhidrat /100g (g)';

  @override
  String get foodsFatPer100 => 'Yağ /100g (g)';

  @override
  String get commonYesterday => 'Dün';

  @override
  String get commonDate => 'Tarih';

  @override
  String get commonArchive => 'Arşivle';

  @override
  String get commonNone => 'Yok';

  @override
  String get unitMinShort => 'dk';

  @override
  String get unitReps => 'tekrar';

  @override
  String get labelSets => 'Set';

  @override
  String get labelReps => 'Tekrar';

  @override
  String get labelRest => 'Dinlenme';

  @override
  String get labelDuration => 'Süre';

  @override
  String get labelVolume => 'Hacim';

  @override
  String get workoutLoadRoutinesError => 'Rutinler yüklenemedi';

  @override
  String get workoutLibrary => 'Hareket Kütüphanesi';

  @override
  String get workoutAddPast => 'Geçmiş Antrenman Ekle';

  @override
  String get workoutHistory => 'Antrenman Geçmişi';

  @override
  String get wcalTitle => 'Antrenman takvimi';

  @override
  String get wcalEmpty => 'Bu gün antrenman kaydı yok.';

  @override
  String get wcalAddForDay => 'Bu güne antrenman ekle';

  @override
  String wcalMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu ay $count antrenman günü',
      zero: 'Bu ay antrenman yok',
    );
    return '$_temp0';
  }

  @override
  String get workoutThisWeekCaps => 'BU HAFTA';

  @override
  String get workoutTotalVolumeCaps => 'TOPLAM HACİM';

  @override
  String get workoutStartEmpty => 'Boş Antrenman Başlat';

  @override
  String get workoutNewRoutine => 'Yeni Rutin Oluştur';

  @override
  String get workoutMyRoutines => 'Rutinlerim';

  @override
  String get workoutNoRoutines => 'Henüz rutin yok';

  @override
  String get workoutNoRoutinesMsg =>
      'Kendi antrenman rutinini oluştur — hareketleri seç, hedef set ve tekrarları belirle.';

  @override
  String get workoutCreateRoutine => 'Rutin oluştur';

  @override
  String get workoutResumeTitle => 'Devam eden antrenman';

  @override
  String workoutResumeSub(int ex, int sets) {
    return '$ex hareket · $sets set';
  }

  @override
  String get workoutDraftDelete => 'Taslağı sil';

  @override
  String get workoutDraftDeleteMsg =>
      'Devam eden antrenman taslağı silinsin mi? Girdiğin setler kaydedilmeyecek.';

  @override
  String workoutExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hareket',
    );
    return '$_temp0';
  }

  @override
  String workoutSetCount(int count) {
    return '$count set';
  }

  @override
  String get exploreTitle => 'Keşfet';

  @override
  String get exSubtitle =>
      'Hazır programlar — ekle, rutinleri senin olsun, istediğin gibi düzenle.';

  @override
  String get exLevelBeginner => 'Başlangıç';

  @override
  String get exLevelIntermediate => 'Orta';

  @override
  String get exLevelAdvanced => 'İleri';

  @override
  String get exSplitFullBody => 'Tüm vücut';

  @override
  String get exSplitUpperLower => 'Üst / Alt';

  @override
  String get exSplitPpl => 'İtme · Çekme · Bacak';

  @override
  String get exSplitFullBodyDesc =>
      'Her seansta tüm vücut. Kısa ve verimli — haftada 3 gün çalışana ideal.';

  @override
  String get exSplitUpperLowerDesc =>
      'Üst ve alt vücut sırayla. Kas başına daha çok hacim, haftada 4 gün.';

  @override
  String get exSplitPplDesc =>
      'İtme, çekme ve bacak ayrı günlerde. Klasik vücut geliştirme bölünmesi.';

  @override
  String get exLevelBeginnerDesc =>
      'Ağırlıklı makineler, orta tekrar — hareketleri güvenle öğren.';

  @override
  String get exLevelIntermediateDesc =>
      'Barbell temelleri + yardımcı hareketler, çift ilerleme.';

  @override
  String get exLevelAdvancedDesc =>
      'Ağır ve düşük tekrarlı ana hareketler, yüksek haftalık hacim.';

  @override
  String exDaysPerWeek(int count) {
    return 'Haftada $count gün';
  }

  @override
  String exRoutineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutin',
    );
    return '$_temp0';
  }

  @override
  String exProgramTitle(String split, String level) {
    return '$split · $level';
  }

  @override
  String get exAddProgram => 'Programı ekle';

  @override
  String get exAddAgainTitle => 'Zaten rutinlerinde';

  @override
  String get exAddAgainMsg =>
      'Bu programın rutinleri listende var. Bir kopya daha eklensin mi?';

  @override
  String get exAddAgain => 'Yine de ekle';

  @override
  String exAdded(String name) {
    return '$name rutinlerine eklendi';
  }

  @override
  String get exAddError => 'Program eklenemedi — tekrar dene';

  @override
  String get exHowTo =>
      'Rutinleri sırayla dönüştür, örn. A → B → A. Hedefler başlangıç noktası; uygulama setlerine göre sonraki adımı önerir.';

  @override
  String get exFreeWorkout => 'Serbest antrenman';

  @override
  String get exInList => 'Rutinlerinde';

  @override
  String get exRoutineFullBodyA => 'Tüm Vücut A';

  @override
  String get exRoutineFullBodyB => 'Tüm Vücut B';

  @override
  String get exRoutineFullBodyC => 'Tüm Vücut C';

  @override
  String get exRoutineUpper => 'Üst Vücut';

  @override
  String get exRoutineLower => 'Alt Vücut';

  @override
  String get exRoutineUpperA => 'Üst A';

  @override
  String get exRoutineLowerA => 'Alt A';

  @override
  String get exRoutineUpperB => 'Üst B';

  @override
  String get exRoutineLowerB => 'Alt B';

  @override
  String get exRoutineUpperPower => 'Üst · Güç';

  @override
  String get exRoutineLowerPower => 'Alt · Güç';

  @override
  String get exRoutineUpperHypertrophy => 'Üst · Hacim';

  @override
  String get exRoutineLowerHypertrophy => 'Alt · Hacim';

  @override
  String get exRoutinePush => 'İtme';

  @override
  String get exRoutinePull => 'Çekme';

  @override
  String get exRoutineLegs => 'Bacak';

  @override
  String get workoutOwnRoutines => 'Kendi rutinlerim';

  @override
  String get whRecentTitle => 'Son antrenmanlar';

  @override
  String get whSeeAll => 'Tümünü gör';

  @override
  String whMoreExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count hareket daha',
    );
    return '$_temp0';
  }

  @override
  String whRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekor',
    );
    return '$_temp0';
  }

  @override
  String whVsLast(String value) {
    return 'Geçen sefere göre: $value';
  }

  @override
  String whDeltaReps(String delta) {
    return '$delta tekrar';
  }

  @override
  String get whDeltaSame => 'geçen seferle aynı';

  @override
  String get whMuscles => 'Çalışan kaslar';

  @override
  String get whAvgRpe => 'Ort. RPE';

  @override
  String get whNotes => 'Not';

  @override
  String whSetsWithRpe(String rpe) {
    return 'RPE $rpe';
  }

  @override
  String get whRpeLegend =>
      'RPE = Algılanan Zorluk Derecesi; 10 = son tekrar, daha fazlası yok.';

  @override
  String get workoutAddExercise => 'Hareket Ekle';

  @override
  String get rbEditTitle => 'Rutini Düzenle';

  @override
  String get rbNewTitle => 'Yeni Rutin';

  @override
  String get rbNameCaps => 'RUTİN ADI';

  @override
  String get rbNameHint => 'örn. Push Day';

  @override
  String get rbNoExercises => 'Henüz hareket yok';

  @override
  String get rbWeekday => 'Haftalık gün (opsiyonel)';

  @override
  String get rbWeekdayHelper => 'Atarsan ana sayfa o gün bu rutini önerir';

  @override
  String get rbNoDay => 'Gün atama';

  @override
  String get rbRestBetweenSets => 'Setler arası dinlenme';

  @override
  String get rbNameRequired => 'Rutine bir ad ver';

  @override
  String get rbNeedExercise => 'En az bir hareket ekle';

  @override
  String get rbSaveError => 'Rutin kaydedilemedi — tekrar dene';

  @override
  String get rbTargetHint => 'hedef set×tekrar';

  @override
  String get rbSave => 'Rutini Kaydet';

  @override
  String get whLoadError => 'Geçmiş yüklenemedi';

  @override
  String get whEmptyTitle => 'Henüz antrenman yok';

  @override
  String get whEmptyMsg => 'İlk antrenmanını tamamladığında burada görünecek';

  @override
  String get whEditDate => 'Tarihi düzenle';

  @override
  String get whDeleteTitle => 'Antrenmanı sil';

  @override
  String get whDeleteMsg => 'Bu seans ve tüm setleri silinecek. Geri alınamaz.';

  @override
  String get whNoSets => 'Set kaydı yok';

  @override
  String get whCalorieNote =>
      'Kalori tahminidir — kilo, süre ve yoğunluğa (RPE) dayanır.';

  @override
  String get wsTitle => 'Antrenman Özeti';

  @override
  String get wsLoadError => 'Özet yüklenemedi';

  @override
  String get wsDone => 'Antrenman Tamamlandı';

  @override
  String get wsExercises => 'Hareketler';

  @override
  String wsNewRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni rekor',
    );
    return '$_temp0';
  }

  @override
  String get wsDoneBtn => 'Bitti';

  @override
  String get wsUnknownExercise => 'Hareket';

  @override
  String get rpFallback => 'Rutin';

  @override
  String get rpArchiveTitle => 'Rutini arşivle';

  @override
  String get rpArchiveMsg =>
      'Antrenman sekmesinin altındaki Arşiv\'e taşınır; istediğin zaman geri alabilirsin. Geçmiş antrenmanlar korunur.';

  @override
  String get rpArchived => 'Rutin arşivlendi';

  @override
  String workoutArchiveSection(int count) {
    return 'Arşiv ($count)';
  }

  @override
  String get workoutArchiveRestore => 'Geri al';

  @override
  String workoutArchiveRestored(String name) {
    return '$name rutinlerine geri döndü';
  }

  @override
  String get workoutArchiveHint =>
      'Arşivdeki rutinler listede ve haftalık planda görünmez. Geçmiş antrenmanlar geçmişte kalır.';

  @override
  String get rpStart => 'Antrenmana Başla';

  @override
  String get rpLoadError => 'Rutin yüklenemedi';

  @override
  String get rpEmptyTitle => 'Bu rutin boş';

  @override
  String get rpEmptyMsg => 'Düzenle ile hareket ekle';

  @override
  String get asPastWorkout => 'Geçmiş Antrenman';

  @override
  String get asEmptyWorkout => 'Boş Antrenman';

  @override
  String liveSetLabel(int n, int total) {
    return 'Set $n/$total';
  }

  @override
  String get liveAllDone => 'Tüm setler tamam';

  @override
  String get liveRestOver => 'Dinlenme bitti';

  @override
  String get liveNext => 'Sıradaki';

  @override
  String get liveCompleteSet => 'Seti tamamla';

  @override
  String get liveAddRest => '+15 sn';

  @override
  String get liveSkipRest => 'Atla';

  @override
  String get liveElapsed => 'Süre';

  @override
  String get asPastEntry => 'Geçmiş kayıt';

  @override
  String asSetProgress(int done, int total) {
    return '$done/$total set';
  }

  @override
  String get asFinish => 'Bitir';

  @override
  String get asExitTitle => 'Antrenmandan çık?';

  @override
  String get asExitMsg => 'Girdiğin setler kaydedilmeyecek.';

  @override
  String get asKeepGoing => 'Devam et';

  @override
  String get asLeave => 'Çık';

  @override
  String get asRemoveExercise => 'Hareketi kaldır';

  @override
  String asRemoveExerciseMsg(String name) {
    return '$name ve girdiğin setler silinecek.';
  }

  @override
  String get asRemove => 'Kaldır';

  @override
  String get asNeedOneSet => 'Önce en az bir set gir';

  @override
  String get asNewRecord => 'Yeni rekor';

  @override
  String get asSaveError => 'Antrenman kaydedilemedi — tekrar dene';

  @override
  String get asStartFromLibrary => 'Kütüphaneden hareket ekleyerek başla';

  @override
  String get asAddSet => 'Set Ekle';

  @override
  String get asRemoveSet => 'Çıkar';

  @override
  String get asHowTo => 'Nasıl yapılır';

  @override
  String get asExerciseOptions => 'Hareket seçenekleri';

  @override
  String get asSkip => 'Atla';

  @override
  String get hdrSet => 'SET';

  @override
  String get hdrPrev => 'ÖNCEKİ';

  @override
  String get hdrKg => 'KG';

  @override
  String get hdrReps => 'TEKRAR';

  @override
  String get hdrTime => 'SÜRE';

  @override
  String get hdrDistance => 'MESAFE';

  @override
  String get rpeTitle => 'RPE — Algılanan Zorluk';

  @override
  String get rpeHelp =>
      'Seti yaparken ne kadar zorlandığını 1-10 arası kendin puanlarsın. \"Kaç tekrar daha yapabilirdin?\" sorusuna dayanır. Opsiyoneldir — boş bırakabilirsin.';

  @override
  String get rpe10 => 'Son tekrar — bir tane daha yapamazdın';

  @override
  String get rpe9 => '1 tekrar daha yapabilirdin';

  @override
  String get rpe8 => '2 tekrar rezervde kaldı';

  @override
  String get rpe7 => '3-4 tekrar rezerv';

  @override
  String get rpe6 => 'Rahat / ısınma seti';

  @override
  String rpePick_title(int set) {
    return 'Set $set RPE';
  }

  @override
  String get rpePick_select => 'RPE seç';

  @override
  String get rpePick_done => 'Tamam';

  @override
  String get rpePick_clear => 'Temizle';

  @override
  String get rpeEffort_light => 'Hafif efor';

  @override
  String get rpeEffort_moderate => 'Orta efor';

  @override
  String get rpeEffort_vigorous => 'Zorlayıcı efor';

  @override
  String get rpeEffort_veryHard => 'Çok zor';

  @override
  String get rpeEffort_extremelyHard => 'Aşırı zor';

  @override
  String get rpeEffort_max => 'Maksimum efor';

  @override
  String get rpeRir_none => 'Bir tekrar daha yapamazdın';

  @override
  String rpeRir_exact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tekrar daha yapabilirdin',
    );
    return '$_temp0';
  }

  @override
  String rpeRir_range(int min, int max) {
    return '$min–$max tekrar daha yapabilirdin';
  }

  @override
  String rpeRir_atLeast(int count) {
    return '$count+ tekrar daha yapabilirdin';
  }

  @override
  String get rbAddWarmUp => 'Isınma ekle';

  @override
  String get rbAddWarmUpHint => 'Başa tüm vücut dinamik ısınma koyar';

  @override
  String get rbWarmUpMissing => 'Isınma hareketi kütüphanede bulunamadı';

  @override
  String rpSetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count set',
    );
    return '$_temp0';
  }

  @override
  String get asTimerStart => 'Sayacı başlat';

  @override
  String get asTimerStop => 'Sayacı durdur';

  @override
  String get elPickTitle => 'Hareket Seç';

  @override
  String get elSearchHint => 'Hareket ara…';

  @override
  String get elRecent => 'Son kullandıkların';

  @override
  String get elLoadError => 'Hareketler yüklenemedi';

  @override
  String get elNotFoundTitle => 'Hareket bulunamadı';

  @override
  String get elFilterHint => 'Filtreyi değiştir ya da yeni hareket ekle';

  @override
  String get elNew => 'Yeni Hareket';

  @override
  String get elAdded => 'Hareket eklendi';

  @override
  String get elNameLabel => 'Hareket adı (örn. Cable Row)';

  @override
  String get elCategory => 'Kategori';

  @override
  String get elPrimaryMuscle => 'Ana kas';

  @override
  String get elEquipment => 'Ekipman';

  @override
  String get elMeasureType => 'Ölçüm tipi';

  @override
  String get measureWeightReps => 'ağırlık × tekrar';

  @override
  String get measureReps => 'tekrar';

  @override
  String get measureTime => 'süre';

  @override
  String get measureDistance => 'mesafe';

  @override
  String get edFallbackTitle => 'Hareket';

  @override
  String get edArchiveTitle => 'Hareketi arşivle';

  @override
  String edArchiveMsg(String name) {
    return '$name kütüphaneden kaldırılsın mı? Geçmiş kayıtlar korunur.';
  }

  @override
  String get edTabHow => 'Nasıl';

  @override
  String get edTabHistory => 'Geçmiş';

  @override
  String get edTabChart => 'Grafik';

  @override
  String get edTabRecords => 'Rekorlar';

  @override
  String get edMusclesWorked => 'Çalışan Kaslar';

  @override
  String get edPrimary => 'Birincil';

  @override
  String get edSecondary => 'İkincil';

  @override
  String get edNoInstructions => 'Talimat yok';

  @override
  String get edNoInstructionsMsg =>
      'Bu hareket için adım adım açıklama bulunmuyor';

  @override
  String get edHowTo => 'Nasıl Yapılır';

  @override
  String get edLevelBeginner => 'Başlangıç';

  @override
  String get edLevelIntermediate => 'Orta';

  @override
  String get edLevelExpert => 'İleri';

  @override
  String get edForcePush => 'İtme';

  @override
  String get edForcePull => 'Çekme';

  @override
  String get edForceStatic => 'Statik';

  @override
  String get edLoadError => 'Yüklenemedi';

  @override
  String get edAppearsHere =>
      'Bu hareketi bir antrenmanda kullanınca burada görünür';

  @override
  String get edSetHistory => 'Set geçmişi';

  @override
  String get edChartEmpty => 'Grafik için yeterli veri yok';

  @override
  String get edChartEmptyMsg =>
      'En az iki kez ağırlık×tekrar girince ilerleme grafiği çıkar';

  @override
  String get edE1rmTitle => 'Tahmini 1RM gelişimi';

  @override
  String get edEpley => 'Epley: ağırlık × (1 + tekrar/30)';

  @override
  String get edNoPr => 'Henüz rekor yok';

  @override
  String get edNoPrMsg =>
      'Ağırlık×tekrar girince kişisel rekorların burada toplanır';

  @override
  String get edBestE1rm => 'Tahmini 1RM';

  @override
  String get edHeaviest => 'En ağır set';

  @override
  String get edTotalLogs => 'Toplam kayıt';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti';

  @override
  String get commonCloseApp => 'Uygulamayı Kapat';

  @override
  String get bmAddMeasurement => 'Ölçüm Ekle';

  @override
  String get bmLoadError => 'Ölçümler yüklenemedi';

  @override
  String get bmEmptyTitle => 'Henüz ölçüm yok';

  @override
  String get bmEmptyMsg => 'İlk vücut ölçümünü ekleyerek ilerlemeni takip et';

  @override
  String get bmAddFirst => 'İlk ölçümünü ekle';

  @override
  String get bmPastMeasurements => 'Geçmiş Ölçümler';

  @override
  String get bmDeleteTitle => 'Ölçümü sil';

  @override
  String bmDeleteMsg(String date) {
    return '$date tarihli ölçüm silinsin mi?';
  }

  @override
  String get bmWeightTrend => 'Kilo Trendi';

  @override
  String bmGoalLine(String value) {
    return 'Hedef $value';
  }

  @override
  String get bmLatest => 'Son Ölçümler';

  @override
  String get bmWeight => 'Kilo';

  @override
  String bmDiffSince(String date) {
    return '$date ölçümüne göre';
  }

  @override
  String get bmWaist => 'Bel';

  @override
  String get bmArm => 'Kol';

  @override
  String get bmChest => 'Göğüs';

  @override
  String get bmHip => 'Kalça';

  @override
  String get bmNeck => 'Boyun';

  @override
  String get bmBodyFat => 'Yağ Oranı';

  @override
  String get bmNeedOneValue => 'En az bir değer gir';

  @override
  String get bmSaveFailed => 'Kaydedilemedi, tekrar dene';

  @override
  String get bmNewMeasurement => 'Yeni Ölçüm';

  @override
  String get bmSheetSubtitle => 'Boş bıraktığın alan kaydedilmez';

  @override
  String get actTitle => 'Aktivite';

  @override
  String get actLoadError => 'Takvim yüklenemedi';

  @override
  String get actNoEntry => 'Bu gün için kayıt yok.';

  @override
  String get exTitle => 'Veri Dışa Aktar';

  @override
  String get exNoData => 'Seçilen aralıkta dışa aktarılacak veri yok';

  @override
  String get exShareFailed => 'Paylaşım başarısız oldu, tekrar dene';

  @override
  String get exHeadline => 'Verini dışa aktar, yapay zekâ ile analiz et';

  @override
  String get exFormat => 'Format';

  @override
  String get exDateRange => 'Tarih Aralığı';

  @override
  String get exWeek => '1 Hafta';

  @override
  String get exMonth => '1 Ay';

  @override
  String get exAll => 'Tümü';

  @override
  String get exScope => 'Kapsam';

  @override
  String get exScopeAll => 'Hepsi';

  @override
  String get exPreparing => 'Hazırlanıyor…';

  @override
  String get exShareBtn => 'Dışa Aktar & Paylaş';

  @override
  String get cloudSignupOk =>
      'Kayıt alındı. E-postanı doğrulayıp giriş yapabilirsin.';

  @override
  String cloudConnErr(String err) {
    return 'Bağlanılamadı: $err';
  }

  @override
  String get cloudSignIn => 'Giriş yap';

  @override
  String get cloudCreateAccount => 'Hesap oluştur';

  @override
  String get cloudIntro =>
      'Giriş yap — antrenmanların, öğünlerin ve ölçümlerin hesabına otomatik kaydedilir.';

  @override
  String get cloudEmail => 'E-posta';

  @override
  String get cloudPassword => 'Şifre (en az 6 karakter)';

  @override
  String get cloudSignInBtn => 'Giriş Yap';

  @override
  String get cloudSignUpBtn => 'Kayıt Ol';

  @override
  String get cloudGoogle => 'Google ile devam et';

  @override
  String get cloudOrEmail => 'ya da e-posta ile devam et';

  @override
  String get cloudForgot => 'Şifreni mi unuttun?';

  @override
  String get cloudForgotTitle => 'Şifreni sıfırla';

  @override
  String get cloudForgotMsg =>
      'Yeni şifre belirlemen için e-postana bir bağlantı göndereceğiz. Bağlantıyı bu cihazda aç.';

  @override
  String get cloudForgotSend => 'Bağlantı gönder';

  @override
  String get cloudForgotSent =>
      'Bu adrese ait bir hesap varsa sıfırlama bağlantısı yola çıktı.';

  @override
  String get cloudResetTitle => 'Yeni şifre belirle';

  @override
  String get cloudResetIntro =>
      'Hesabın için yeni bir şifre seç. Hemen ardından girişin yapılacak.';

  @override
  String get cloudResetNew => 'Yeni şifre (en az 6 karakter)';

  @override
  String get cloudResetRepeat => 'Yeni şifre (tekrar)';

  @override
  String get cloudResetMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get cloudResetSave => 'Şifreyi kaydet';

  @override
  String get cloudResetOk => 'Şifren güncellendi.';

  @override
  String get cloudResetCancel => 'Vazgeç ve çıkış yap';

  @override
  String get cloudNoAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get cloudHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get updateRequiredTitle => 'Güncelleme gerekli';

  @override
  String get updateRequiredBody =>
      'Bu sürüm artık desteklenmiyor. Verilerin bu telefonda güvende; güncelledikten sonra eşitlenecek.';

  @override
  String get updateRequiredAction => 'Güncelle';

  @override
  String get cloudSignOut => 'Çıkış Yap';

  @override
  String get cloudSyncNow => 'Şimdi eşitle';

  @override
  String get cloudSyncDone => 'Eşitlendi';

  @override
  String cloudSyncPending(int count) {
    return '$count kayıt hâlâ bekliyor — bağlantını kontrol et';
  }

  @override
  String get cloudSyncFailed => 'Eşitlenemedi — verilerin bu telefonda güvende';

  @override
  String get cloudDeleteAccount => 'Hesabı Sil';

  @override
  String get cloudDeleteHint =>
      'Hesabın ve bulutta saklanan verilerin kalıcı olarak silinir.';

  @override
  String get cloudDeleteTitle => 'Hesabı sil';

  @override
  String get cloudDeleteMsg =>
      'Bulut hesabın ve buluttaki yedeğin kalıcı olarak silinir. Bu cihazdaki veriler etkilenmez.';

  @override
  String get cloudDeleteConfirm2Title => 'Emin misin?';

  @override
  String get cloudDeleteConfirm2Msg =>
      'Bu son adım — sonrasında hesabın geri getirilemez.';

  @override
  String get cloudDeleted => 'Hesabın silindi';

  @override
  String cloudDeleteFailed(String error) {
    return 'Hesap silinemedi: $error';
  }

  @override
  String get unitPortion => 'porsiyon';

  @override
  String get unitPiece => 'adet';

  @override
  String get unitSlice => 'dilim';

  @override
  String get unitBowl => 'kâse';

  @override
  String get unitWaterGlass => 'su bardağı';

  @override
  String get unitCup => 'bardak';

  @override
  String get unitTablespoon => 'yemek kaşığı';

  @override
  String get unitHandful => 'avuç';

  @override
  String get unitClove => 'diş';

  @override
  String get unitScoop => 'ölçek';

  @override
  String get unitCan => 'kutu';

  @override
  String get homeInsightLabel => 'İÇGÖRÜ';

  @override
  String homeInsightMostImproved(String name) {
    return 'En çok gelişen: $name';
  }

  @override
  String get homeInsightSubtitle => 'Son 6 haftada tahmini 1RM\'in arttı';

  @override
  String get homeWaterTitle => 'Su';

  @override
  String homeWaterAmount(String current, String goal) {
    return '$current / $goal L';
  }

  @override
  String get homeWaterAdd => '+250 ml';

  @override
  String get homeWeightTitle => 'Son kilo';

  @override
  String get homeWeightEmpty => 'İlk kilonu gir';

  @override
  String get unitKg => 'kg';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsProfileNotFound => 'Profil bulunamadı';

  @override
  String get settingsProfileNotFoundHint =>
      'Uygulamayı yeniden başlatmayı dene';

  @override
  String get settingsLoadError => 'Ayarlar yüklenemedi';

  @override
  String get settingsSectionGoals => 'Hedefler';

  @override
  String get settingsSectionBody => 'Vücut';

  @override
  String get settingsSectionPreferences => 'Tercihler';

  @override
  String get settingsSectionNutrition => 'Beslenme';

  @override
  String get settingsSectionAbout => 'Hakkında';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSectionIdentity => 'Kimlik & Enerji';

  @override
  String get profileMeasurements => 'Ölçümler';

  @override
  String get profileMeasurementsSubtitle =>
      'Kilo, bel, kol — girmek için dokun';

  @override
  String get homeProfileTooltip => 'Profil';

  @override
  String get settingsLicenses => 'Açık Kaynak Lisansları';

  @override
  String get settingsAttribution => 'Açık Veri Kaynakları';

  @override
  String get settingsAttributionSubtitle =>
      'Uygulamanın üzerine kurulduğu egzersiz ve besin veritabanları';

  @override
  String get settingsFeedback => 'Geri Bildirim Gönder';

  @override
  String get settingsFeedbackSubtitle => 'Sorun bildir ya da fikir paylaş';

  @override
  String get settingsWeekStart => 'Haftanın İlk Günü';

  @override
  String get settingsUnits => 'Birimler';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsNotificationsSubtitle =>
      'Dinlenme sayacı, antrenman ve su hatırlatıcıları';

  @override
  String get notifRestTimer => 'Dinlenme sayacı bildirimi';

  @override
  String get notifRestTimerSub =>
      'Uygulama arka plandayken dinlenme bitince haber verir';

  @override
  String get notifRestSound => 'Mola sonu sesi';

  @override
  String get notifRestSoundSub =>
      'Son 3 saniye ve mola bitince bip sesi. Medya sesini kullanır, müziğin üstünde çalar.';

  @override
  String get restSoundTitle => 'Mola sesi';

  @override
  String get restSoundSheetSub =>
      'Son 3 saniyede ve mola bitince çalar. Dokun: seç ve dinle.';

  @override
  String get restSoundPreview => 'Dinle';

  @override
  String get restSoundDigitalBeep => 'Dijital bip';

  @override
  String get restSoundDigitalBeepHint => 'Kısa bipler, uzun bir başlama sesi';

  @override
  String get restSoundClassicBell => 'Klasik zil';

  @override
  String get restSoundClassicBellHint => 'Tek, net bir zil vuruşu';

  @override
  String get restSoundBoxingBell => 'Boks zili';

  @override
  String get restSoundBoxingBellHint => 'Ring zili: ding-ding-ding';

  @override
  String get restSoundSoftChime => 'Yumuşak çan';

  @override
  String get restSoundSoftChimeHint => 'Nazik, kısık bir akor';

  @override
  String get restSoundStrongAlert => 'Güçlü alarm';

  @override
  String get restSoundStrongAlertHint =>
      'Gürültülü salon için yüksek iki tonlu alarm';

  @override
  String get notifIosSoundOff => 'Fit Pack bildirim sesi kapalı';

  @override
  String get notifIosSoundOffSub =>
      'iPhone Ayarlar › Bildirimler › Fit Pack › Sesler’den aç.';

  @override
  String get notifRestIosNote =>
      'Uygulama arka plandayken mola sonu iPhone bildirimiyle gelir: telefon sessizdeyse ya da bir Odaklanma modu süzüyorsa ses çıkmaz. Uygulama açıkken ses her zaman çalar.';

  @override
  String get notifWorkout => 'Antrenman hatırlatıcı';

  @override
  String get notifWater => 'Günlük su hatırlatıcı';

  @override
  String get notifTime => 'Saat';

  @override
  String get notifPermissionDenied =>
      'Bildirim izni verilmedi — sistem ayarlarından açabilirsin.';

  @override
  String get notifRestDoneTitle => 'Dinlenme bitti';

  @override
  String get notifRestDoneBody => 'Sıradaki set zamanı';

  @override
  String get notifRestEndingTitle => 'Dinlenme 3 saniyede bitiyor';

  @override
  String get notifRestEndingBody => 'Sıradaki sete hazırlan';

  @override
  String get notifWorkoutTitle => 'Antrenman zamanı';

  @override
  String get notifWorkoutBody =>
      'Planın seni bekliyor — kısa bir seans da sayılır.';

  @override
  String get notifWorkoutSub =>
      '2 gün ara verirsen, olağan saatinde sıradaki antrenmanını hatırlatır.';

  @override
  String get notifWorkoutFallbackTime => 'Varsayılan saat';

  @override
  String get notifWorkoutFallbackTimeSub =>
      'Saat antrenman geçmişinden bulunur; geçmiş yoksa bu saat kullanılır.';

  @override
  String get notifRecallTitle => 'Sıradaki antrenmanın hazır';

  @override
  String get notifRecallTitle2 => 'Kısa bir seans da sayılır';

  @override
  String get notifRecallTitle3 => 'Bugün uygun bir gün mü?';

  @override
  String notifRecallBodyRoutine(String routine, int minutes) {
    return 'Sıradaki: $routine · ~$minutes dk';
  }

  @override
  String notifRecallBodyRoutineOnly(String routine) {
    return 'Sıradaki: $routine';
  }

  @override
  String get notifRecallBody =>
      'Rutinini seç ya da boş antrenman başlat — birkaç set de iş görür.';

  @override
  String notifMissedTitle(String routine) {
    return 'Bugün $routine günüydü';
  }

  @override
  String get notifMissedBody =>
      'Yarın da olur. Vaktin varsa kısa bir seans şimdi de sayılır.';

  @override
  String get notifFirstWeekTitle => 'İlk antrenmanına hazır mısın?';

  @override
  String notifFirstWeekBodyRoutine(String routine, int minutes) {
    return 'İlk antrenmanın hazır: $routine · ~$minutes dk';
  }

  @override
  String notifFirstWeekBodyRoutineOnly(String routine) {
    return 'İlk antrenmanın hazır: $routine';
  }

  @override
  String get notifFirstWeekBody =>
      'Hazır programlardan birini seç ya da boş antrenman başlat.';

  @override
  String get recallOfferTitle => 'Sıradaki antrenmanını hatırlatayım mı?';

  @override
  String get recallOfferBody =>
      '2 gün ara verirsen ya da planlı günü kaçırırsan, olağan saatine göre hatırlatırım (günde en fazla 2). Ayarlar → Bildirimler\'den kapatabilirsin.';

  @override
  String get recallOfferOnbTitle => 'Antrenmanlarını hatırlatayım mı?';

  @override
  String get recallOfferOnbBody =>
      'İlk antrenmanını ve 2 gün ara verdiğinde sıradakini hatırlatırım (günde en fazla 2). Ayarlar → Bildirimler\'den kapatabilirsin.';

  @override
  String get recallOfferYes => 'Evet, hatırlat';

  @override
  String get recallOfferNo => 'Şimdi değil';

  @override
  String get recallOfferEnabled => 'Tamam — 2 gün ara verirsen hatırlatacağım.';

  @override
  String get notifWaterTitle => 'Su molası';

  @override
  String get notifWaterBody => 'Şimdi bir bardak su halkanı yolda tutar.';

  @override
  String get unitsMetric => 'Metrik (kg, cm)';

  @override
  String get unitsImperial => 'İmperial (lb, ft)';

  @override
  String get attribIntro =>
      'Fit Pack şu açık veri setleri ve kütüphaneler üzerine kuruludur. Emeği geçenlere teşekkürler!';

  @override
  String get attribOffDesc =>
      'Paketli gıda besin verileri (barkod ve metin araması)';

  @override
  String get attribFedDesc =>
      'Egzersiz kütüphanesi, talimatlar ve demo fotoğrafları';

  @override
  String get attribMuscleDesc => 'Vücut kas haritası görseli';

  @override
  String attribLicense(String name) {
    return 'Lisans: $name';
  }

  @override
  String get settingsKcalGoal => 'Kalori Hedefi';

  @override
  String get settingsProteinGoal => 'Protein Hedefi';

  @override
  String get settingsHeight => 'Boy';

  @override
  String get settingsGoalWeight => 'Hedef Kilo';

  @override
  String get settingsGender => 'Cinsiyet';

  @override
  String get settingsBirthDate => 'Doğum Tarihi';

  @override
  String get settingsActivityLevel => 'Aktiflik Düzeyi';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsFoods => 'Yemekler';

  @override
  String get settingsFoodsSubtitle =>
      'Besin veritabanı — değerleri gör, düzenle, ekle';

  @override
  String get settingsCloudAccount => 'Hesap';

  @override
  String settingsCloudSignedIn(String email) {
    return '$email';
  }

  @override
  String get settingsCloudSignedInFallback => 'Giriş yapıldı';

  @override
  String get settingsCloudSignedOut =>
      'Verilerini hesabına kaydetmek için giriş yap';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Sürüm $version · Kişisel fitness takibi';
  }

  @override
  String get settingsGenderMale => 'Erkek';

  @override
  String get settingsGenderFemale => 'Kadın';

  @override
  String settingsBirthDateValue(String date, int age) {
    return '$date · $age yaş';
  }

  @override
  String get settingsPickBirthDate => 'Doğum tarihini seç';

  @override
  String get settingsDailyEnergyTitle => 'Tahmini Günlük Harcama';

  @override
  String settingsDailyEnergyValue(int total, int bmr) {
    return '~$total kcal/gün  ·  dinlenme $bmr';
  }

  @override
  String settingsDailyEnergyMissing(String fields) {
    return 'Hesaplamak için gir: $fields';
  }

  @override
  String get settingsMissingWeight => 'kilo';

  @override
  String get settingsMissingHeight => 'boy';

  @override
  String get settingsMissingBirthDate => 'doğum tarihi';

  @override
  String get settingsMissingGender => 'cinsiyet';

  @override
  String get themeSystem => 'Sistem (cihaz)';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get languageSystem => 'Sistem (cihaz)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get activitySedentary => 'Hareketsiz';

  @override
  String get activityLight => 'Az hareketli';

  @override
  String get activityModerate => 'Orta';

  @override
  String get activityActive => 'Aktif';

  @override
  String get activityVeryActive => 'Çok aktif';

  @override
  String get onbWelcomeTitle => 'Fit Pack\'e hoş geldin';

  @override
  String get onbWelcomeTagline =>
      'Antrenmanını, beslenmeni ve gelişimini tek yerde topla.';

  @override
  String get onbWelcomeHint =>
      'Birkaç hızlı soruyla planını kuralım — 1 dakikadan az sürer.';

  @override
  String get onbAboutYouTitle => 'Seni tanıyalım';

  @override
  String get onbAboutYouSubtitle =>
      'Hedef önerisi için kilon yeterli. Boy, cinsiyet ve yaşı sonra Profil\'den ekleyebilirsin.';

  @override
  String get onbCurrentWeight => 'Mevcut kilo';

  @override
  String get onbGoalWeightOptional => 'Hedef kilo (opsiyonel)';

  @override
  String get commonSelect => 'Seç';

  @override
  String get onbYourGoal => 'Hedefin';

  @override
  String get phaseCut => 'Kilo Ver';

  @override
  String get phaseCutDesc => 'Yağ yak, kası koru';

  @override
  String get phaseMaintain => 'Koru';

  @override
  String get phaseMaintainDesc => 'Mevcut formu sürdür';

  @override
  String get phaseBulk => 'Kütle Al';

  @override
  String get phaseBulkDesc => 'Kas yap, gücü artır';

  @override
  String get onbPlanReadyTitle => 'Planın hazır';

  @override
  String get onbPlanReadySubtitle =>
      'Hedefine göre önerildi — istediğin gibi değiştir. Sonradan Ayarlar\'dan da güncelleyebilirsin.';

  @override
  String get onbDailyKcal => 'Günlük kalori hedefi';

  @override
  String get onbDailyProtein => 'Günlük protein hedefi';

  @override
  String onbProjectionCut(String goal, int weeks) {
    return 'Bu tempoyla tahmini $weeks haftada $goal hedefine ulaşabilirsin.';
  }

  @override
  String onbProjectionBulk(String goal, int weeks) {
    return 'Bu tempoyla tahmini $weeks haftada $goal hedefine ulaşabilirsin.';
  }

  @override
  String get onbProjectionNote =>
      'Bu bir tahmin — gerçek ilerleme kişiden kişiye değişir.';

  @override
  String get onbStart => 'Başlayalım';

  @override
  String get onbTrainingTitle => 'Antrenmanın';

  @override
  String get onbTrainingSubtitle =>
      'İki soru — sana uygun bir programla başlayalım.';

  @override
  String get onbExperienceQ => 'Ne kadar süredir antrenman yapıyorsun?';

  @override
  String get onbExpBeginner => 'Yeni başlıyorum';

  @override
  String get onbExpSome => 'Bir süredir yapıyorum';

  @override
  String get onbExpLong => 'Uzun süredir yapıyorum';

  @override
  String get onbDaysQ => 'Haftada kaç gün antrenman yapmak istersin?';

  @override
  String get onbDays23 => '2–3 gün';

  @override
  String get onbDays4 => '4 gün';

  @override
  String get onbDays56 => '5–6 gün';

  @override
  String get onbProgramTitle => 'Senin için önerimiz';

  @override
  String get onbProgramSubtitle =>
      'Cevaplarına göre seçtik. Rutinler hesabına eklenir, sonra istediğin gibi değiştirebilirsin.';

  @override
  String get onbProgramRestNote =>
      'Başlangıçta dinlenme günü gelişimi hızlandırır — bu yüzden haftada 4 gün öneriyoruz.';

  @override
  String get onbProgramUse => 'Bu programla başla';

  @override
  String get onbProgramSkip => 'Kendim kuracağım';

  @override
  String get onbProgramSkipDesc =>
      'Rutinini sonra Antrenman sekmesinden kurarsın; hazır programlar Keşfet\'te.';

  @override
  String get onbProgramInstallError =>
      'Program eklenemedi — Antrenman → Keşfet\'ten ekleyebilirsin.';

  @override
  String get onbGoalsNumberError =>
      'Kalori ve protein hedefini sayı olarak gir';

  @override
  String get onbSaveError => 'Kaydedilemedi — tekrar dene';

  @override
  String get hintWorkout =>
      'Hazır bir programla başla ya da kendi rutinini kur.';

  @override
  String get hintNutrition =>
      'İlk öğününü ekle: yazarak ara ya da barkod okut.';

  @override
  String get hintProgress => 'İlk kilonu gir — grafiğin buradan başlar.';

  @override
  String get hintGotIt => 'Anladım';

  @override
  String get emptyRestartHint => 'Uygulamayı yeniden başlatmayı dene';

  @override
  String unitAge(int age) {
    return '$age yaş';
  }

  @override
  String workoutRoutineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutin',
    );
    return '$_temp0';
  }

  @override
  String get backupErrorInvalidFile => 'Geçerli bir Fit Pack yedeği değil.';

  @override
  String get backupErrorNewerVersion =>
      'Bu yedek daha yeni bir Fit Pack sürümüyle alınmış. Önce uygulamayı güncelle.';

  @override
  String get backupErrorSignIn => 'Önce giriş yapmalısın.';

  @override
  String exportRptRange(String start, String end) {
    return 'Aralık: $start → $end';
  }

  @override
  String exportRptGenerated(String ts) {
    return 'Oluşturulma: $ts';
  }

  @override
  String get exportRptProfile => 'Profil';

  @override
  String exportRptPhaseWeek(int phase, int week) {
    return 'Faz: $phase, Hafta: $week';
  }

  @override
  String exportRptCalorieGoal(int kcal) {
    return 'Kalori hedefi: $kcal kcal';
  }

  @override
  String exportRptProteinGoal(int g) {
    return 'Protein hedefi: $g g';
  }

  @override
  String exportRptHeight(String cm) {
    return 'Boy: $cm cm';
  }

  @override
  String exportRptGoalWeight(String kg) {
    return 'Hedef kilo: $kg kg';
  }

  @override
  String exportRptWorkoutsTitle(int count) {
    return 'Antrenmanlar ($count seans)';
  }

  @override
  String get exportRptNoWorkouts => 'Bu aralıkta antrenman yok.';

  @override
  String exportRptDuration(int min) {
    return 'Süre: $min dk';
  }

  @override
  String exportRptNote(String note) {
    return 'Not: $note';
  }

  @override
  String get exportRptWorkoutTable =>
      '| Egzersiz | Set | Kg | Tekrar | RPE | Süre | Mesafe | Tip |';

  @override
  String get exportRptSetWarmup => 'Isınma';

  @override
  String get exportRptSetDrop => 'Drop';

  @override
  String get exportRptSetFail => 'Fail';

  @override
  String exportRptRoutinesTitle(int count) {
    return 'Rutinler ($count)';
  }

  @override
  String exportRptNutritionTitle(int count) {
    return 'Beslenme ($count kayıt)';
  }

  @override
  String get exportRptNoNutrition => 'Bu aralıkta beslenme kaydı yok.';

  @override
  String exportRptDayTotal(String kcal, String p, String c, String f) {
    return 'Toplam: $kcal kcal · P ${p}g · K ${c}g · Y ${f}g';
  }

  @override
  String get exportRptNutritionTable =>
      '| Öğün | Yemek | Gram | Kcal | Protein |';

  @override
  String exportRptWaterTitle(int count) {
    return 'Su ($count gün)';
  }

  @override
  String get exportRptWaterTable => '| Tarih | ml |';

  @override
  String exportRptBodyTitle(int count) {
    return 'Vücut Ölçüleri ($count kayıt)';
  }

  @override
  String get exportRptNoBody => 'Bu aralıkta ölçüm yok.';

  @override
  String get exportRptBodyTable =>
      '| Tarih | Kilo | Bel | Göğüs | Kol | Kalça | Boyun | YY% |';

  @override
  String get authWelcomeTitle => 'Fit Pack\'e hoş geldin';

  @override
  String get authWelcomeTagline =>
      'Antrenmanın, beslenmen ve gelişimin tek yerde.';

  @override
  String get authValueWorkout => 'Rutinlerini kur, her seti kaydet';

  @override
  String get authValueNutrition => 'Kalori ve proteini gün gün takip et';

  @override
  String get authValueProgress => 'Kilonu ve ölçülerini grafikte gör';

  @override
  String get authWhyAccount =>
      'Verilerin hesabında durur — telefon değiştirsen de seninle gelir.';

  @override
  String get cloudIntroSignUp =>
      'Hesap oluştur — antrenmanların, öğünlerin ve ölçümlerin hesabına otomatik kaydedilir.';

  @override
  String get syncUpToDate => 'Verilerin güncel';

  @override
  String get syncSyncing => 'Yükleniyor…';

  @override
  String syncPendingOffline(int count) {
    return 'Kaydedildi — $count kayıt bağlantı gelince yüklenecek';
  }

  @override
  String syncPendingWaiting(int count) {
    return 'Kaydedildi — $count kayıt yüklenmeyi bekliyor';
  }

  @override
  String get signOutPendingTitle => 'Yüklenmemiş kayıtlar var';

  @override
  String signOutPendingMsg(int count) {
    return '$count kayıt henüz sunucuya yüklenmedi. Şimdi çıkarsan bir dahaki girişine kadar yüklenmezler.';
  }

  @override
  String get signOutSyncFirst => 'Önce senkron et';

  @override
  String get signOutAnyway => 'Yine de çık';

  @override
  String get signOutStillPending => 'Hâlâ yükleniyor — birazdan tekrar dene';

  @override
  String get settingsWeightIncrement => 'Kilo artışı';

  @override
  String progIncrease(String sets, int max, String inc) {
    return 'Geçen sefer: $sets — her sette $max tekrara ulaştın. Hazırsan +$inc dene.';
  }

  @override
  String progAddRep(String sets, int min, int max) {
    return 'Geçen sefer: $sets (aralık $min–$max). Her sette bir tekrar fazlasını dene.';
  }

  @override
  String progRepeat(String sets, int min) {
    return 'Geçen sefer: $sets — bazı setler $min tekrarın altında. Aynı kilolarla tekrar dene.';
  }

  @override
  String progApplyWeight(String inc) {
    return '+$inc';
  }

  @override
  String get progApplyReps => '+1 tekrar';

  @override
  String progAppliedWeight(String inc, int reps) {
    return 'Uygulandı: her sete +$inc, $reps tekrar';
  }

  @override
  String get progAppliedReps => 'Uygulandı: her sete +1 tekrar';

  @override
  String get progInfoTitle => 'Hedef nasıl belirlenir?';

  @override
  String progInfoBody(int min, int max, String inc) {
    return 'Çift ilerleme: aynı kiloda her set aralığın üstüne ($min–$max) ulaşana kadar tekrar ekle. Sonra kiloyu artır (+$inc) ve $min tekrardan yeniden başla. Düğmeye basmadıkça hiçbir şey değişmez — rutinin aynı kalır, önerilen set yapılmış sayılmaz.';
  }

  @override
  String get progInfoSettings =>
      'Artış miktarını Ayarlar → Kilo artışı\'ndan değiştirebilirsin.';

  @override
  String progIncreaseHard(String sets, int max, String inc, String rpe) {
    return 'Geçen sefer: $sets — her sette $max tekrara ulaştın; en zor set RPE $rpe. +$inc dene, ilk sette tekrar düşebilir.';
  }

  @override
  String progHoldFailure(String sets) {
    return 'Geçen sefer: $sets — en az bir set tükenişteydi (RPE 10). Tekrar eklemeden önce aynı hedefi tekrarla.';
  }

  @override
  String progDecrease(String sets, int min, String inc) {
    return 'İki seanstır $min tekrarın altında kaldın, sonuncusu tükenişte. −$inc düşür, $min tekrardan yeniden kur.';
  }

  @override
  String progApplyDecrease(String inc) {
    return '−$inc';
  }

  @override
  String progAppliedDecrease(String inc, int reps) {
    return 'Uygulandı: her sete −$inc, $reps tekrar';
  }

  @override
  String get progInfoRpe =>
      'RPE de hesaba girer: bir set tükenişteyse (RPE 10) fazladan tekrar istenmez; iki seans üst üste takılırsan bir adım kilo düşürmek önerilir.';

  @override
  String syncLastBackup(String when) {
    return 'Son yedekleme: $when';
  }

  @override
  String syncWhenToday(String time) {
    return 'bugün $time';
  }

  @override
  String syncWhenYesterday(String time) {
    return 'dün $time';
  }

  @override
  String syncLongOutage(int days) {
    return '$days gündür yedeklenemedi. Veriler bu telefonda güvende.';
  }

  @override
  String syncReplacedRows(int count) {
    return '$count kaydın buluttaki daha yeni sürümü alındı';
  }

  @override
  String syncFailedRows(int count) {
    return '$count kayıt yüklenemedi — tekrar denemek için dokun';
  }

  @override
  String get wrTitle => 'Haftalık değerlendirme';

  @override
  String wrInProgress(int days) {
    return 'Hafta sürüyor — $days günlük veriyle';
  }

  @override
  String get wrPrevWeek => 'Önceki hafta';

  @override
  String get wrNextWeek => 'Sonraki hafta';

  @override
  String get wrSummaryTitle => 'Özet';

  @override
  String wrFactWorkouts(int count) {
    return '$count antrenman';
  }

  @override
  String wrFactFoodDays(int days) {
    return '$days günde beslenme kaydı';
  }

  @override
  String get wrFactNoFood => 'beslenme kaydı yok';

  @override
  String wrFactWeightDelta(String delta) {
    return 'kilo $delta';
  }

  @override
  String get wrFactNoPrevWeight => 'önceki hafta kilo ölçümü yok';

  @override
  String get wrFactNoWeight => 'kilo ölçümü yok';

  @override
  String get wrWorkoutTitle => 'Antrenman';

  @override
  String wrWorkoutPlanned(int done, int planned) {
    return '$done/$planned planlı antrenman';
  }

  @override
  String wrWorkoutDone(int count) {
    return '$count antrenman';
  }

  @override
  String wrWorkoutDetail(int sets, int minutes, String volume) {
    return '$sets tamamlanmış set · $minutes dk · $volume hacim';
  }

  @override
  String wrWorkoutPrev(int count) {
    return 'Geçen hafta: $count antrenman';
  }

  @override
  String get wrWorkoutNone => 'Bu hafta antrenman kaydı yok';

  @override
  String wrWorkoutSource(int count) {
    return 'Kaynak: $count seans. Hacim ve seans sayısı ana sayfadakiyle aynı hesap.';
  }

  @override
  String get wrProgressTitle => 'Hareket ilerlemesi';

  @override
  String wrProgressRow(String weight, int reps, String delta) {
    return '$weight × $reps — tahmini 1TM +$delta';
  }

  @override
  String get wrProgressNone =>
      'Karşılaştırılacak önceki kayıt ya da ilerleme yok';

  @override
  String get wrProgressSource =>
      'Kaynak: bu haftanın en iyi tamamlanmış seti, hareketin bir önceki kaydıyla karşılaştırılır (Epley 1TM). Hareketler ayrı ayrı; toplam puan yok.';

  @override
  String get wrNutritionTitle => 'Beslenme';

  @override
  String wrNutritionLogged(int days) {
    return '$days gün kayıt';
  }

  @override
  String wrNutritionAvg(int kcal, int protein) {
    return 'Kayıtlı günlerin ortalaması: $kcal kcal · $protein g protein';
  }

  @override
  String wrNutritionGoal(int kcal, int protein) {
    return 'Hedef: $kcal kcal · $protein g protein';
  }

  @override
  String get wrNutritionNone => 'Bu hafta beslenme kaydı yok';

  @override
  String get wrNutritionSource =>
      'Kaynak: yalnız kayıt girilen günler. Kayıtsız gün 0 sayılmaz ve hedefe göre yorumlanmaz.';

  @override
  String get wrWeightTitle => 'Kilo';

  @override
  String wrWeightAvg(String weight, int count) {
    return 'Hafta ortalaması: $weight ($count ölçüm)';
  }

  @override
  String wrWeightDelta(String delta) {
    return 'Geçen haftaya göre $delta';
  }

  @override
  String get wrWeightSingle => 'Tek ölçüm — trend sayılmaz';

  @override
  String get wrWeightNoPrev =>
      'Önceki hafta ölçümü yok — karşılaştırma yapılamadı';

  @override
  String get wrWeightNone => 'Bu hafta kilo ölçümü yok';

  @override
  String get wrMeaningOnTrack => 'Hedefinle aynı yönde';

  @override
  String get wrMeaningAgainst =>
      'Hedefinin tersine — tek hafta tek başına sonuç değildir';

  @override
  String get wrMeaningFlat => 'Belirgin değişim yok';

  @override
  String get wrDirectionLabel => 'Kilo hedefin';

  @override
  String get wrDirLose => 'Ver';

  @override
  String get wrDirMaintain => 'Koru';

  @override
  String get wrDirGain => 'Al';

  @override
  String get wrDirectionUnset =>
      'Yön seçersen kilo değişimi ona göre yorumlanır. Seçim geçmiş haftalara uygulanmaz.';

  @override
  String get wrGoalConflict =>
      'Seçtiğin yön ile hedef kilon birbirini tutmuyor. Hedefin değiştirilmedi — Profil\'den kontrol edebilirsin.';

  @override
  String get wrGoalConflictAction => 'Profili aç';

  @override
  String get wrWeightSource =>
      'Kaynak: haftalık ortalamalar. Yön yalnız seçildiği tarihten sonraki haftalara uygulanır.';

  @override
  String get wrMuscleTitle => 'Kas grubu dağılımı';

  @override
  String wrMuscleRow(int sets) {
    return '$sets set';
  }

  @override
  String get wrMuscleNone => 'Bu hafta tamamlanmış set yok';

  @override
  String get wrMuscleSource =>
      'Kaynak: tamamlanmış, ısınma dışı setler; hareketin birincil kası. Yalnız sayım.';

  @override
  String get wrFocusTitle => 'Gelecek hafta';

  @override
  String wrFocusCompletePlan(int done, int planned) {
    return 'Planındaki $planned antrenmandan $done tanesini tamamladın — hedef planı tamamlamak.';
  }

  @override
  String wrFocusIncrease(String name) {
    return '$name 3 haftadır aynı kiloda ve tekrar aralığının üstünde — kiloyu artırmayı deneyebilirsin.';
  }

  @override
  String wrFocusLogging(int days) {
    return '$days gün beslenme kaydı var — hedef her gün kısa bir kayıt.';
  }

  @override
  String get wrFocusCalories =>
      'Kilo 2 haftadır hedefinin tersine gidiyor — kalori hedefini gözden geçirebilirsin.';

  @override
  String get wrFocusKeep => 'Aynı ritmi sürdür.';

  @override
  String get wrFocusSource =>
      'Kural: sıradaki ilk eşleşen öneri gösterilir. Öneridir; hedeflerin değişmez.';

  @override
  String get wrOpen => 'Haftalık değerlendirme';

  @override
  String get notifWeeklyReview => 'Haftalık değerlendirme';

  @override
  String notifWeeklyReviewSub(String day) {
    return 'Hafta kapanışında: $day 20:00';
  }

  @override
  String get notifWeeklyTitle => 'Haftan hazır';

  @override
  String get notifWeeklyBody =>
      'Haftanın özeti ve gelecek hafta için tek odak.';

  @override
  String get ppTitle => 'İlerleme fotoğrafları';

  @override
  String ppEntrySub(int count) {
    return '$count fotoğraf · sunucuya yüklenmez';
  }

  @override
  String get ppEntryEmpty => 'Aynadaki değişim tartıdan önce görünür';

  @override
  String get ppEmptyTitle => 'Henüz fotoğraf yok';

  @override
  String get ppEmptyMsg =>
      'Aynı açıdan, aynı ışıkta düzenli çekilen fotoğraflar değişimi tartıdan haftalar önce gösterir.';

  @override
  String get ppAdd => 'Fotoğraf ekle';

  @override
  String get ppAngleFront => 'Ön';

  @override
  String get ppAngleSide => 'Yan';

  @override
  String get ppAngleBack => 'Arka';

  @override
  String get ppAll => 'Tümü';

  @override
  String get ppCamera => 'Kamerayla çek';

  @override
  String get ppGallery => 'Galeriden seç';

  @override
  String get ppAngle => 'Açı';

  @override
  String get ppDeleteTitle => 'Fotoğraf silinsin mi?';

  @override
  String get ppDeleteMsg =>
      'Bu fotoğraf bizim sunucumuzda yedeklenmez; silinince uygulamadan geri getirilemez.';

  @override
  String get ppCompare => 'Karşılaştır';

  @override
  String get ppCompareHint => 'Karşılaştırmak için iki fotoğraf seç';

  @override
  String ppSelected(int count) {
    return '$count/2 seçildi';
  }

  @override
  String ppDaysApart(int days) {
    return '$days gün arayla';
  }

  @override
  String get ppDeviceOnly =>
      'Fotoğraflar sunucumuza yüklenmez, galeriye yazılmaz; bu telefonda saklanır. Telefonunun kendi yedeği (iCloud / Google) açıksa onun içinde de yer alır. Hesap değiştirince bu telefondan silinir.';

  @override
  String get ppLoadError => 'Fotoğraflar yüklenemedi';

  @override
  String get ppSaveError => 'Fotoğraf kaydedilemedi';

  @override
  String get ppMissingFile => 'Dosya bulunamadı';

  @override
  String get homeTitleToday => 'Bugün';

  @override
  String get homeUpNext => 'SIRADAKİ ANTRENMAN';

  @override
  String get homeTodayPlan => 'BUGÜNÜN PLANI';

  @override
  String homePlanSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hareket',
    );
    return '$_temp0 · Planlı rutin';
  }

  @override
  String get homeInProgress => 'DEVAM EDEN SEANS';

  @override
  String get homeResumeAction => 'Seansa dön';

  @override
  String get homeRhythmKicker => 'RİTMİN';

  @override
  String homeRhythmLeft(int done, int goal, int left) {
    return 'Bu hafta $done/$goal antrenman · hedefe $left kaldı';
  }

  @override
  String homeRhythmDone(int done, int goal) {
    return 'Bu haftanın hedefi tamam ($done/$goal)';
  }

  @override
  String homeRhythmEmptySub(int goal) {
    return 'Haftalık hedef: $goal antrenman · dinlenme günleri seriyi bozmaz';
  }

  @override
  String homeRhythmRestartSub(int done, int goal) {
    return 'Geçen haftanın hedefi tamamlanmadı · bu hafta $done/$goal';
  }

  @override
  String get homeLast30 => 'SON 30 GÜN';

  @override
  String get homeStatKcalEstimated => 'tahmini kcal';

  @override
  String get homeDayLog => 'Günün kaydı';

  @override
  String get calTitle => 'TAKVİM';

  @override
  String get calBackToToday => 'Bugüne dön';

  @override
  String get calPrevWeek => 'Önceki hafta';

  @override
  String get calNextWeek => 'Sonraki hafta';

  @override
  String get calPrevMonth => 'Önceki ay';

  @override
  String get calNextMonth => 'Sonraki ay';

  @override
  String get calOpenMonth => 'Ay görünümünü aç';

  @override
  String get calLegendRecord => 'Kayıt var';

  @override
  String calSelected(String date) {
    return 'Seçili: $date';
  }

  @override
  String get calDayRecords => 'Bu güne ait kayıtlar';

  @override
  String get calOpen => 'Aç';

  @override
  String calWorkoutLine(int sets, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets set',
    );
    return '$_temp0 · $volume hacim';
  }

  @override
  String calNutritionLine(int kcal, int protein) {
    return '$kcal kcal · $protein g protein';
  }

  @override
  String calWaterLine(String liters) {
    return '$liters L su';
  }

  @override
  String get asMoveUp => 'Yukarı taşı';

  @override
  String get asMoveDown => 'Aşağı taşı';

  @override
  String get asRestTitle => 'Setler arası dinlenme';

  @override
  String get asRestRoutineNote =>
      'Rutine de kaydedilir — sonraki antrenman bu süreyle başlar.';

  @override
  String get asRestSessionNote => 'Bu antrenman için geçerli.';

  @override
  String get asRestChange => 'Dinlenme süresini değiştir';

  @override
  String get asRestSaveError => 'Dinlenme süresi rutine kaydedilemedi';

  @override
  String asSuggestHint(String value) {
    return '✓ ile $value kaydedilir';
  }

  @override
  String get asStepTitle => 'Kilo adımı';

  @override
  String get asStepHelp =>
      '− ve + düğmeleri kiloyu bu kadar değiştirir. Bu hareket için hatırlanır.';

  @override
  String get asStepChange => 'Kilo adımını değiştir';

  @override
  String asStepDecrease(String step) {
    return 'Kiloyu $step azalt';
  }

  @override
  String asStepIncrease(String step) {
    return 'Kiloyu $step artır';
  }

  @override
  String get wrThisWeek => 'Bu hafta';

  @override
  String get wrHowCalculated => 'Nasıl hesaplandı?';

  @override
  String get wrKpiWorkouts => 'Antrenman';

  @override
  String get wrKpiVolume => 'Hacim';

  @override
  String get wrKpiKcal => 'Ort. kalori';

  @override
  String get wrKpiWeight => 'Ort. kilo';

  @override
  String wrPrevValue(String value) {
    return 'Geçen hafta: $value';
  }

  @override
  String wrPlannedOf(int planned) {
    return '$planned planlıdan';
  }

  @override
  String wrLoggedOf(int days, int total) {
    return '$days/$total gün kayıt';
  }

  @override
  String wrProteinAvg(int protein) {
    return '$protein g protein';
  }

  @override
  String wrGoalShort(int kcal) {
    return 'Hedef $kcal';
  }

  @override
  String wrMeasureCount(int count) {
    return '$count ölçüm';
  }

  @override
  String get wrSingleShort => 'Tek ölçüm — trend değil';

  @override
  String get wrNoPrevShort => 'Geçen hafta ölçüm yok';

  @override
  String get wrNoRecord => 'Kayıt yok';

  @override
  String wrProgressDelta(String delta) {
    return '1TM +$delta';
  }

  @override
  String get wrVsPrev => 'geçen haftaya göre';

  @override
  String get rhythmStart => 'Ritmini başlat';

  @override
  String get rhythmFirstWeek => 'İlk haftanı tamamla';

  @override
  String get rhythmFirstWeekLastOne => 'Bir antrenman daha, ilk hafta cepte';

  @override
  String get rhythmWeek1 => 'İlk hafta cepte!';

  @override
  String get rhythmWeek2 => '2 hafta üst üste, alışkanlık doğuyor';

  @override
  String get rhythmWeek3 => '3 hafta! Ritmi yakaladın';

  @override
  String get rhythmMonth1 => 'Bir ay tamam, artık bu senin rutinin';

  @override
  String get rhythmMonth2 => '2 aydır aralıksız, ciddi iş';

  @override
  String get rhythmMonth3 => '3 ay! Disiplin kazanıyor';

  @override
  String get rhythmHalfYear => 'Yarım yıl kesintisiz, efsane seri';

  @override
  String get rhythmYear1 => 'Tam 1 yıl, şapka çıkarıyoruz';

  @override
  String rhythmDoneA(int n) {
    return '$n. hafta da cepte';
  }

  @override
  String rhythmDoneB(int n) {
    return '$n haftadır durmak yok';
  }

  @override
  String rhythmDoneC(int n) {
    return 'Seri $n hafta, alev alev';
  }

  @override
  String rhythmDoneD(int n) {
    return '$n hafta, tek kopuş yok';
  }

  @override
  String rhythmOngoingA(int n) {
    return '$n haftalık seri, bu haftayı da al';
  }

  @override
  String rhythmOngoingB(int next) {
    return 'Seriyi $next. haftaya taşı';
  }

  @override
  String rhythmOngoingC(int n) {
    return '$n hafta oldu, şimdi bırakmak yok';
  }

  @override
  String rhythmOngoingLastOne(int next) {
    return 'Bir antrenman daha, seri $next. haftada';
  }

  @override
  String get rhythmRestartA => 'Yeni seri başlıyor';

  @override
  String get rhythmRestartB => 'Kaldığın yerden devam';

  @override
  String get rhythmRestartC => 'Her seri tek antrenmanla başlar';

  @override
  String get nhUsualBreakfast => 'Her zamanki kahvaltın';

  @override
  String get nhUsualLunch => 'Her zamanki öğle yemeğin';

  @override
  String get nhUsualDinner => 'Her zamanki akşam yemeğin';

  @override
  String get nhUsualSnack => 'Her zamanki ara öğünün';

  @override
  String nhUsualSub(int count, int kcal, int protein) {
    return '$count besin · $kcal kcal · $protein g protein';
  }

  @override
  String get nhUsualAdd => 'Ekle';

  @override
  String get nhUsualLater => 'Şimdi değil';

  @override
  String nhUsualAdded(String meal) {
    return '$meal eklendi';
  }

  @override
  String nhWeekStart(int goal) {
    return 'Bu hafta ilk kaydını gir · hedef $goal gün';
  }

  @override
  String nhWeekGoing(int done, int goal, int left) {
    return 'Bu hafta $done/$goal gün kayıt · $left gün daha';
  }

  @override
  String nhWeekLastOne(int done, int goal) {
    return 'Bu hafta $done/$goal gün · bir gün daha, hafta tamam';
  }

  @override
  String nhWeekDone(int done, int goal) {
    return 'Bu haftanın kayıt hedefi tamam ($done/$goal)';
  }

  @override
  String get nhQuickButton => 'Hızlı: kcal + protein';

  @override
  String get nhQuickTitle => 'Hızlı giriş';

  @override
  String get nhQuickHint =>
      'Tartamadığın öğünler için: yalnız kalori ve protein. Besin listene de eklenir, bir dahaki sefere aratıp seçebilirsin.';

  @override
  String get nhQuickName => 'Ne yedin? (isteğe bağlı)';

  @override
  String get nhQuickDefaultName => 'Hızlı giriş';

  @override
  String get nhQuickKcal => 'Kalori (kcal)';

  @override
  String get nhQuickProtein => 'Protein (g, isteğe bağlı)';

  @override
  String get nhQuickEntry => 'hızlı giriş';

  @override
  String nhQuickAdded(String name) {
    return '$name eklendi';
  }

  @override
  String get nhReminderCta =>
      'Öğünleri unutmamak için hatırlatıcı aç — girdiğin öğün için bildirim gelmez.';

  @override
  String get nhReminderEnable => 'Aç';

  @override
  String get nhReminderEnabled => 'Öğün hatırlatıcısı açıldı';

  @override
  String get notifMealLabel => 'Öğün hatırlatıcısı';

  @override
  String get notifMealSub =>
      'Öğünü girmediysen, genelde girdiğin saatten biraz sonra. Girdiysen bildirim gelmez.';

  @override
  String get notifMealBreakfastTitle => 'Kahvaltını ekledin mi?';

  @override
  String get notifMealLunchTitle => 'Öğle yemeğini ekledin mi?';

  @override
  String get notifMealDinnerTitle => 'Akşam yemeğini ekledin mi?';

  @override
  String get notifMealBody => 'Eklemek 10 saniye sürer.';

  @override
  String get notifMealBreakfastTitle2 => 'Güne bir kayıtla başla';

  @override
  String get notifMealBreakfastTitle3 => 'Sabah yakıtın ne oldu?';

  @override
  String get notifMealLunchTitle2 => 'Öğlen tabağında ne vardı?';

  @override
  String get notifMealLunchTitle3 => 'Öğle arası: 10 saniyelik kayıt';

  @override
  String get notifMealDinnerTitle2 => 'Günü kapatmadan son bir kayıt';

  @override
  String get notifMealDinnerTitle3 => 'Akşam tabağını unutma';

  @override
  String get notifMealBody2 => 'Sıcağı sıcağına girersen porsiyonu unutmazsın.';

  @override
  String get notifMealBody3 =>
      'Emin değilsen hızlı girişle tahmini kalori yaz, yeter.';

  @override
  String get notifMealBody4 => 'Bugünün tablosu bu öğünle tamamlanıyor.';

  @override
  String get notifMealBody5 => 'Ne yediğini görmek, hedefe giden yolun yarısı.';

  @override
  String get notifMealBody6 => 'Protein hedefin bu öğünü bekliyor.';

  @override
  String notifMealUsualBreakfast(String foods) {
    return 'Her zamanki kahvaltın: $foods. Tek dokunuşla ekle.';
  }

  @override
  String notifMealUsualLunch(String foods) {
    return 'Her zamanki öğle yemeğin: $foods. Tek dokunuşla ekle.';
  }

  @override
  String notifMealUsualDinner(String foods) {
    return 'Her zamanki akşam yemeğin: $foods. Tek dokunuşla ekle.';
  }

  @override
  String get notifMealWeekStart => 'Bu haftanın ilk kaydı seni bekliyor.';

  @override
  String notifMealWeekProgress(int done, int goal, int next) {
    return 'Bu hafta $done/$goal gün kayıt. Bugünü eklersen $next/$goal.';
  }

  @override
  String get notifMealWeekMet =>
      'Haftalık hedefin tamam. Bugünü de eklersen tablo eksiksiz kalır.';

  @override
  String get nhPortion => 'porsiyon';

  @override
  String get foodCatSweet => 'Tatlı ve atıştırmalık';

  @override
  String get foodCatDrink => 'İçecek';

  @override
  String get attribUsdaDesc =>
      'Temel gıdaların besin değerleri; Türk yemekleri malzemelerinden hesaplanan tahminlerdir';

  @override
  String get afScan => 'Barkod';

  @override
  String get afQuick => 'Hızlı kalori';

  @override
  String get afCustom => 'Kendi besinin';

  @override
  String get afRecent => 'Son eklediklerin';

  @override
  String afAllCount(int count) {
    return 'Tüm besinler · $count';
  }

  @override
  String afResults(int count) {
    return '$count sonuç';
  }

  @override
  String get afCatAll => 'Tümü';

  @override
  String afAdded(String name) {
    return '$name eklendi';
  }

  @override
  String afSessionCount(int count) {
    return '$count kayıt eklendi';
  }

  @override
  String get afDone => 'Bitti';

  @override
  String get afAddBreakfast => 'Kahvaltıya ekle';

  @override
  String get afAddLunch => 'Öğle yemeğine ekle';

  @override
  String get afAddDinner => 'Akşam yemeğine ekle';

  @override
  String get afAddSnack => 'Ara öğüne ekle';

  @override
  String afQuickAddTip(String portion) {
    return 'Hemen ekle: $portion';
  }

  @override
  String get afChangeMeal => 'Öğünü değiştir';

  @override
  String get afEditHint =>
      'Miktarı değiştirmek için satıra dokun, hemen eklemek için +';

  @override
  String get journalTitle => 'Bugün, bir adım ileri.';

  @override
  String get journalSubtitle => 'Performans günlüğü';

  @override
  String get journalEnergyMacros => 'Enerji ve makrolar';

  @override
  String get journalEnergyLogged => 'Alınan enerji';

  @override
  String get journalEnergyGoal => 'Günlük hedef';

  @override
  String get journalProteinRing => 'İç halka: protein';

  @override
  String get journalMeals => 'Öğün günlüğün';

  @override
  String get journalMealAdd => '+ Ekle';

  @override
  String get journalActivity => 'Antrenman aktivitesi';

  @override
  String get journalActivityPeriod => 'Son 7 gün · tahmini kcal';

  @override
  String get journalActivityEmpty => 'Son 7 günde kayıtlı antrenman yok.';

  @override
  String get journalEstimateMissing =>
      'Kalori tahmini için kilo ve süre bilgisi gerekli.';

  @override
  String get journalNoWorkout => 'Bu gün kayıtlı antrenman yok.';

  @override
  String journalActivitySessions(int count) {
    return '$count kayıtlı antrenman';
  }

  @override
  String get nutritionDailyEnergy => 'Günlük enerji';

  @override
  String get nutritionKcalRemaining => 'kcal kaldı';

  @override
  String get nutritionKcalAboveGoal => 'kcal hedef üzerinde';

  @override
  String get nutritionKcalAtGoal => 'kcal · hedefte';

  @override
  String get nutritionDiary => 'Öğün günlüğü';

  @override
  String nutritionFoodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count besin',
      one: '1 besin',
      zero: 'Kayıt yok',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDayCompleteToday => 'Bugünün tüm öğünlerini girdim';

  @override
  String get nutritionDayCompletePast => 'Bu günün tüm öğünlerini girdim';

  @override
  String get nutritionDayCompleteHint =>
      'İşaretle: haftalık değerlendirme ve asistan bu günü eksik saymaz.';

  @override
  String get nutritionDayCompleted => 'Tüm öğünler girildi';

  @override
  String get nutritionDayCompletedSub =>
      'Bu gün haftalık değerlendirmede tam sayılıyor.';

  @override
  String get nutritionDayChangedAfter => 'Tamamlandıktan sonra değişti';

  @override
  String get nutritionDayReopen => 'Geri al';

  @override
  String wrCompletedDays(int days) {
    return '$days tamamlanmış gün';
  }

  @override
  String wrExcludedDays(int days) {
    return '$days gün hesaba katılmadı';
  }

  @override
  String wrProteinHit(int hit, int total) {
    return 'Protein hedefi $hit/$total gün';
  }

  @override
  String get healthSteps => 'Adım';

  @override
  String get healthInstall => 'Health Connect\'i kur';

  @override
  String get healthSeeSteps => 'Adımlarını gör';

  @override
  String get healthNoData => 'Veri yok — Sağlık izinlerini kontrol et';

  @override
  String get healthReadError => 'Adımlar okunamadı. Yeniden dene.';

  @override
  String get healthStepGoal => 'Günlük adım hedefi';

  @override
  String get healthPermissionTitle => 'Adımların Ana Sayfa\'da';

  @override
  String get healthPermissionStepsOnly => 'Yalnız adım sayın okunur.';

  @override
  String get healthPermissionOnDevice => 'Adımların yalnız bu telefonda kalır.';

  @override
  String get healthPermissionNoSharing =>
      'Kalori hedefin değişmez, kimseyle paylaşılmaz.';

  @override
  String get healthConnect => 'Bağlan';

  @override
  String get healthNotNow => 'Şimdi değil';

  @override
  String get healthConnectError =>
      'Bağlanamadık. Sağlık izinlerini kontrol edip yeniden dene.';

  @override
  String get healthWeekTitle => 'Son 7 gün';

  @override
  String get healthRetry => 'Yeniden dene';

  @override
  String get healthNotConnected => 'Bağlı değil · adımlarını gör';

  @override
  String get healthAverage => 'Ortalama (verisi olan günler)';

  @override
  String healthStepCount(String count) {
    return '$count adım';
  }

  @override
  String get healthGoalHint => 'Boş bırak ya da 0 yaz: hedef olmasın.';

  @override
  String get healthGoalSaveError => 'Hedef kaydedilemedi. Yeniden dene.';

  @override
  String get healthSection => 'Sağlık';

  @override
  String get healthConnection => 'Adım bağlantısı';

  @override
  String get healthConnected => 'Bağlı';

  @override
  String get healthDisconnect => 'Bağlantıyı kes';

  @override
  String get healthDisconnectNote =>
      'İzni ayrıca Sağlık veya Health Connect ayarlarından kaldırabilirsin.';

  @override
  String get healthNoGoal => 'Hedef yok';

  @override
  String get healthInstallError => 'Health Connect açılamadı. Yeniden dene.';

  @override
  String get healthDisconnectError => 'Bağlantı kesilemedi. Yeniden dene.';

  @override
  String get assistantTitle => 'Verime sor';

  @override
  String get assistantSubtitle =>
      'Sayılar senin kayıtlarından. Sorunu seç, birlikte bakalım.';

  @override
  String get assistantQuestionHint => 'Bu hafta antrenmanlarım nasıldı?';

  @override
  String get assistantAsk => 'Sor';

  @override
  String get assistantReady => 'Hazır sorular';

  @override
  String get assistantAll => 'Tüm sorular';

  @override
  String get assistantLess => 'Daha az göster';

  @override
  String get assistantUnderstood => 'Anladığım soru';

  @override
  String get assistantChange => 'Değiştir';

  @override
  String get assistantApply => 'Sonucu göster';

  @override
  String get assistantPeriod => 'Dönem';

  @override
  String get assistantExercise => 'Hareket';

  @override
  String get assistantChooseExercise => 'Hareket seç';

  @override
  String get assistantInterpretation => 'Sayıların anlamını da göster';

  @override
  String get assistantMeal => 'Yemek örnekleri için öğün seç';

  @override
  String get assistantNoMeal => 'Yalnız kalan miktar';

  @override
  String get assistantPrivacyTitle => 'Sorun Google’a gönderilecek';

  @override
  String get assistantPrivacy =>
      'Yalnız yazdığın soru ve sabit soru tanımları Gemini’ye gider; antrenman, beslenme ve ölçüm kayıtların gönderilmez. Ücretsiz Gemini’de Google metni ve model çıktısını ürün geliştirme için kullanabilir; insan incelemesi olabilir. Kimlik, iletişim veya özel sağlık bilgisi yazma. Hazır sorular cihazda çalışır.';

  @override
  String get assistantPrivacyAccept => 'Anladım, soruyu gönder';

  @override
  String get assistantPrivacyCancel => 'Hazır soruları kullan';

  @override
  String get assistantUnavailable =>
      'Serbest soru şu an kullanılamıyor. Hazır sorularla devam edebilirsin.';

  @override
  String get assistantSignedOut =>
      'Serbest soru için hesabına giriş yap. Hazır sorular cihazda çalışır.';

  @override
  String get assistantPrivateBlocked =>
      'Bu soruda özel bilgi olabilir. Kimlik, iletişim veya sağlık bilgilerini kaldır ya da hazır bir soru seç.';

  @override
  String get assistantFallback =>
      'Bu soruyu güvenle eşleyemedim. Kayıtlarını incelemek için hazır bir soru seç.';

  @override
  String get assistantClarify => 'Hesabı açmadan önce dönem veya hareketi seç.';

  @override
  String get assistantMulti => 'Birden fazla konu var. Önce hangisine bakalım?';

  @override
  String assistantQuota(String time) {
    return 'Soru sınırına ulaşıldı. Yenilenme: $time. Hazır sorular açık.';
  }

  @override
  String get assistantError => 'Kayıtlar okunamadı. Tekrar dene.';

  @override
  String get assistantRetry => 'Tekrar dene';

  @override
  String get assistantOpenRecords => 'Kayıtları aç';

  @override
  String assistantRecords(String count) {
    return '$count kayıt';
  }

  @override
  String get assistantSoFar => 'Şu ana kadar';

  @override
  String get assistantUnknownStart => 'İlk kayıttan beri';

  @override
  String get assistantNoData =>
      'Bu dönemde kayıt yok. Veri yokluğunu sıfır sonuç olarak değerlendirmiyorum.';

  @override
  String get assistantInsufficient =>
      'Sayılar görünür; eğilim yorumu için henüz yeterli veri yok.';

  @override
  String get assistantNoGoal => 'Bu hesap için hedef belirlenmemiş.';

  @override
  String get assistantNoPlan => 'Planlı antrenman günü yok.';

  @override
  String get assistantIncompleteDays =>
      'Tamamlanan gün yok; protein hedefi başarısı hesaplanmaz.';

  @override
  String get assistantLoggedBasis =>
      'Yalnız kaydedilen günler; eksik kayıt olabilir.';

  @override
  String get assistantCompletedBasis =>
      'Ortalama yalnız tamamlanan günlerden; boş tamamlanan gün 0 sayılır.';

  @override
  String get assistantCurrentPlan =>
      'Bugünkü plan kullanılır; geçmiş plan değişiklikleri bilinmiyor.';

  @override
  String get assistantFoodBasis =>
      'Örnekler seçtiğin öğündeki geçmiş porsiyonların. Yalnız kalan kaloriye göre süzülür; otomatik kaydedilmez.';

  @override
  String get assistantUnknownExercise => 'Bilinmeyen hareket';

  @override
  String get assistantOwnHistory => 'Kendi geçmişin';

  @override
  String get assistantGuideline => 'Genel araştırma bulgusu';

  @override
  String get assistantSources => 'Kaynaklar';

  @override
  String get assistantDeveloper => 'Geliştirici';

  @override
  String get assistantQuality => 'Asistan kalitesi';

  @override
  String get assistantQualityInfo =>
      'Yalnız bu cihazdaki metinsiz olaylar. Düzeltme oranı doğruluk oranı değildir; hiç düzeltmemen doğru eşleme kanıtı sayılmaz.';

  @override
  String get assistantQualityAuto => 'Otomatik cevaplar';

  @override
  String get assistantQualityCorrections => 'Değiştirilen seçimler';

  @override
  String get assistantQualityLatency => 'Gecikme: medyan / %95';

  @override
  String get assistantQualityTokens => 'Girdi / çıktı tokenı';

  @override
  String get assistantQualityFree => 'Gemini ücretsiz katmanı · maliyet \$0';

  @override
  String get assistantQualityClear => 'Yerel kalite kayıtlarını temizle';

  @override
  String get assistantQualityClearConfirm =>
      'Asistan kalite kayıtları silinsin mi? Fitness kayıtların korunur.';

  @override
  String get assistantQualitySmall => 'Az örnek; oranı temkinli oku.';

  @override
  String get assistantQualityWarning =>
      'İki hafta üst üste düzeltme oranı %3’ü aştı. Eşlemeleri gözden geçir.';

  @override
  String get assistantQualityTransitions => 'Sorgu değişiklikleri';

  @override
  String get assistantQualityDays => 'Son 7 gün';

  @override
  String get assistantNotAvailable => 'Bilinmiyor';

  @override
  String get assistantPeriodToday => 'Bugün';

  @override
  String get assistantPeriodThisWeek => 'Bu hafta';

  @override
  String get assistantPeriodLastWeek => 'Geçen hafta';

  @override
  String get assistantPeriodLast30Days => 'Son 30 gün';

  @override
  String get assistantPeriodAllTime => 'Tüm zamanlar';

  @override
  String get assistantQueryWorkoutSummary => 'Antrenmanlarım nasıldı?';

  @override
  String get assistantQueryPlanAdherence => 'Planlı günlere ne kadar uydum?';

  @override
  String get assistantQueryStrengthProgress => 'Hangi hareketlerde ilerledim?';

  @override
  String get assistantQueryExerciseHistory => 'Bu harekette nasıl ilerledim?';

  @override
  String get assistantQueryNutritionSummary =>
      'Beslenme kayıtlarım ne söylüyor?';

  @override
  String get assistantQueryProteinGoal => 'Protein hedefine kaç gün ulaştım?';

  @override
  String get assistantQueryWeightTrend => 'Kilom nasıl değişti?';

  @override
  String get assistantQueryMuscleBalance => 'Kas gruplarına kaç set yaptım?';

  @override
  String get assistantQueryStreak => 'Kaç haftadır düzenliyim?';

  @override
  String get assistantQueryTodayRemaining => 'Bugün hedefime ne kaldı?';

  @override
  String get assistantQueryTopExercises => 'En çok hangi hareketleri yaptım?';

  @override
  String get assistantMetricSessions => 'Seans';

  @override
  String get assistantMetricSets => 'Tamamlanan set';

  @override
  String get assistantMetricMinutes => 'Süre';

  @override
  String get assistantMetricVolume => 'Hacim';

  @override
  String get assistantMetricPlannedDays => 'Planlı gün';

  @override
  String get assistantMetricDoneDays => 'Yapılan planlı gün';

  @override
  String get assistantMetricLoggedDays => 'Kayıtlı gün';

  @override
  String get assistantMetricCompletedDays => 'Tamamlanan gün';

  @override
  String get assistantMetricExcludedDays => 'Hesaba katılmayan gün';

  @override
  String get assistantMetricAvgKcal => 'Ortalama enerji';

  @override
  String get assistantMetricAvgProtein => 'Ortalama protein';

  @override
  String get assistantMetricProteinGoal => 'Protein hedefi';

  @override
  String get assistantMetricHitDays => 'Hedefe ulaşan tamamlanmış gün';

  @override
  String get assistantMetricMeasurements => 'Ölçüm';

  @override
  String get assistantMetricFirstWeight => 'İlk kilo';

  @override
  String get assistantMetricLastWeight => 'Son kilo';

  @override
  String get assistantMetricChange => 'Değişim';

  @override
  String get assistantMetricWeeks => 'Haftalık seri';

  @override
  String get assistantMetricWeeklyGoal => 'Haftalık gün hedefi';

  @override
  String get assistantMetricRemainingKcal => 'Kalan enerji';

  @override
  String get assistantMetricRemainingProtein => 'Kalan protein';

  @override
  String get assistantMetricFirstE1rm => 'İlk tahmini tek tekrar maksimumu';

  @override
  String get assistantMetricLastE1rm => 'Son tahmini tek tekrar maksimumu';

  @override
  String get assistantMetricPortion => 'Geçmiş porsiyon';

  @override
  String get assistantMetricPortionKcal => 'Porsiyon enerjisi';

  @override
  String get assistantMetricPortionProtein => 'Porsiyon proteini';

  @override
  String insightMuscleBelowTen(String muscle, String sets, String level) {
    return '$muscle: $sets set, araştırmadaki haftalık yaklaşık $level set düzeyinin altında.';
  }

  @override
  String insightMuscleAtTen(String muscle, String sets, String level) {
    return '$muscle: $sets set, araştırmadaki yaklaşık $level set düzeyinde veya üzerinde.';
  }

  @override
  String insightMuscleBeyondTwenty(
    String muscle,
    String sets,
    String limitedEvidenceAbove,
  ) {
    return '$muscle: $sets set. $limitedEvidenceAbove setin ötesinde ek kazanım kanıtı sınırlı.';
  }

  @override
  String insightWeightNotEnoughData(
    String count,
    String spanDays,
    String minDays,
  ) {
    return '$count ölçüm, $spanDays gün açıklık. Eğilim yorumu için en az iki ölçüm ve $minDays gün gerekir.';
  }

  @override
  String insightWeightAgainstGoal(String weeklyChangeKg) {
    return 'Haftalık değişim $weeklyChangeKg; seçtiğin hedef yönünün tersinde.';
  }

  @override
  String insightWeightNoClearChange(String weeklyChangeKg) {
    return 'Haftalık değişim $weeklyChangeKg; belirgin bir eğilim görünmüyor.';
  }

  @override
  String insightWeightLossSlower(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Haftalık değişim $weeklyChangeKg; CDC’nin genel $rangeMinKg–$rangeMaxKg kayıp aralığından daha yavaş.';
  }

  @override
  String insightWeightLossInRange(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Haftalık değişim $weeklyChangeKg; CDC’nin genel $rangeMinKg–$rangeMaxKg kayıp aralığında.';
  }

  @override
  String insightWeightLossFaster(
    String weeklyChangeKg,
    String rangeMinKg,
    String rangeMaxKg,
  ) {
    return 'Haftalık değişim $weeklyChangeKg; CDC’nin genel $rangeMinKg–$rangeMaxKg kayıp aralığından daha hızlı.';
  }

  @override
  String insightWeightGainSlower(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Haftalık %$pctPerWeek artış; araştırmadaki %$rangeMinPct–%$rangeMaxPct düzeyinden daha yavaş.';
  }

  @override
  String insightWeightGainInRange(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Haftalık %$pctPerWeek artış, araştırmadaki %$rangeMinPct–%$rangeMaxPct düzeyinde.';
  }

  @override
  String insightWeightGainFaster(
    String pctPerWeek,
    String rangeMinPct,
    String rangeMaxPct,
  ) {
    return 'Haftalık %$pctPerWeek artış; araştırmadaki %$rangeMinPct–%$rangeMaxPct düzeyinden daha hızlı.';
  }

  @override
  String insightWeightStable(String totalChangePct, String stablePct) {
    return 'Dönemde öngörülen değişim %$totalChangePct; ortalamanın ±%$stablePct aralığında.';
  }

  @override
  String insightWeightDriftUp(String totalChangePct) {
    return 'Dönemde öngörülen artış %$totalChangePct.';
  }

  @override
  String insightWeightDriftDown(String totalChangePct) {
    return 'Dönemde öngörülen değişim %$totalChangePct.';
  }

  @override
  String insightWorkoutNotEnoughHistory(
    String metric,
    String value,
    String minWeeks,
    String baselineWeeks,
  ) {
    return '$metric: $value. Kendi geçmişinle karşılaştırmak için en az $minWeeks tamamlanmış hafta gerekir; $baselineWeeks var.';
  }

  @override
  String insightWorkoutNoBaseline(String metric, String value) {
    return '$metric: $value. Geçmiş medyanı 0; yüzde karşılaştırması yapılamaz.';
  }

  @override
  String insightWorkoutSoFar(
    String metric,
    String value,
    String baselineWeeks,
    String median,
  ) {
    return '$metric: şu ana kadar $value. Önceki $baselineWeeks haftanın medyanı $median; devam eden hafta tam haftayla karşılaştırılmaz.';
  }

  @override
  String insightWorkoutAboveMedian(
    String metric,
    String value,
    String median,
    String pct,
  ) {
    return '$metric: $value, geçmiş medyan $median; %$pct üzerinde.';
  }

  @override
  String insightWorkoutAtMedian(String metric, String value, String median) {
    return '$metric: $value, geçmiş medyanla ($median) aynı.';
  }

  @override
  String insightWorkoutBelowMedian(
    String metric,
    String value,
    String median,
    String pct,
  ) {
    return '$metric: $value, geçmiş medyan $median; fark %$pct.';
  }

  @override
  String get insightStrengthNotApplicable =>
      'Uygun ağırlık/tekrar seti yok; tahmini tek tekrar maksimumu hesaplanamaz.';

  @override
  String insightStrengthNotEnoughData(String days) {
    return '$days farklı günde uygun set var; gelişim için en az iki gün gerekir.';
  }

  @override
  String insightStrengthUp(String firstE1rm, String lastE1rm, String pct) {
    return 'Tahmini tek tekrar maksimumu $firstE1rm → $lastE1rm; %$pct artış.';
  }

  @override
  String insightStrengthStable(String firstE1rm, String lastE1rm) {
    return 'Tahmini tek tekrar maksimumu $firstE1rm → $lastE1rm; değişim ±%1 içinde.';
  }

  @override
  String insightStrengthDown(String firstE1rm, String lastE1rm, String pct) {
    return 'Tahmini tek tekrar maksimumu $firstE1rm → $lastE1rm; değişim %$pct.';
  }

  @override
  String insightStrengthPlateau(String topKg, String weeks) {
    return 'Son $weeks ardışık veri haftasında en ağır set $topKg.';
  }

  @override
  String get insightNutritionNoLogs =>
      'Bu dönem beslenme hesabı için veri yok.';

  @override
  String insightProteinGoalDays(
    String goal,
    String hitDays,
    String loggedDays,
  ) {
    return '$hitDays/$loggedDays tamamlanan günde $goal g protein hedefine ulaşıldı.';
  }

  @override
  String insightKcalVsGoal(
    String loggedDays,
    String avgKcal,
    String goal,
    String pctOfGoal,
  ) {
    return '$loggedDays gün ortalaması $avgKcal kcal; hedefin $goal kcal (%$pctOfGoal).';
  }

  @override
  String insightProteinPerKgBelow(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Kaydedilen ortalama $gPerKg g/kg; araştırmadaki yaklaşık $breakpoint g/kg düzeyinin altında. Kullanılan kilo: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightProteinPerKgInRange(
    String gPerKg,
    String breakpoint,
    String upper,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Kaydedilen ortalama $gPerKg g/kg; araştırmadaki $breakpoint–$upper g/kg aralığında. Kullanılan kilo: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightProteinPerKgAbove(
    String gPerKg,
    String breakpoint,
    String bodyWeightKg,
    String bodyWeightDate,
  ) {
    return 'Kaydedilen ortalama $gPerKg g/kg. Araştırmada yaklaşık $breakpoint g/kg üstünde ek yağsız kütle kazanımı görülmedi; bu bir güvenlik sınırı değildir. Kullanılan kilo: $bodyWeightKg ($bodyWeightDate).';
  }

  @override
  String insightTodayNoGoal(String loggedKcal, String loggedProtein) {
    return 'Enerji hedefi yok; bugün $loggedKcal kcal ve $loggedProtein g protein kaydedildi.';
  }

  @override
  String insightTodayRemaining(String remainingKcal) {
    return 'Enerji hedefine $remainingKcal kcal kaldı. Kayıtların eksik olabilir.';
  }

  @override
  String insightTodayGoalReached(String remainingKcal) {
    return 'Enerji hedefinden kalan $remainingKcal kcal; sıfır veya negatif değer hedefe ulaşıldığını gösterir.';
  }

  @override
  String get assistantNoteGeneralGuideline =>
      'Genel kılavuz; kişisel tıbbi tavsiye değildir.';

  @override
  String get assistantNoteConsultProfessional =>
      'Tıbbi değerlendirme için uzmana danış.';

  @override
  String get assistantNoteSoFar =>
      'Devam eden dönemin şu ana kadarki kayıtları.';

  @override
  String get assistantNoteCompletedSetsCounted =>
      'Tamamlanan, ısınma dışı setler birincil kasa yazılır; araştırmalar zorlayıcı setleri inceler.';

  @override
  String get assistantNoteFastLossCaution =>
      'Haftalık kayıp %1,5’i aştı. Bu dikkat eşiği ürün tercihidir.';

  @override
  String get assistantNoteLeanMassInfo =>
      'Kuvvet sporcularındaki bir çalışmada haftalık yaklaşık %0,7 kayıp yağsız kütleyi daha iyi korudu.';

  @override
  String get assistantNoteBeginnerIntermediateRange =>
      'Bu aralık başlangıç/orta seviye için araştırılmıştır.';

  @override
  String get assistantNoteLoggedOnly =>
      'Yalnız kaydedilen miktarlar; eksik kayıt olabilir.';

  @override
  String get assistantNoteCompletedDaysOnly =>
      'Yalnız tamamlanan günler hesaba katıldı.';

  @override
  String get assistantNoteChooseGoalDirection =>
      'Hedef yönünü seçersen yönüne göre yorumlayabilirim.';

  @override
  String get assistantQualityUnavailable =>
      'Yerel kalite kaydı yazılamadı. Sonuçlarını kullanmaya devam edebilirsin.';

  @override
  String get assistantDecisionAuto => 'Otomatik';

  @override
  String get assistantDecisionClarify => 'Netleştirme';

  @override
  String get assistantDecisionMulti => 'Çoklu konu';

  @override
  String get assistantDecisionFallback => 'Hazır sorulara dönüş';

  @override
  String get assistantDecisionError => 'Ağ / kota hatası';

  @override
  String get assistantMuscleChest => 'Göğüs';

  @override
  String get assistantMuscleUpperChest => 'Üst göğüs';

  @override
  String get assistantMuscleBack => 'Sırt';

  @override
  String get assistantMuscleShoulders => 'Omuz';

  @override
  String get assistantMuscleFrontDelt => 'Ön omuz';

  @override
  String get assistantMuscleRearDelt => 'Arka omuz';

  @override
  String get assistantMuscleBiceps => 'Ön kol';

  @override
  String get assistantMuscleTriceps => 'Arka kol';

  @override
  String get assistantMuscleForearms => 'Ön kol altı';

  @override
  String get assistantMuscleLegs => 'Bacak';

  @override
  String get assistantMuscleQuads => 'Ön bacak';

  @override
  String get assistantMuscleHamstrings => 'Arka bacak';

  @override
  String get assistantMuscleGlutes => 'Kalça';

  @override
  String get assistantMuscleCalves => 'Baldır';

  @override
  String get assistantMuscleCore => 'Karın';

  @override
  String get assistantMuscleFullBody => 'Tüm vücut';

  @override
  String get assistantMuscleOther => 'Diğer';

  @override
  String bmFromHealth(String app) {
    return 'Sağlık · $app';
  }

  @override
  String get bmHideTitle => 'Ölçümü gizle';

  @override
  String bmHideMsg(String date) {
    return '$date tarihli tartı ölçümü gizlensin mi? Sağlık uygulamasındaki kayıt değişmez.';
  }

  @override
  String get healthWeightRow => 'Kilo ve yağ oranı';

  @override
  String get healthWeightOn => 'Açık · tartı uygulamalarından';

  @override
  String get healthWeightOff => 'Kapalı';

  @override
  String get healthConsentTitle => 'Tartı ölçümlerin Fit Pack\'e gelsin';

  @override
  String get healthConsentWhat =>
      'Okunan: tartı uygulamalarının Apple Sağlık / Health Connect\'e yazdığı kilo ve vücut yağ oranı. Başka bir şey değil.';

  @override
  String get healthConsentWhere =>
      'Fit Pack hesabında saklanır; sunucular Avrupa Birliği\'nde (Almanya).';

  @override
  String get healthConsentWhy =>
      'Yalnız ilerleme grafiğin, kilo eğilimin ve haftalık değerlendirmen için kullanılır.';

  @override
  String get healthConsentNoShare =>
      'Reklamda kullanılmaz, satılmaz, üçüncü taraflarla paylaşılmaz.';

  @override
  String get healthConsentWithdraw =>
      'Rızanı istediğin an Ayarlar → Sağlık\'tan geri alabilirsin; içe alınan ölçümler o zaman silinir.';

  @override
  String get healthConsentLegal =>
      'Bu, sağlık verilerinin işlenmesine ilişkin açık rızandır (KVKK md. 6, GDPR md. 9).';

  @override
  String get healthConsentAccept => 'Kabul ediyorum';

  @override
  String get healthConsentDecline => 'Şimdi değil';

  @override
  String get healthWithdrawTitle => 'Rızayı geri al';

  @override
  String get healthWithdrawMsg =>
      'Tartıdan içe aktarma durur ve şimdiye kadar içe alınan ölçümler silinir (buluttan da). Sonra yeniden rıza verirsen yalnız yeni ölçümler gelir.';

  @override
  String get healthWithdrawDelete => 'Ölçümleri sil';

  @override
  String get privacyTitle => 'Gizlilik politikası';

  @override
  String get privacySubtitle => 'Hangi verileri, nerede işliyoruz; hakların';

  @override
  String get privacyAuthLink =>
      'Verilerini nasıl kullanıyoruz (gizlilik politikası)';

  @override
  String get homeWeightTrend7d => '7 günlük trend';

  @override
  String get bmTrendLegend => 'nokta: günlük · çizgi: trend';

  @override
  String get adaptiveTdeeTitle => 'Gerçek harcaman (tahmin)';

  @override
  String adaptiveTdeeValue(int kcal, int days) {
    return '~$kcal kcal/gün · $days tamamlanmış gün ve kilo eğiliminden';
  }

  @override
  String adaptiveTdeeAtGoal(int goal, String change) {
    return '$goal kcal hedefinle: haftada yaklaşık $change';
  }

  @override
  String adaptiveTdeeNeedDays(int need, int have) {
    return 'Son 4 haftada $need gün \'tamamlandı\' işaretli olmalı (şu an $have).';
  }

  @override
  String adaptiveTdeeNeedWeighIns(int count, int days) {
    return 'En az $count tartı ölçümü, $days güne yayılmış olmalı.';
  }

  @override
  String get adaptiveTdeeInconsistent =>
      'Tahmin için kayıtlar eksik görünüyor — tamamlandı işaretli günlerin tam girildiğini kontrol et.';

  @override
  String get adaptiveTdeeNote =>
      'Tahmindir (1 kg ≈ 7.700 kcal). Hedefin kendiliğinden değişmez.';

  @override
  String get healthWriteWorkouts => 'Antrenmanları Sağlık\'a yaz';

  @override
  String get healthWriteWorkoutsNote =>
      'Canlı seanslar Apple Sağlık / Health Connect\'te görünür (saat ve ad; kalori yazılmaz).';

  @override
  String get expDraftError => 'Devam eden antrenman okunamadı. Yeniden dene.';

  @override
  String expFirstMeal(String goal) {
    return 'Bugün 0 / $goal kcal · İlk öğününü ekle';
  }

  @override
  String get expPlanSubtitle =>
      'Hedefine göre önerildi — istediğin gibi değiştir. Sonradan Profil’den de güncelleyebilirsin.';

  @override
  String get expMeasurementError => 'Ölçüm değiştirilemedi. Yeniden dene.';

  @override
  String get expAuthConnection =>
      'Bağlantı kurulamadı. İnternetini kontrol edip yeniden dene.';

  @override
  String get expAuthCredentials => 'E-posta veya şifre yanlış.';

  @override
  String get expAuthUnconfirmed => 'Giriş yapmadan önce e-postanı doğrula.';

  @override
  String get expAuthExists =>
      'Bu e-posta ile bir hesap var. Giriş yapmayı dene.';

  @override
  String get expAuthRateLimit =>
      'Çok sık denedin. Biraz bekleyip yeniden dene.';

  @override
  String get expAuthPassword => 'Farklı, en az 6 karakterli bir şifre seç.';

  @override
  String get expAuthGeneric => 'İşlem tamamlanamadı. Yeniden dene.';

  @override
  String get expConfirmTitle => 'E-postanı doğrula';

  @override
  String get expConfirmHelp =>
      'Gelen kutunu ve spam klasörünü kontrol et. Bağlantıyı başka cihazda açtıysan buraya dönüp giriş yap. Google ile de devam edebilirsin.';

  @override
  String get expResend => 'Doğrulama e-postasını yeniden gönder';

  @override
  String get expChangeEmail => 'E-posta adresini değiştir';

  @override
  String get expEmailSent => 'Doğrulama e-postası gönderildi.';

  @override
  String get expAmountDecrease => 'Miktarı azalt';

  @override
  String get expAmountIncrease => 'Miktarı artır';

  @override
  String get expAmount => 'Miktar';

  @override
  String get expUpdate => 'Güncelle';

  @override
  String get expBarcode => 'Barkod';

  @override
  String get expCreateFood => 'Kendi besinini oluştur';

  @override
  String get expYesterdayMeal => 'Dünkü gibi ekle';

  @override
  String expProteinRemaining(String grams) {
    return '$grams g protein kaldı';
  }

  @override
  String expTodayLeftBoth(String protein, String kcal) {
    return 'Bugün $protein g protein, $kcal kcal kaldı.';
  }

  @override
  String expTodayLeftProtein(String protein) {
    return 'Bugün $protein g protein kaldı.';
  }

  @override
  String expTodayLeftKcal(String kcal) {
    return 'Bugün $kcal kcal kaldı.';
  }
}
