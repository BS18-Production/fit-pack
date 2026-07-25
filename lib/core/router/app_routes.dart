/// Merkezi rota tanımları (CODE_REVIEW L-02).
///
/// Router bu sabitleri `path` olarak kullanır; ekranlar navigasyonda yine
/// bunları çağırır. Böylece rota adresi tek yerde tanımlı → elle yazılan
/// string kaynaklı yazım hataları (ör. `/wokrout`) derlemede yakalanır.
///
/// KURAL: Yeni rota eklerken önce buraya sabit/oluşturucu ekle, sonra
/// `app_router.dart`'ta `GoRoute(path: AppRoutes.x)` tanımla, çağrı yerinde
/// `context.go(AppRoutes.x)` kullan. Ham string `'/...'` yazma.
class AppRoutes {
  AppRoutes._();

  // ── Giriş kapısı (docs/18 §5.1) ──
  /// ① Karşılama — oturum yokken uygulamanın açıldığı yer.
  static const welcome = '/welcome';

  /// ② Giriş / Kayıt. `mode=signup` kayıt sekmesiyle açar.
  static const auth = '/auth';
  static String authMode({required bool signUp}) =>
      '$auth?mode=${signUp ? 'signup' : 'login'}';

  /// Şifre kurtarma — maildeki bağlantıdan gelen kullanıcı yeni şifresini
  /// burada belirler (docs/18 §14). Yalnız kurtarma oturumunda erişilir.
  static const resetPassword = '/reset-password';

  // ── Onboarding ──
  static const onboarding = '/onboarding';

  // ── Shell sekmeleri ──
  static const home = '/home';
  static const workout = '/workout';
  static const nutrition = '/nutrition';
  static const progress = '/progress';

  // ── Antrenman alt rotaları (sabit) ──
  static const workoutHistory = '/workout/history';
  static const workoutActive = '/workout/active';
  static const workoutActiveResume = '/workout/active/resume';
  static const workoutLogPast = '/workout/log-past';
  static const routineNew = '/workout/routine/new';

  // ── Diğer sabit rotalar ──
  static const exercises = '/exercises';
  static const exercisesSelect = '/exercises/select';
  static const foods = '/foods';
  static const cloud = '/cloud';
  static const profile = '/profile';
  static const settings = '/settings';
  static const attribution = '/settings/attribution';
  static const notifications = '/settings/notifications';

  // ── Parametreli rotalar: `*Path` = router tanımı, fonksiyon = çağrı ──
  static const routineEditPath = '/workout/routine/:id/edit';
  static String routineEdit(int id) => '/workout/routine/$id/edit';

  static const routinePreviewPath = '/workout/routine/:id/preview';
  static String routinePreview(int id) => '/workout/routine/$id/preview';

  static const workoutActiveRoutinePath = '/workout/active/:routineId';
  static String workoutActiveRoutine(int routineId) =>
      '/workout/active/$routineId';

  static const summaryPath = '/workout/summary/:sessionId';
  static String summary(int sessionId) => '/workout/summary/$sessionId';

  static const exerciseDetailPath = '/exercise/:id';
  static String exerciseDetail(int id) => '/exercise/$id';
}
