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
  String get homeToday => 'BUGÜN';

  @override
  String get homeStreakKickerZero => 'Yeni hafta, yeni ritim';

  @override
  String homeStreakTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haftadır\nritimdesin',
    );
    return '$_temp0';
  }

  @override
  String get homeStreakTitleZero => 'Serini başlat';

  @override
  String get homeStreakTitleFirstWeek => 'İlk haftanı\ntamamla';

  @override
  String homeStreakWeekProgress(int done, int goal) {
    return 'Bu hafta $done/$goal antrenman';
  }

  @override
  String get homeStatWorkouts => 'antrenman';

  @override
  String homeStatVolume(String unit) {
    return '$unit hacim';
  }

  @override
  String get homeStatKcal => 'kcal';

  @override
  String homeTodayRoutine(String name) {
    return 'Bugün: $name';
  }

  @override
  String homeStartWithCount(int count) {
    return 'Antrenmanı başlat · $count hareket';
  }

  @override
  String get homeStart => 'Antrenmanı başlat';

  @override
  String get homeStartTitle => 'Antrenmana başla';

  @override
  String get homeStartSubtitle => 'Rutin oluştur ya da boş antrenman başlat';

  @override
  String get homeRestTitle => 'Bugün dinlenme günü';

  @override
  String homeRestNext(String name) {
    return 'Sıradaki: $name';
  }

  @override
  String get homeWorkoutAnyway => 'Yine de antrenman yap';

  @override
  String get homeThisWeek => 'Bu Hafta';

  @override
  String homeWeekGoalDone(int done, int total) {
    return '$done/$total antrenman tamam';
  }

  @override
  String homeWeekGoalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count antrenman',
    );
    return '$_temp0';
  }

  @override
  String get homeMetricVolume => 'kaldırılan hacim';

  @override
  String get homeMetricKcal => 'kcal yakıldı';

  @override
  String get homeMetricWorkouts => 'antrenman tamamlandı';

  @override
  String get homeMetricProtein => 'protein hedefi ort.';

  @override
  String get homeNutritionTitle => 'Bugünkü Beslenme';

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
  String get mealSnackShort => 'Atıştır.';

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
  String get whSetsLoadError => 'Setler yüklenemedi';

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
      'Bu rutin listeden kaldırılsın mı? Geçmiş antrenmanlar korunur.';

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
  String get asPastEntry => 'Geçmiş kayıt';

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
  String get elPickTitle => 'Hareket Seç';

  @override
  String get elSearchHint => 'Hareket ara…';

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
  String get cloudGoogleErr =>
      'Google girişi henüz yapılandırılmadı ya da iptal edildi.';

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
  String get cloudNoAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get cloudHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get cloudSignOut => 'Çıkış Yap';

  @override
  String get cloudDeleteAccount => 'Hesabı Sil';

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
  String get notifWorkout => 'Günlük antrenman hatırlatıcı';

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
  String get notifWorkoutTitle => 'Antrenman zamanı';

  @override
  String get notifWorkoutBody =>
      'Planın seni bekliyor — kısa bir seans da sayılır.';

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
      'Hedef önerisi için kilon yeterli — gerisi opsiyonel (cinsiyet ve doğum tarihi günlük enerji tahminini iyileştirir).';

  @override
  String get onbCurrentWeight => 'Mevcut kilo';

  @override
  String get onbGoalWeightOptional => 'Hedef kilo (opsiyonel)';

  @override
  String get onbBirthDateOptional => 'Doğum tarihi (opsiyonel)';

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
  String get onbWhatsInsideTitle => 'İçeride ne var';

  @override
  String get onbWhatsInsideSubtitle => 'Dört sekme, her şey yerli yerinde:';

  @override
  String get onbTourHomeDesc => 'Günün özeti: seri, plan, beslenme, su';

  @override
  String get onbTourWorkoutDesc => 'Rutin kur, setlerini kaydet, geçmişe bak';

  @override
  String get onbTourNutritionDesc =>
      'Öğün ekle: ara, barkod okut, makroları izle';

  @override
  String get onbTourProgressDesc => 'Kilo ve ölçüm gir, gelişimi grafikte gör';

  @override
  String get onbStart => 'Başlayalım';

  @override
  String get onbGoalsNumberError =>
      'Kalori ve protein hedefini sayı olarak gir';

  @override
  String get onbSaveError => 'Kaydedilemedi — tekrar dene';

  @override
  String get hintWorkout =>
      'İlk rutinini buradan kur — ya da hemen boş antrenman başlat.';

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
}
