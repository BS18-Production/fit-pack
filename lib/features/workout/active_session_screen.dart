import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/feedback/feedback_service.dart';
import '../../core/feedback/rest_alarm.dart';
import '../../core/live_activity/workout_live_activity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/prefs/training_prefs.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import '../../core/utils/format.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'progression.dart';
import 'record_calc.dart';
import 'live_position.dart';
import 'session_progress.dart';
import 'set_prefill.dart';
import 'live_action_target.dart';
import 'weight_step.dart';
import 'active_session_model.dart';
import 'active_session_widgets.dart';
import 'exercise_replacement.dart';
import 'session_rest_sound.dart';
import 'workout_draft.dart';
import 'workout_ui.dart';
import '../../core/router/app_routes.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../health/body_providers.dart';
import '../cloud/auth_service.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_providers.dart';

/// Aktif Antrenman Seansı (Antrenman V2 Faz C — docs/09-workout-v2.md).
/// Set tablosu (KG/tekrar/RPE/✓), set tipleri, dinlenme sayacı, canlı süre,
/// +set / +hareket. Bitir → seans + setler kaydedilir → özet.

/// Set alanına yazım durduktan sonra taslağın kaydedilme gecikmesi.
const _draftSaveDelay = Duration(milliseconds: 500);

/// Çıkış penceresinin seçenekleri (docs/53).
enum _ExitChoice { keep, save, discard }

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final int? routineId;
  // Geçmiş antrenman ekleme modu: dolu ise kronometre çalışmaz, seans bu güne
  // yazılır (H-B). null ise normal canlı seans (H-A: bitişte tarih düzenlenebilir).
  final DateTime? manualDate;
  // Kaydedilmiş taslaktan devam (docs/12). true ise routine yerine taslak yüklenir.
  final bool resume;

  /// Geçmiş kayıtta tarih seçici açılışta kendiliğinden açılsın mı. Takvimden
  /// belli bir gün için gelince hayır (gün zaten seçili).
  final bool pickDateOnOpen;
  const ActiveSessionScreen(
      {super.key,
      this.routineId,
      this.manualDate,
      this.resume = false,
      this.pickDateOnOpen = true});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with WidgetsBindingObserver {
  final List<SessionExerciseEntry> _exercises = [];
  late String _title;
  // Rutin bağı: normalde route'tan gelir; resume modunda TASLAKTAN geri
  // yüklenir (M-01 — widget.routineId resume'da null olur, bağ kopmasın).
  int? _routineId;
  late DateTime _startedAt;
  late DateTime _sessionDate; // seansın yazılacağı mantıksal gün
  bool _loading = true;
  // Yükleme hatası (A1 E10): sonsuz dönen gösterge yerine tekrar dene.
  Object? _loadError;
  bool _saving = false;
  bool _replacing = false;
  bool _committingReplacement = false;
  bool _replacementDirty = false;
  late final String? _sessionOwner;
  bool _accountLost = false;
  int _pendingDraftWrites = 0;
  ProviderSubscription<String?>? _accountWatch;
  bool _draftCleared = false; // bitir/çıkış sonrası taslak yazımını durdur
  late final WorkoutDraftService _drafts;
  // Ekran açıldığında taslak kaç kez silinmişti — değişirse taslak başka
  // yerden silinmiştir (hesap değişimi), bu ekran onu yeniden yazmaz.
  late final int _draftClearCount;
  // Set alanına yazarken gecikmeli kayıt (bkz. [_scheduleDraftSave]).
  Timer? _draftDebounce;

  bool get _isManual => widget.manualDate != null;
  // Yalnızca canlı seans taslaklanır (geçmiş kayıt hızlı + tarihli, gerek yok).
  bool get _draftable => !_isManual;

  Timer? _ticker; // canlı süre
  // Son tamamlanan setin anı — süre kuralı (docs/53): boşta geçen zaman sayılmaz.
  DateTime? _lastDoneAt;
  Duration _elapsed = Duration.zero;

  Timer? _restTimer;
  // Sayaç duvar saatine bağlı (M-03): uygulama arka plana alınınca Dart
  // timer'ları donar; tık saymak yerine hedef bitiş anı saklanır, her tikte
  // kalan süre gerçek zamandan hesaplanır — dönüşte doğru kalır.
  DateTime? _restDeadline;
  DateTime? _restStartedAt; // kilit ekranı ilerleme çubuğu (docs/45)
  int _restRemaining = 0; // yalnız görüntü için (deadline'dan türetilir)
  // Süren mola kurulumu (servis + bildirim). Kilit ekranı eylemi dönmeden
  // beklenir — iOS ardından uygulamayı yeniden askıya alır.
  Future<void>? _restSetup;
  // dispose'ta ref kullanılmaz — servisler baştan yakalanır.
  late final FeedbackService _feedback = ref.read(feedbackServiceProvider);
  // Mola sesi/titreşimi/bildirimi — yerel servis ya da uygulama içi yol.
  // İlk molada kurulur; dispose'ta kurulmadıysa ref'e dokunulmaz.
  SessionRestSound? _restSoundOrNull;
  SessionRestSound get _restSound => _restSoundOrNull ??=
      SessionRestSound(ref.read(restAlarmProvider), _feedback);
  late final WorkoutLiveActivity _live = ref.read(workoutLiveActivityProvider);
  bool _disposing = false;
  final _liveSetTarget = LiveActionTarget();
  final _liveRestTarget = LiveActionTarget();
  bool _handlingLiveAction = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _routineId = widget.routineId;
    _startedAt = widget.manualDate ?? now;
    _sessionDate = DateTime(_startedAt.year, _startedAt.month, _startedAt.day);
    _title = ''; // ilk didChangeDependencies'te locale ile atanır
    _drafts = ref.read(workoutDraftServiceProvider);
    _draftClearCount = _drafts.clearCount;
    _sessionOwner = ref.read(currentUserProvider)?.id;
    _accountWatch = ProviderScope.containerOf(context, listen: false).listen<String?>(
      currentUserProvider.select((user) => user?.id),
      (before, after) {
        if (before == after) return;
        // Hesap temizliğini bekleme: A→B→A da eski seansı canlandırmaz.
        _invalidateAccount();
      },
    );
    if (!_isManual) {
      WakelockPlus.enable(); // antrenman boyunca ekran uyanık kalsın (docs/12)
      // İlk bip gecikmesin (G-1) — seçili ses yüklensin (docs/45 §3).
      _feedback.warmUp(ref.read(notificationPrefsProvider).restSound);
      WidgetsBinding.instance.addObserver(this);
      _live.attach(_onLiveAction); // kilit ekranı düğmeleri (docs/45 §2)
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsed = DateTime.now().difference(_startedAt));
        }
      });
    }
    // Serbest akış _syncLive'a await etmeden ulaşır; localization için
    // initState tamamlanmalı. Ekran kapanmışsa ilk yükleme başlatılmaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadSafely());
    });
  }

  /// [_load]'u hata yakalayarak çalıştırır; hata olursa ekranda "Tekrar dene".
  void _invalidateAccount() {
    if (_accountLost) return;
    _accountLost = true;
    if (!_isManual) unawaited(WorkoutLiveActivity.endAll());
    _liveSetTarget.clear();
    _liveRestTarget.clear();
    _draftDebounce?.cancel();
  }

  bool _ownsCurrentAccount() {
    // Türetilmiş provider bildirimi henüz yayılmadıysa güncel okumayla yakala.
    if (mounted && !_disposing &&
        ref.read(currentUserProvider)?.id != _sessionOwner) {
      _invalidateAccount();
    }
    return !_accountLost;
  }

  bool _analyticsStartRecorded = false;

  Future<void> _loadSafely() async {
    final analytics = ref.read(analyticsControllerProvider);
    final owner = ref.read(currentUserProvider)?.id;
    try {
      await _load();
      // Taslaktan devam yeni başlangıç değildir; kişisel seans adı aktarılmaz.
      if (mounted && !_isManual && !widget.resume && !_analyticsStartRecorded) {
        _analyticsStartRecorded = true;
        unawaited(
          analytics.trackOwned(owner, AnalyticsEventName.workoutStarted, {
            'mode': _routineId == null ? 'free' : 'routine',
          }),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _exercises.clear();
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _loadError = null;
      _loading = true;
    });
    _loadSafely();
  }

  bool _titleInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_titleInitialized) {
      _titleInitialized = true;
      // Rutin/taslak başlığı _load'da üzerine yazabilir; bu yalnız
      // boş/manuel modun varsayılanı. Kayıtta workoutType olarak saklanır
      // (oluşturma anındaki dil — bilinçli, docs/14).
      if (_title.isEmpty) {
        final l = AppL10n.of(context);
        _title = _isManual ? l.asPastWorkout : l.asEmptyWorkout;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka plana alınınca taslağı diske yaz — process öldürülse de kaybolmasın.
    // Yazım bitince banner provider'ını tazele (alttaki liste güncellensin).
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveDraft().then((_) {
        if (mounted) ref.invalidate(activeDraftProvider);
      });
    }
    // P-11 (docs/16 §5): dinlenme sürerken arka plana geçildiyse bitişe
    // bildirim kur; öne dönünce iptal (uygulama içinde sayaç zaten görünür).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _syncRestNotification();
    }
    if (state == AppLifecycleState.resumed) _restSound.dismissDone();
  }

  bool get _inForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// Mola sonu bildirimini kurar ya da kaldırır (bkz.
  /// [SessionRestSound.syncNotification]).
  Future<void> _syncRestNotification() {
    if (!mounted) return Future.value();
    return _restSound.syncNotification(
      service: ref.read(notificationServiceProvider),
      prefs: ref.read(notificationPrefsProvider),
      deadline: _restDeadline,
      inForeground: _inForeground,
      l: AppL10n.of(context),
    );
  }

  /// Kilit ekranından gelen eylem (iOS düğmesi / Android bildirim eylemi).
  /// Uygulama arka plandayken çalışır; ekrandaki dokunuşla aynı yolu izler —
  /// seans durumunun tek sahibi bu ekran. Kart güncellemesi gidene kadar
  /// beklenir (sistem ardından uygulamayı yeniden uyutur).
  Future<bool> _onLiveAction(LiveAction action, String? setKey) async {
    if (!mounted ||
        _loading ||
        _draftCleared ||
        _isManual ||
        _saving ||
        _replacing ||
        _accountLost ||
        _disposing ||
        !_ownsCurrentAccount() ||
        _handlingLiveAction ||
        _drafts.clearCount != _draftClearCount) {
      return false;
    }
    // Set eylemi yalnız kartın gösterdiği sete uygulanır: arada set
    // değiştiyse (gecikmiş ya da çift dokunuş) sıradaki set tamamlanmaz
    // (Codex incelemesi, 2026-10-12).
    final next = _nextLiveSet();
    final sameSet = next != null && setKey == next.key;
    final deadline = _restDeadline;
    final resting = deadline != null && deadline.isAfter(DateTime.now());
    final sameRest = resting && setKey == _liveRestTarget.keyFor(deadline);
    // Tamamlama toggle değildir: yalnız hâlâ geçerli, gösterilen hedefe
    // uygulanır. Native beklerken ikinci komut durumu değiştiremez.
    _handlingLiveAction = true;
    try {
      switch (action) {
        case LiveAction.completeSet:
          if (resting || !sameSet || !next.canComplete) return false;
          _toggleDone(next.exercise, next.set);
        case LiveAction.stepDown:
        case LiveAction.stepUp:
          if (resting || !sameSet || !_canStep(next.exercise)) return false;
          _stepLive(
            next.exercise,
            next.set,
            next.index,
            action == LiveAction.stepUp ? 1 : -1,
          );
        case LiveAction.addRest:
          if (!sameRest) return false;
          _bumpRest(15);
        case LiveAction.skipRest:
          if (!sameRest) return false;
          _skipRest();
      }
      // Taslak, mola sesi/bildirimi ve kart güncellemesi bitmeden dönme:
      // perform() dönünce sistem uygulamayı uyutur, yarım iş kalırdı.
      await Future.wait([_saveDraft(), _restSetup ?? Future<void>.value()]);
      if (!_ownsCurrentAccount() || _draftCleared ||
          _drafts.clearCount != _draftClearCount || _disposing) {
        return false;
      }
      await _live.flush();
      return _ownsCurrentAccount() && !_draftCleared &&
          _drafts.clearCount == _draftClearCount && !_disposing;
    } finally {
      _handlingLiveAction = false;
      _releaseAccountWatch();
    }
  }

  /// Kilit ekranındaki "şu anki set": sırayla ilk tamamlanmamış set.
  /// [canComplete]: değeri girilmiş ya da öneriyle dolacak — boş set kilit
  /// ekranından işaretlenmez (değersiz kayıt üretirdi).
  ({
    SessionExerciseEntry exercise,
    SessionSetEntry set,
    int index,
    String key,
    bool canComplete,
  })? _nextLiveSet() {
    final pos = livePosition(
        [for (final e in _exercises) [for (final s in e.sets) s.done]]);
    if (pos == null) {
      // Son set uygulamadan geri alınırsa eski tamamla komutu canlanmasın.
      _liveSetTarget.clear();
      return null;
    }
    final ex = _exercises[pos.exercise];
    final set = ex.sets[pos.set];
    return (
      exercise: ex,
      set: set,
      index: pos.set,
      // Nesne kimliği yinelenen hareketi/yeniden eklenen seti ayırır.
      // Değer veya kilo adımı değişince eski kart komutu da bayatlar.
      key: _liveSetTarget.keyFor((
        set, _shownValues(ex, set, pos.set), set.type, ex.restSec,
        _canStep(ex) && ex.measure != 'reps'
            ? _stepKgFor(ex, ref.read(weightStepPrefsProvider)) : null,
        ref.read(unitsProvider).imperial,
      )),
      canComplete: set.hasInput(ex.measure) || ex.suggestionAt(pos.set) != null,
    );
  }

  /// Kartta (ve ✓'de) geçerli değerler: girilen değer önce, boş alan
  /// öneriden — `_toggleDone`'un kaydedeceğiyle aynı (G-2).
  SetValues _shownValues(SessionExerciseEntry ex, SessionSetEntry set, int index) {
    final suggestion = ex.suggestionAt(index);
    return suggestion == null
        ? set.values
        : fillMissing(set.values, suggestion, ex.measure);
  }

  /// Kilit ekranı ± yalnız kilo×tekrar (kilo adımı) ve tekrar (±1)
  /// hareketlerinde; süre/mesafede yok.
  bool _canStep(SessionExerciseEntry ex) =>
      ex.measure != 'time' && ex.measure != 'distance';

  /// Kilit ekranı ±: yalnız bu setin tek alanını değiştirir (kilo ya da
  /// tekrar); boşsa öneriden başlar. Sonraki setlere ve öneriye dokunmaz.
  void _stepLive(SessionExerciseEntry ex, SessionSetEntry set, int index, int dir) {
    if (ex.measure == 'reps') {
      final from = set.reps ?? ex.suggestionAt(index)?.reps ?? 0;
      setState(() {
        set.reps = (from + dir).clamp(0, 999);
        set.fillGen++;
      });
    } else {
      _stepWeight(ex, set, dir);
    }
    _saveDraft(); // arka planda: gecikmeli yazım tetiklenmeyebilir
  }

  // ───────── taslak (draft) ─────────

  WorkoutDraft _buildDraft([List<SessionExerciseEntry>? exercises]) => WorkoutDraft(
        title: _title,
        routineId: _routineId,
        startedAtMs: _startedAt.millisecondsSinceEpoch,
        sessionDateMs: _sessionDate.millisecondsSinceEpoch,
        restStartedAtMs: _restStartedAt?.millisecondsSinceEpoch,
        restEndsAtMs: _restDeadline?.millisecondsSinceEpoch,
        lastDoneAtMs: _lastDoneAt?.millisecondsSinceEpoch,
        exercises: (exercises ?? _exercises).map((e) => e.toDraft()).toList(),
      );

  /// Kilit ekranı / Dynamic Island (docs/32): yalnız canlı seansta. Şu
  /// anki hareket + set, sıradaki setin hedefi, dinlenme bitişi. Aynı durum
  /// tekrar gönderilmez (servis karşılaştırır).
  void _syncLive() {
    if (_isManual ||
        _replacing ||
        _accountLost ||
        _loading ||
        _loadError != null ||
        _draftCleared ||
        _drafts.clearCount != _draftClearCount ||
        _disposing ||
        !mounted) {
      return;
    }
    if (!_ownsCurrentAccount()) return;
    final l = AppL10n.of(context);
    final units = ref.read(unitsProvider);
    final next = _nextLiveSet();
    final total = _exercises.fold<int>(0, (n, e) => n + e.sets.length);
    final done = _exercises.fold<int>(
        0, (n, e) => n + e.sets.where((s) => s.done).length);
    final String exercise, setLabel, target;
    if (next == null) {
      exercise = _exercises.isEmpty ? _title : _exercises.last.exercise.name;
      setLabel = l.liveAllDone;
      target = '';
    } else {
      final ex = next.exercise;
      exercise = ex.exercise.name;
      setLabel = l.liveSetLabel(next.index + 1, ex.sets.length);
      final v = _shownValues(ex, next.set, next.index);
      target = switch (ex.measure) {
        'reps' => v.reps == null ? '' : '× ${v.reps}',
        'time' => v.durationSec == null ? '' : fmtDuration(v.durationSec!),
        'distance' => v.distanceM == null
            ? ''
            : '${units.distanceValue(v.distanceM!)} ${units.distanceUnit}',
        _ => [
            if (v.weightKg != null) units.lift(v.weightKg!),
            if (v.reps != null) '× ${v.reps}',
          ].join(' '),
      };
    }
    final deadline = _restDeadline;
    final resting = deadline != null && deadline.isAfter(DateTime.now());
    if (deadline == null) _liveRestTarget.clear();
    final step = next == null || !_canStep(next.exercise)
        ? (down: '', up: '')
        : next.exercise.measure == 'reps'
            ? (down: '−1 ${l.unitReps}', up: '+1 ${l.unitReps}')
            : () {
                final kg = units.lift(
                    _stepKgFor(next.exercise, ref.read(weightStepPrefsProvider)));
                return (down: '−$kg', up: '+$kg');
              }();
    _live.show(
      title: _title,
      startedAt: _startedAt,
      state: WorkoutLiveState(
        exercise: exercise,
        setLabel: setLabel,
        target: target,
        restStartedAt: resting ? _restStartedAt : null,
        restEndsAt: resting ? deadline : null,
        doneSets: done,
        totalSets: total,
        canComplete: next?.canComplete ?? false,
        setKey: next?.key ?? '',
        restKey: resting ? _liveRestTarget.keyFor(deadline) : '',
        stepDownLabel: step.down,
        stepUpLabel: step.up,
      ),
      labels: WorkoutLiveLabels(
        rest: l.labelRest,
        restOver: l.liveRestOver,
        next: l.liveNext,
        completeSet: l.liveCompleteSet,
        addRest: l.liveAddRest,
        skipRest: l.liveSkipRest,
        elapsed: l.liveElapsed,
      ),
    );
  }

  /// Taslağı hemen yazar; bekleyen gecikmeli yazım varsa onu da karşılar
  /// (yazılan anlık durum, bekleyen değişikliği zaten içerir).
  Future<void> _saveDraft() async {
    _draftDebounce?.cancel();
    _draftDebounce = null;
    // Yükleme hatasında bellek boş — diskteki taslağın üstüne yazılmaz.
    if (!_draftable || _draftCleared || _loading || _loadError != null ||
        _committingReplacement || !_ownsCurrentAccount()) {
      return;
    }
    if (_drafts.clearCount != _draftClearCount) return;
    _syncLive();
    _pendingDraftWrites++;
    try {
      if (await _drafts.saveIfCurrent(_buildDraft(),
          expectedClearCount: _draftClearCount,
          isCurrent: () => _ownsCurrentAccount() && !_draftCleared)) {
        _replacementDirty = false;
      }
    } finally {
      _pendingDraftWrites--;
      _releaseAccountWatch();
    }
  }

  /// Set alanına yazılan değer: her tuşta değil, yazım [_draftSaveDelay]
  /// kadar durunca kaydedilir. Bekleyen yazım arka plana geçişte
  /// ([didChangeAppLifecycleState]) ve ekran kapanışında ([dispose]) hemen
  /// tamamlanır. Kalan kayıp penceresi yalnız ani kapanmada (çökme, pil
  /// bitmesi, sistemin uygulamayı arka plan olayı vermeden öldürmesi): son
  /// tuştan sonraki en fazla [_draftSaveDelay] + diske yazma süresi.
  void _scheduleDraftSave() {
    if (_committingReplacement) {
      _replacementDirty = true;
      return;
    }
    if (!_draftable || _draftCleared || _accountLost) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(_draftSaveDelay, _saveDraft);
  }

  void _clearDraft() {
    if (!_ownsCurrentAccount() || _drafts.clearCount != _draftClearCount) {
      _draftCleared = true;
      return;
    }
    _draftCleared = true;
    _live.end(); // seans bitti ya da atıldı — kilit ekranından kalksın
    _draftDebounce?.cancel();
    _drafts.clear();
    ref.invalidate(activeDraftProvider); // banner kalksın
  }

  /// Taslaktan hareketleri yeniden kurar (resume modu).
  Future<void> _restoreFromDraft(WorkoutDraft d) async {
    final dao = ref.read(workoutDaoProvider);
    _title = d.title;
    _routineId = d.routineId;
    _startedAt = d.startedAt;
    _sessionDate = d.sessionDate;
    _lastDoneAt = d.lastDoneAt;
    // Süren dinlenme (uygulama arka planda öldürüldü): kaldığı yerden sürer.
    final restEnds = d.restEndsAt;
    if (restEnds != null && restEnds.isAfter(DateTime.now())) {
      _restDeadline = restEnds;
      _restStartedAt = d.restStartedAt;
    }
    // Hedef tekrar aralıkları rutinde — ilerleme önerisi için yeniden okunur.
    final targets = <int, RoutineExercise>{
      if (d.routineId != null)
        for (final it in await dao.getRoutineExercises(d.routineId!))
          it.exercise.id: it.routineExercise,
    };
    for (final de in d.exercises) {
      final ex = await dao.getExerciseById(de.exerciseId);
      if (ex == null) continue; // silinmiş/arşivlenmiş hareketi atla
      final lastSets = await dao.getLastSessionSetsForExercise(ex.id);
      final prevSets = await dao.getPreviousSessionSetsForExercise(ex.id);
      final se = SessionExerciseEntry(
        ex,
        de.sets
            .map(SessionSetEntry.fromDraft)
            .toList(),
        // Geçen seans taslakta değil DB'de — devam ederken yeniden okunur.
        lastSets: lastSets,
        restSec: de.restSec,
        inRoutine: !de.sessionOnly && targets.containsKey(ex.id),
        sessionOnly: de.sessionOnly,
        units: ref.read(unitsProvider),
        advice: de.sessionOnly ? null :
            _adviceFor(ex, lastSets, prevSets, targets[ex.id]),
        appliedIncrementKg: de.appliedIncrementKg,
      );
      await _loadBests(se);
      _exercises.add(se);
    }
  }

  /// Sonraki hedef önerisi (docs/21 #3): yalnız canlı seansta, rutin hedefi
  /// olan kilo×tekrar harekette. Isınma setleri hesaba katılmaz.
  /// RPE (docs/29): geçen seansın set RPE'leri ve sondan ikinci seans da
  /// girer — tükenişte +1 tekrar zorlanmaz, iki seans üst üste takılınca
  /// kilo düşürme önerilir.
  ProgressionAdvice? _adviceFor(Exercise ex, List<WorkoutSet> lastSets,
      List<WorkoutSet> prevSets, RoutineExercise? target) {
    if (_isManual || target == null || ex.measurementType != 'weight_reps') {
      return null;
    }
    final working = [for (final s in lastSets) if (!s.isWarmup) s];
    return progressionFor(
      lastWorkingSets: [for (final s in working) SetValues.fromSet(s)],
      lastRpe: [for (final s in working) s.rpe],
      previousWorkingSets: [
        for (final s in prevSets)
          if (!s.isWarmup) SetValues.fromSet(s),
      ],
      repsMin: target.targetRepsMin,
      repsMax: target.targetRepsMax,
    );
  }

  /// Öneriyi uygula / geri al — yalnız bu seansın önerilerini değiştirir,
  /// girilmiş ve tamamlanmış setlere dokunmaz.
  void _toggleAdvance(SessionExerciseEntry ex) {
    setState(() {
      ex.appliedIncrementKg = ex.appliedIncrementKg == null
          ? ref.read(effectiveIncrementKgProvider)
          : null;
    });
    _saveDraft();
  }

  Future<void> _pickSessionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now, // gelecek tarih kapalı
    );
    if (picked != null) {
      setState(() =>
          _sessionDate = DateTime(picked.year, picked.month, picked.day));
      _saveDraft();
    }
  }

  void _releaseAccountWatch() {
    if (_disposing && _pendingDraftWrites == 0 &&
        !_handlingLiveAction && !_replacing) {
      _accountWatch?.close();
      _accountWatch = null;
    }
  }

  @override
  void dispose() {
    _disposing = true; // _saveDraft → _syncLive context'e dokunmasın
    _ticker?.cancel();
    _restTimer?.cancel();
    _restSoundOrNull?.dispose(restRunning: _restDeadline != null);
    // Yazıp hemen ekrandan çıkıldıysa bekleyen yazımı tamamla. _saveDraft
    // ref kullanmaz; temizlenmiş/başka yerden silinmiş taslağı yazmaz.
    if ((_draftDebounce?.isActive ?? false) || _replacementDirty) _saveDraft();
    if (!_isManual) {
      _live.detach(_onLiveAction);
      if (!_accountLost) _live.end();
      WidgetsBinding.instance.removeObserver(this);
      WakelockPlus.disable();
    }
    _releaseAccountWatch();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(workoutDaoProvider);
    // Resume modu: routine yerine kaydedilmiş taslaktan kur.
    if (widget.resume) {
      final draft = await _drafts.load();
      if (draft != null) await _restoreFromDraft(draft);
      if (mounted) setState(() => _loading = false);
      if (mounted && _restDeadline != null) {
        _tickRest();
        _scheduleRestTick();
        _armRestAlarm();
      }
      _syncLive();
      return;
    }
    if (widget.routineId != null) {
      final routine = await dao.getRoutine(widget.routineId!);
      final exs = await dao.getRoutineExercises(widget.routineId!);
      _title = routine?.name ??
          (mounted ? AppL10n.of(context).navWorkout : 'Workout');
      for (final it in exs) {
        // Kardiyo/süre/mesafe hareketleri tek "set" ile başlar; ağırlık
        // hareketleri rutin hedefi kadar (varsayılan 3).
        final isCardioLike = it.exercise.measurementType == 'time' ||
            it.exercise.measurementType == 'distance';
        final count = isCardioLike ? 1 : (it.routineExercise.targetSets ?? 3);
        final lastSets =
            await dao.getLastSessionSetsForExercise(it.exercise.id);
        final prevSets =
            await dao.getPreviousSessionSetsForExercise(it.exercise.id);
        final se = SessionExerciseEntry(
          it.exercise,
          List.generate(count, (_) => SessionSetEntry()),
          lastSets: lastSets,
          restSec: it.routineExercise.targetRestSec ??
              WorkoutUi.defaultRestSec(it.exercise.category),
          inRoutine: true,
          units: ref.read(unitsProvider),
          advice: _adviceFor(
              it.exercise, lastSets, prevSets, it.routineExercise),
        );
        await _loadBests(se); // anlık rekor rozeti için seans öncesi en iyiler
        _exercises.add(se);
      }
    }
    if (mounted) setState(() => _loading = false);
    _syncLive();
    _saveDraft(); // başlangıç taslağını yaz (boş bile olsa resume hedefi olur)
    // Bildirim izni seans başında, ilk set ✓'sinde değil (deneyim
    // araştırması A2 #12): sette soru penceresi antrenmanı kesiyordu.
    if (!_isManual && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _inForeground) _offerRestNotificationOnce();
      });
    }
    // Geçmiş kayıt (C-18): akışın ilk sorusu "hangi gün?" — tarih seçici
    // kendiliğinden açılır; vazgeçilirse bugün kalır.
    if (_isManual && widget.pickDateOnOpen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickSessionDate();
      });
    }
  }

  bool get _hasData => _exercises
      .any((e) => e.sets.any((s) => s.hasInput(e.measure) || s.done));

  /// Hareketin seans öncesi en iyi değerlerini yükler (anlık rekor rozeti).
  /// Geçmiş kayıt modunda anlamsız (rekoru özet ekranı tarihe göre hesaplar);
  /// ağırlık dışı ölçümlerde rekor tanımı yok (Rekorlar sekmesiyle tutarlı).
  Future<void> _loadBests(SessionExerciseEntry ex) async {
    if (_isManual) return;
    final m = ex.measure;
    if (m == 'time' || m == 'distance' || m == 'reps') return;
    final history =
        await ref.read(workoutDaoProvider).getExerciseHistory(ex.exercise.id);
    final b = bestsOf(history);
    ex.bestE1rm = b.e1rm;
    ex.bestWeightKg = b.weightKg;
  }

  // ───────── set işlemleri ─────────

  /// Tamamlanan set kişisel rekor mu? (canlı mod; geçmişi olmayan hareket
  /// rozetlenmez — record_calc kuralı). Rekorsa işaretle + güçlü titreşim.
  void _checkRecord(SessionExerciseEntry ex, SessionSetEntry set) {
    if (_isManual || set.type == 'warmup') return;
    if (ex.bestE1rm <= 0 && ex.bestWeightKg <= 0) return; // geçmiş yok
    final w = set.weight;
    final e1 = epley(w, set.reps);
    var record = false;
    if (e1 != null && e1 > ex.bestE1rm) {
      ex.bestE1rm = e1;
      record = true;
    }
    if (w != null && w > ex.bestWeightKg) {
      ex.bestWeightKg = w;
      record = true;
    }
    if (record) {
      set.isRecord = true;
      _feedback.record();
    }
  }

  void _toggleDone(SessionExerciseEntry ex, SessionSetEntry set) {
    // ✓ klavyeyi her zaman kapatır (A5): yazılan alan açık kalıp sıradaki
    // dokunuşu kaydırmasın.
    _dismissKeyboard();
    // Boş set tamamlanmaz (A2 #5): değer yok, öneri de yok → kayıtsız set +
    // gereksiz mola. Geçerlilik ölçüm türüne göre (hasInput).
    if (!set.done &&
        !set.hasInput(ex.measure) &&
        ex.suggestionAt(ex.sets.indexOf(set)) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).asEnterValueFirst)));
      return;
    }
    setState(() {
      // G-2: tamamlanırken boş alanlar öneriyle dolar (tek dokunuş = onay).
      // Geri alırken değerler kalır — kullanıcı düzeltip yeniden işaretler.
      if (!set.done) _fillFromSuggestion(ex, set);
      set.done = !set.done;
      if (set.done) {
        _checkRecord(ex, set);
      } else {
        // Geri alındı: rozeti kaldır. ex.best* bilerek düşürülmez — aynı
        // değer yeniden girilirse tekrar rozetlenmez (güvenli taraf).
        set.isRecord = false;
      }
    });
    if (set.done) {
      _lastDoneAt = DateTime.now();
      _feedback.setDone();
      // Hareketin kullanıcı tarafından belirlenen dinlenme süresi (0 = yok).
      // Geçmiş kayıt modunda dinlenme sayacı anlamsız — canlı değil.
      if (!_isManual && ex.restSec > 0) _startRest(ex.restSec);
    }
    _saveDraft();
  }

  void _fillFromSuggestion(SessionExerciseEntry ex, SessionSetEntry set) {
    final suggestion = ex.suggestionAt(ex.sets.indexOf(set));
    if (suggestion == null) return;
    final filled = fillMissing(set.values, suggestion, ex.measure);
    if (filled == set.values) return;
    set.apply(filled);
    set.fillGen++;
  }

  /// Set türü artık döngüyle değil seçenek panelinden (A5 #10): rozete
  /// kazara dokunuş türü sessizce değiştirmesin.
  void _setType(SessionSetEntry set, String type) {
    if (set.type == type) return;
    setState(() => set.type = type);
    _saveDraft();
  }

  void _addSet(SessionExerciseEntry ex) {
    setState(() => ex.sets.add(SessionSetEntry()));
    _saveDraft();
  }

  void _removeSet(SessionExerciseEntry ex) {
    if (ex.sets.length > 1) {
      setState(() => ex.sets.removeLast());
      _saveDraft();
    }
  }

  /// Hareketi seanstan kaldır. Veri girilmişse önce onay sor.
  Future<void> _removeExercise(SessionExerciseEntry ex) async {
    final hasData = ex.sets.any((s) => s.hasInput(ex.measure) || s.done);
    if (hasData) {
      final ok = await confirmAction(
        context,
        title: AppL10n.of(context).asRemoveExercise,
        message: AppL10n.of(context).asRemoveExerciseMsg(ex.exercise.name),
        confirmLabel: AppL10n.of(context).asRemove,
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() => _exercises.remove(ex));
    _saveDraft();
  }

  /// Hareketi seans içinde bir yukarı/aşağı taşır (A1). Rutin değişmez;
  /// yeni sıra taslağa ve kayda (setler bu sırayla yazılır) yansır.
  void _moveExercise(SessionExerciseEntry ex, int delta) {
    final i = _exercises.indexOf(ex);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= _exercises.length) return;
    _dismissKeyboard();
    setState(() {
      _exercises.removeAt(i);
      _exercises.insert(j, ex);
    });
    _saveDraft();
    // Taşınan kart ekranda kalsın — kullanıcı nereye gittiğini görsün.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = GlobalObjectKey(ex).currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx,
            duration: AppDuration.normal, alignmentPolicy:
                delta < 0
                    ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
                    : ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  /// Menü/seçici/± kullanılınca klavye kapanır. Açık alan, menü ya da sheet
  /// kapanınca odağı geri alıp klavyeyi yeniden açıyor ve listeyi o alana
  /// kaydırıyordu (emülatörde görüldü, 2026-09-30) — ikinci çağrı o geri
  /// dönüşü yakalar.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => FocusManager.instance.primaryFocus?.unfocus());
  }

  /// Hareketin dinlenme süresini değiştir (A2). Rutindeki hareketse süre
  /// sormadan rutine de yazılır (Samet 2026-09-30) — sonraki antrenman bu
  /// süreyle başlar. Çalışan sayaç etkilenmez; yeni süre sonraki setten
  /// itibaren geçerli.
  Future<void> _pickRest(SessionExerciseEntry ex) async {
    _dismissKeyboard();
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => RestPickerSheet(
          current: ex.restSec, savesToRoutine: ex.inRoutine),
    );
    _dismissKeyboard();
    if (picked == null || picked == ex.restSec || !mounted) return;
    setState(() => ex.restSec = picked);
    _saveDraft();
    final routineId = _routineId;
    if (!ex.inRoutine || routineId == null) return;
    try {
      await ref.read(workoutDaoProvider).setRoutineExerciseRest(
          routineId: routineId, exerciseId: ex.exercise.id, restSec: picked);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppL10n.of(context).asRestSaveError)));
      }
    }
  }

  /// Hareketin kilo adımı (A4): seçilen → geçmişten tahmin → ekipman.
  double _stepKgFor(SessionExerciseEntry ex, Map<int, double> saved) =>
      saved[ex.exercise.id] ??
      inferStepKg([
        for (final s in ex.lastSets)
          if (s.weightKg != null) s.weightKg!,
        for (final s in ex.sets)
          if (s.weight != null) s.weight!,
      ]) ??
      defaultStepKg(ex.exercise.equipment, ref.read(unitsProvider));

  /// ± düğmesi: boş alanda öneriden başlar. Dokunuş kullanıcı girişi
  /// sayılır — değer alana yazılır (✓ onayı yine gerekir).
  void _stepWeight(SessionExerciseEntry ex, SessionSetEntry set, int direction) {
    final base = ex.suggestionAt(ex.sets.indexOf(set))?.weightKg;
    final step = _stepKgFor(ex, ref.read(weightStepPrefsProvider));
    _dismissKeyboard();
    setState(() {
      set.weight = applyStepKg(
          current: set.weight, base: base, stepKg: step, direction: direction);
      set.fillGen++;
    });
    _scheduleDraftSave();
  }

  Future<void> _pickStep(SessionExerciseEntry ex) async {
    _dismissKeyboard();
    final current = _stepKgFor(ex, ref.read(weightStepPrefsProvider));
    final picked = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (_) => StepPickerSheet(currentKg: current),
    );
    _dismissKeyboard();
    if (picked == null) return;
    await ref.read(weightStepPrefsProvider.notifier).set(ex.exercise.id, picked);
    if (mounted) _syncLive();
  }

  Future<void> _addExercise() async {
    final ex = await context.push<Exercise>(AppRoutes.exercisesSelect);
    if (ex == null) return;
    final lastSets =
        await ref.read(workoutDaoProvider).getLastSessionSetsForExercise(ex.id);
    if (!mounted) return;
    final se = SessionExerciseEntry(
      ex,
      List.generate(1, (_) => SessionSetEntry()),
      lastSets: lastSets,
      restSec: WorkoutUi.defaultRestSec(ex.category),
      units: ref.read(unitsProvider),
    );
    await _loadBests(se);
    if (!mounted) return;
    setState(() => _exercises.add(se));
    _saveDraft();
  }

  /// Yalnız seçilen blok değişir. Önce planı diske yaz, başarıdan sonra
  /// ekrana uygula; hata/iptal sırasında eski blok ve yazılmış alanlar kalır.
  Future<void> _replaceExercise(SessionExerciseEntry source) async {
    if (_replacing ||
        _saving ||
        _handlingLiveAction ||
        _isManual ||
        _accountLost ||
        (source.measure != 'weight_reps' && source.measure != 'reps') ||
        _drafts.clearCount != _draftClearCount) {
      return;
    }
    final owner = ref.read(currentUserProvider)?.id;
    if (owner != _sessionOwner) return;
    final dao = ref.read(workoutDaoProvider);
    final units = ref.read(unitsProvider);
    bool ownsDraft() =>
        !_draftCleared &&
        _drafts.clearCount == _draftClearCount &&
        _ownsCurrentAccount();
    bool ownsSession() => mounted && !_disposing && !_saving && ownsDraft();
    bool valid() => ownsSession() && _exercises.contains(source);
    var committed = false;
    _dismissKeyboard();
    setState(() => _replacing = true);
    try {
      // Seçici açıkken uygulama kapanırsa mevcut alanlar zaten taslakta.
      await _saveDraft();
      if (!mounted || !valid()) return;
      final l = AppL10n.of(context);
      final confirmed = await confirmAction(
        context,
        title: l.asReplaceExercise,
        message: l.asReplaceExplanation,
        confirmLabel: l.asReplaceChoose,
      );
      if (!mounted || !confirmed || !valid()) return;
      final chosen = await context.push<Exercise>(AppRoutes.exercisesSelect);
      if (!valid() || chosen == null || chosen.id == source.exercise.id) return;
      final lastSets = await dao.getLastSessionSetsForExercise(chosen.id);
      if (!mounted || !valid()) return;
      final planned = replaceSessionExercise(
        exercises: _exercises,
        source: source,
        replacement: chosen,
        lastSets: lastSets,
        units: units,
      );
      final replacement = planned.firstWhere(
        (e) => e.exercise.id == chosen.id && !_exercises.contains(e),
      );
      await _loadBests(replacement);
      if (!mounted || !valid()) return;
      // Lifecycle yazımı eski görünümü bu adayın üstüne yazmamalı.
      _committingReplacement = true;
      _replacementDirty = false;
      final saved = await _drafts.saveIfCurrent(
        _buildDraft(planned),
        expectedClearCount: _draftClearCount,
        isCurrent: ownsDraft,
      );
      if (!saved || !ownsDraft()) return;
      committed = true;
      if (valid()) {
        setState(() {
          _exercises..clear()..addAll(planned);
          _liveSetTarget.clear();
        });
        ref.invalidate(activeDraftProvider);
      }
      // Başka bir hareketin süre sayacı, seçim sırasında kendiliğinden
      // bitebilir. Paylaşılan set nesnesindeki yeni süreyi aday taslağa yaz;
      // ekran bu sırada kapansa bile aynı hesabın kaydı tamamlanır.
      while (_replacementDirty && ownsDraft()) {
        _replacementDirty = false;
        if (!await _drafts.saveIfCurrent(_buildDraft(planned),
            expectedClearCount: _draftClearCount, isCurrent: ownsDraft)) {
          return;
        }
      }
    } catch (_) {
      if (committed) _replacementDirty = true;
      if (mounted && ownsSession()) {
        final l = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(committed ? l.asDraftSaveError : l.asReplaceError)));
      }
    } finally {
      _committingReplacement = false;
      _replacing = false;
      _releaseAccountWatch();
      if (mounted) {
        setState(() {});
        if (!_accountLost) _syncLive();
      }
    }
  }

  // ───────── dinlenme sayacı ─────────

  void _startRest(int seconds) {
    _restTimer?.cancel();
    final now = DateTime.now();
    _restStartedAt = now;
    _restDeadline = now.add(Duration(seconds: seconds));
    _tickRest();
    _scheduleRestTick();
    _restSetup = _armRestAlarm();
    _announce(AppL10n.of(context).asRestStarted(fmtDuration(seconds)));
    _syncLive();
  }

  /// Ekran okuyucuya kısa duyuru (A6): mola başlangıcı ve bitişi. Sayaç her
  /// saniye okunmaz; yalnız bu iki an.
  void _announce(String message) {
    if (!mounted || !_inForeground) return;
    unawaited(SemanticsService.sendAnnouncement(
        View.of(context), message, Directionality.of(context)));
  }

  /// İlk molada bildirim iznini bir kez ister — izin yoksa uygulama alttayken
  /// mola sonu hiç bildirilmez (iPhone'da Dart sayacı arka planda durur).
  /// Reddedilirse bir daha sormaz; Ayarlar → Bildirimler'den açılır.
  Future<void> _offerRestNotificationOnce() async {
    final notifier = ref.read(notificationPrefsProvider.notifier);
    if (!ref.read(notificationPrefsProvider).shouldOfferRest) return;
    await notifier.update(
        ref.read(notificationPrefsProvider).copyWith(restPrompted: true));
    bool ok;
    try {
      ok = await ref.read(notificationServiceProvider).requestPermission();
    } catch (_) {
      // İzin servisi yok (test/eklenti hatası): seans etkilenmesin, Ayarlar'dan
      // yine açılabilir. Bilinçli sessiz — molanın ortasında hata mesajı olmaz.
      return;
    }
    if (!ok || !mounted) return;
    await notifier.update(
        ref.read(notificationPrefsProvider).copyWith(restEnabled: true));
    // İzin mola sürerken geldi: Android servisi "bitti" bildirimini bilsin.
    if (mounted && _restDeadline != null) _armRestAlarm();
  }

  /// Mola sonu sesini/titreşimini kurar ya da yeniler (±15 sn) — docs/25.
  ///
  /// Android: yerel ön plan servisi — uygulama alttayken ve ekran kapalıyken
  /// de zamanında çalar, bildirimde canlı geri sayım gösterir.
  /// Diğer (iOS, servis başlatılamadı): uygulama içi zamanlayıcı, bitişten
  /// 3 sn önce tek parça geri sayım sesini başlatır.
  Future<void> _armRestAlarm() async {
    final deadline = _restDeadline;
    _restSound.resetCountdown();
    if (deadline == null) return;
    final prefs = ref.read(notificationPrefsProvider);
    final native = await _restSound.startNative(
        deadline: deadline, prefs: prefs, l: AppL10n.of(context));
    // Beklerken süre değiştiyse/atlandıysa bu çağrının sonucu eskidi.
    if (!mounted || _restDeadline != deadline) return;
    _restSound.native = native;
    await _syncRestNotification();
    if (native || !prefs.restSoundEnabled) return;
    _restSound.scheduleCountdown(
        deadline, prefs.restSound, () => _restDeadline == deadline);
  }

  /// Bir sonraki tıkı **hedeften yeniden hesaplayarak** kurar; `Timer.periodic`
  /// kullanılmaz çünkü kaymayı biriktirir (bkz. [restTickDelayMs]).
  /// Yalnız ekrandaki sayıyı günceller — ses tek parça dosyadan gelir.
  void _scheduleRestTick() {
    _restTimer?.cancel();
    final deadline = _restDeadline;
    if (deadline == null) return;
    final leftMs = deadline.difference(DateTime.now()).inMilliseconds;
    if (leftMs <= 0) return;
    _restTimer = Timer(Duration(milliseconds: restTickDelayMs(leftMs)), () {
      _tickRest();
      _scheduleRestTick();
    });
  }

  void _tickRest() {
    if (!mounted) return;
    final deadline = _restDeadline;
    if (deadline == null) return;
    final leftMs = deadline.difference(DateTime.now()).inMilliseconds;
    final left = (leftMs / 1000).ceil();
    final cue = restCueFor(
        prevLeft: _restRemaining, left: left, overdueMs: -leftMs);
    setState(() => _restRemaining = left > 0 ? left : 0);
    // Bitiş titreşimi: Android'de servis veriyor (çift titreşim olmasın).
    if (cue == RestCue.done) {
      _restSound.restDoneIfInApp();
      _announce(AppL10n.of(context).liveRestOver);
    }
    if (left <= 0) {
      _restTimer?.cancel();
      _restDeadline = null;
      _restStartedAt = null;
      _syncLive(); // kilit ekranındaki geri sayım kalksın
    }
  }

  void _bumpRest(int delta) {
    if (_restDeadline == null) return;
    _restDeadline = _restDeadline!.add(Duration(seconds: delta));
    _tickRest();
    // Hedef değişti → sıradaki tık ve ses yeni hedefe göre yeniden kurulur.
    _scheduleRestTick();
    _restSetup = _armRestAlarm();
    _saveDraft(); // kilit ekranı + taslaktaki bitiş anı (_syncLive dahil)
  }

  void _skipRest() {
    _restTimer?.cancel();
    _restDeadline = null;
    _restStartedAt = null;
    _restSound.stop();
    _restSetup = ref.read(notificationServiceProvider).cancelRestDone();
    setState(() => _restRemaining = 0);
    _saveDraft();
  }

  // ───────── bitir / kaydet ─────────

  Future<void> _finish() async {
    final analytics = ref.read(analyticsControllerProvider);
    final analyticsOwner = ref.read(currentUserProvider)?.id;
    final analyticsMode = _routineId == null ? 'free' : 'routine';
    if (_saving || _replacing || _accountLost) return;
    if (!_hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).asNeedOneSet)));
      return;
    }
    // Eksik set varken bitirmek onay ister (A2 #2: 20 setin 5'iyle tek
    // dokunuşta kapanıyordu). Tam seans tek dokunuş kalır; geçmiş kayıtta ✓
    // zorunlu değil, sorulmaz.
    _dismissKeyboard();
    final open = incompleteSetCount(_exercises);
    if (!_isManual && open > 0 && !await _confirmFinishIncomplete(open)) return;
    if (!mounted || _saving || _replacing || _accountLost) return;
    setState(() => _saving = true);
    final dao = ref.read(workoutDaoProvider);

    final int sessionId;
    try {
      // Seans + setler tek transaction'da: yarıda kesilirse DB'de yarım
      // seans kalmaz, taslak da durur → kullanıcı yeniden deneyebilir.
      sessionId = await dao.insertSessionWithSets(
        finishedSessionRow(
          title: _title,
          routineId: _routineId,
          sessionDate: _sessionDate,
          startedAt: _startedAt,
          elapsed: sessionElapsed(
              startedAt: _startedAt,
              now: DateTime.now(),
              lastDoneAt: _lastDoneAt),
          manual: _isManual,
        ),
        (id) => sessionSetRows(id, _exercises),
      );
    } catch (_) {
      // Yazım başarısız: taslak duruyor, veri kaybolmadı. Düğmeyi serbest
      // bırak ki kullanıcı tekrar deneyebilsin.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppL10n.of(context).asSaveError)));
      }
      return;
    }

    // Ölçüm kaydı, kullanıcının seansı kaydedildikten sonra ve beklenmeden.
    unawaited(
      analytics.trackOwned(analyticsOwner, AnalyticsEventName.workoutSaved, {
        'mode': analyticsMode,
        'source': _isManual ? 'historical' : 'live',
      }),
    );
    _clearDraft(); // seans DB'ye yazıldı — taslağı sil
    // docs/44: tercih açıksa canlı seans Sağlık'a yazılır; hata seansı bozmaz.
    unawaited(exportFinishedSession(ref, sessionId).catchError((_) {}));
    // Home/Progress provider'ları reaktif (H-05): seans+setler DB'ye yazılınca
    // momentum hero, haftalık istatistik, seri hepsi kendiliğinden tazelenir —
    // elle invalidate gerekmez (eski kod momentum provider'larını atlıyordu).
    if (mounted) context.pushReplacement(AppRoutes.summary(sessionId));
  }

  Future<bool> _confirmFinishIncomplete(int open) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppL10n.of(ctx);
        return AlertDialog(
          title: Text(l.asFinishIncompleteTitle),
          content: Text(l.asFinishIncompleteMsg(open)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.asKeepGoing)),
            FilledButton(
                key: const ValueKey('session.finishAnyway'),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.asFinishAnyway)),
          ],
        );
      },
    );
    return ok ?? false;
  }

  /// Çıkış penceresi (docs/53): ana düğme "Devam et"; veriyi silen yol
  /// ikincil ve kırmızı. Geçmiş kayıtta taslak yok → kaydet seçeneği yok.
  Future<_ExitChoice> _confirmExit() async {
    if (!_hasData) return _ExitChoice.discard;
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) {
        final l = AppL10n.of(ctx);
        return AlertDialog(
          title: Text(l.asExitTitle),
          content: Text(_draftable ? l.asExitMsg2 : l.asExitMsg),
          actionsOverflowDirection: VerticalDirection.up,
          actions: [
            TextButton(
                key: const ValueKey('session.exit.discard'),
                style: TextButton.styleFrom(foregroundColor: ctx.colors.error),
                onPressed: () => Navigator.pop(ctx, _ExitChoice.discard),
                child: Text(l.asDiscardAndExit)),
            if (_draftable)
              TextButton(
                  key: const ValueKey('session.exit.save'),
                  onPressed: () => Navigator.pop(ctx, _ExitChoice.save),
                  child: Text(l.asSaveAndExit)),
            FilledButton(
                key: const ValueKey('session.exit.keep'),
                onPressed: () => Navigator.pop(ctx, _ExitChoice.keep),
                child: Text(l.asKeepGoing)),
          ],
        );
      },
    );
    return choice ?? _ExitChoice.keep;
  }

  /// Kaydet ve çık (docs/53): taslak yazılır, mola durur; yazım başarısızsa
  /// ekran açık kalır. Sayaç, ses ve kilit ekranı kartını dispose kapatır.
  Future<bool> _saveAndLeave() async {
    _restTimer?.cancel();
    _restDeadline = null;
    _restStartedAt = null;
    _restSound.stop();
    unawaited(ref.read(notificationServiceProvider).cancelRestDone());
    try {
      await _saveDraft();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppL10n.of(context).asDraftSaveError)));
      }
      return false;
    }
    if (mounted) ref.invalidate(activeDraftProvider);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // C-16: kalan işi göster — geçmiş kayıtta ✓ zorunlu değil, gösterilmez.
    final progress = SessionProgress.of(
        _exercises.map((e) => e.sets.map((s) => s.done)));
    final showProgress = !_isManual && !progress.isEmpty;
    final stepPrefs = ref.watch(weightStepPrefsProvider);
    // Ses Ayarlar'dan değişti (docs/45 §3): süren mola yeni sesle kurulsun —
    // eski seçimin çalmaya devam etmesi olmasın.
    ref.listen(notificationPrefsProvider.select((p) => p.restSound),
        (prev, next) {
      if (prev != next && _restDeadline != null) _armRestAlarm();
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _replacing) return;
        final go = GoRouter.of(context);
        _dismissKeyboard();
        switch (await _confirmExit()) {
          case _ExitChoice.keep:
            return;
          case _ExitChoice.save:
            if (await _saveAndLeave() && mounted) go.pop();
          case _ExitChoice.discard:
            if (!mounted) return;
            _clearDraft(); // kullanıcı setleri atmayı onayladı — taslağı sil
            go.pop();
        }
      },
      child: AbsorbPointer(
        absorbing: _replacing,
        child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                  style: context.texts.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  FitPackIcon.material(_isManual ? Icons.history_rounded : Icons.schedule_rounded,
                      size: 13, color: context.colors.primary),
                  const SizedBox(width: 4),
                  Text(_isManual ? AppL10n.of(context).asPastEntry : fmtDuration(_elapsed.inSeconds),
                      style: context.texts.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  if (showProgress)
                    Flexible(
                      child: Text(
                          '  ·  ${AppL10n.of(context).asSetProgress(progress.done, progress.total)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.labelMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ),
                ],
              ),
            ],
          ),
          bottom: showProgress
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(sessionProgressBarHeight),
                  child: SessionProgressBar(progress: progress),
                )
              : null,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.secondary,
                  foregroundColor: context.colors.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  minimumSize: const Size(48, 48),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    // Geçmiş kayıtta bitirilecek canlı bir seans yok → "Kaydet".
                    : Text(_isManual
                        ? AppL10n.of(context).commonSave
                        : AppL10n.of(context).asFinish),
              ),
            ),
          ],
        ),
        // Mola altta, sabit yükseklikte (A5): üstte açılan şerit listeyi her
        // sette 68 pt aşağı itiyor, sıradaki ✓ parmağın altından kayıyordu.
        // Altta görünmesi yalnız görünümü kısaltır; satırlar yerinde kalır.
        // Klavye açıkken çubuk klavyenin arkasında kalır; sayaç kilit ekranında
        // ve klavye kapanınca burada sürer.
        bottomNavigationBar: !_loading && _restRemaining > 0
            ? RestBar(
                remaining: _restRemaining,
                clock: fmtDuration(_restRemaining),
                onMinus: () => _bumpRest(-15),
                onPlus: () => _bumpRest(15),
                onSkip: _skipRest,
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? ErrorState(onRetry: _retryLoad)
            : Column(
                children: [
                  if (_replacing) const LinearProgressIndicator(),
                  SessionDateBar(
                    date: _sessionDate,
                    highlight: _isManual,
                    onTap: _saving ? null : _pickSessionDate,
                  ),
                  Expanded(
                    child: _exercises.isEmpty
                        ? EmptyActiveSession(onAdd: _addExercise)
                        : ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
                            children: [
                              // ObjectKey ŞART (H-02): key'siz listede Flutter
                              // durumu konuma göre eşler; ortadan hareket
                              // silinince alttaki hareketin metin kutuları
                              // silinenin yazısını devralırdı (ekran ≠ kayıt).
                              ..._exercises.indexed.map((ie) {
                                final (i, e) = ie;
                                return ExerciseBlock(
                                    // Global: taşımadan sonra karta
                                    // kaydırmak için bağlamına erişilir.
                                    key: GlobalObjectKey(e),
                                    ex: e,
                                    onMoveUp: i > 0
                                        ? () => _moveExercise(e, -1)
                                        : null,
                                    onMoveDown: i < _exercises.length - 1
                                        ? () => _moveExercise(e, 1)
                                        : null,
                                    // Geçmiş kayıtta sayaç yok → süre de yok.
                                    onPickRest:
                                        _isManual ? null : () => _pickRest(e),
                                    stepKg: _stepKgFor(e, stepPrefs),
                                    onStep: (s, d) => _stepWeight(e, s, d),
                                    onPickStep: () => _pickStep(e),
                                    onToggle: (s) => _toggleDone(e, s),
                                    onSetType: _setType,
                                    onAddSet: () => _addSet(e),
                                    onRemoveSet: () => _removeSet(e),
                                    onRemoveExercise: () => _removeExercise(e),
                                    onReplaceExercise: _isManual ||
                                            (e.measure != 'weight_reps' &&
                                                e.measure != 'reps')
                                        ? null : () => _replaceExercise(e),
                                    onToggleAdvance: () => _toggleAdvance(e),
                                    onChanged: () {
                                      setState(() {});
                                      _scheduleDraftSave();
                                    },
                                  );
                              }),
                              AppSpacing.vGapMd,
                              OutlinedButton.icon(
                                onPressed: _addExercise,
                                icon: const FitPackIcon.material(Icons.add_rounded,
                                    size: AppIconSize.sm),
                                label: Text(AppL10n.of(context).workoutAddExercise),
                              ),
                            ],
                          ),
                  ),
                  // iOS sayı klavyesinde "Bitti" tuşu yok (A5): klavyenin
                  // hemen üstünde Sonraki / Bitti çubuğu.
                  const SessionKeyboardBar(),
                ],
              ),
      ),
      ),
    );
  }
}
