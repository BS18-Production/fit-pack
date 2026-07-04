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
  String get homeExportTooltip => 'Veri dışa aktar';

  @override
  String get homeSettingsTooltip => 'Ayarlar';

  @override
  String get homeStreakKicker => 'Seri korunuyor';

  @override
  String get homeStreakKickerZero => 'Yeni hafta, yeni ritim';

  @override
  String homeStreakTitle(int count) {
    return '$count gündür\nritimdesin 🔥';
  }

  @override
  String get homeStreakTitleZero => 'Serini başlat 💪';

  @override
  String get homeStatWorkouts => 'antrenman';

  @override
  String get homeStatVolume => 'kg hacim';

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
  String get settingsSectionAppearance => 'Görünüm';

  @override
  String get settingsSectionNutrition => 'Beslenme';

  @override
  String get settingsSectionMyData => 'Verilerim';

  @override
  String get settingsSectionAbout => 'Hakkında';

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
  String get settingsBackup => 'Cihaza Yedekle';

  @override
  String get settingsBackupSubtitle =>
      'Verini dosya olarak kaydet (Drive/Dosyalar) — geri yüklenebilir';

  @override
  String get settingsRestore => 'Yedekten Geri Yükle';

  @override
  String get settingsRestoreSubtitle =>
      'Daha önce aldığın yedek dosyasını geri yükle';

  @override
  String get settingsExport => 'Veri Dışa Aktar (rapor)';

  @override
  String get settingsExportSubtitle =>
      'Okunabilir rapor — Markdown / JSON / CSV';

  @override
  String get settingsCloudAccount => 'Bulut Hesabı';

  @override
  String settingsCloudSignedIn(String email) {
    return '$email · buluta yedekle / geri yükle';
  }

  @override
  String get settingsCloudSignedInFallback => 'Giriş yapıldı';

  @override
  String get settingsCloudSignedOut =>
      'Giriş yap → verini buluta yedekle, yeni cihazda geri yükle';

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
  String settingsBackupFailed(String error) {
    return 'Yedek oluşturulamadı: $error';
  }

  @override
  String get settingsRestoreConfirmTitle => 'Yedekten geri yükle';

  @override
  String get settingsRestoreConfirmMessage =>
      'Şu anki tüm verinin yerine bu yedek yüklenecek. Bu işlem geri alınamaz. Devam edilsin mi?';

  @override
  String get settingsRestoreConfirmAction => 'Geri Yükle';

  @override
  String get settingsRestoreFailedTitle => 'Geri yükleme başarısız';

  @override
  String get settingsRestoreFailedMessage =>
      'Bir sorun oluştu, mevcut verin korundu. Uygulama kapanacak — tekrar açman yeterli.';

  @override
  String settingsRestoreFailed(String error) {
    return 'Geri yükleme başarısız: $error';
  }

  @override
  String get settingsRestoredTitle => 'Geri yüklendi';

  @override
  String get settingsRestoredMessage =>
      'Veriler geri yüklendi. Değişikliklerin görünmesi için uygulama kapanacak — tekrar açman yeterli.';

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
  String get onbPlanReadyTitle => 'Planın hazır ✨';

  @override
  String get onbPlanReadySubtitle =>
      'Hedefine göre önerildi — istediğin gibi değiştir. Sonradan Ayarlar\'dan da güncelleyebilirsin.';

  @override
  String get onbDailyKcal => 'Günlük kalori hedefi';

  @override
  String get onbDailyProtein => 'Günlük protein hedefi';

  @override
  String onbProjectionCut(String goal, int weeks) {
    return 'Bu tempoyla tahmini $weeks haftada $goal kg hedefine ulaşabilirsin.';
  }

  @override
  String onbProjectionBulk(String goal, int weeks) {
    return 'Bu tempoyla tahmini $weeks haftada $goal kg\'a ulaşabilirsin.';
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
}
