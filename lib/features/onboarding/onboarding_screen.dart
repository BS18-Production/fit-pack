import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../home/providers/home_providers.dart';
import 'onboarding_calc.dart';

/// İlk açılış akışı (P-10 — docs/03-ux-flows.md §3).
///
/// 3 adım: Hoş geldin → Hedef (boy/kilo/hedef kilo/faz) → Hedefler
/// (kalori/protein, fazdan ön-dolu). Tamamla → profil yazılır, başlangıç
/// kilosu ölçüm olarak kaydedilir, onboarded=1, Home'a geçilir.
///
/// Bilinçli erteleme (altyapı bekliyor): AI key girişi (flutter_secure_storage,
/// Aşama 0 T-005) + bildirim izni (P-11). Doküman bu kısımları "daha sonra
/// ekle" diyor; çekirdek hedef kişiselleştirmeye odaklanıldı.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Adım 2 — vücut bilgileri
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  OnboardingPhase _phase = OnboardingPhase.cut;
  String? _gender; // 'male' | 'female' — günlük enerji tahmini için (opsiyonel)
  DateTime? _birthDate; // yaş — günlük enerji tahmini için (opsiyonel)

  // Adım 3 — hedefler
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  bool _goalsEdited = false; // kullanıcı elle değiştirdiyse üzerine yazma

  bool _saving = false;

  static const _lastPage = 2;

  @override
  void dispose() {
    _pageController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    super.dispose();
  }

  double? get _weight => double.tryParse(_weightCtrl.text.replaceAll(',', '.'));

  /// Faz/kilo değişince hedefleri yeniden öner (kullanıcı elle dokunmadıysa).
  void _refreshSuggestedGoals() {
    if (_goalsEdited) return;
    final w = _weight;
    if (w == null || w <= 0) return;
    final g = suggestGoals(weightKg: w, phase: _phase);
    _kcalCtrl.text = g.kcal.toString();
    _proteinCtrl.text = g.protein.toString();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < _lastPage) {
      if (_page == 1) _refreshSuggestedGoals();
      _pageController.nextPage(
        duration: AppDuration.normal,
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_page == 0) return;
    _pageController.previousPage(
      duration: AppDuration.normal,
      curve: Curves.easeInOut,
    );
  }

  /// İleri tuşu, mevcut adımın zorunlu alanları doluysa aktif olur.
  bool get _canAdvance {
    switch (_page) {
      case 1:
        return _weight != null && _weight! > 0;
      case 2:
        final kcal = int.tryParse(_kcalCtrl.text);
        final protein = int.tryParse(_proteinCtrl.text);
        return kcal != null && kcal > 0 && protein != null && protein > 0;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    // Hedefler sayı olarak okunamıyorsa kaydetmeye hiç girme — kullanıcıya
    // söyle (M-10: eski int.parse boş alanda sessizce çöküyordu).
    final kcal = int.tryParse(_kcalCtrl.text);
    final protein = int.tryParse(_proteinCtrl.text);
    if (kcal == null || protein == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kalori ve protein hedefini sayı olarak gir')));
      return;
    }
    setState(() => _saving = true);
    try {
      final height = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
      final goalWeight =
          double.tryParse(_goalWeightCtrl.text.replaceAll(',', '.'));

      await ref.read(userProfileDaoProvider).completeOnboarding(
            kcalGoal: kcal,
            proteinGoal: protein,
            phase: _phase.dbValue,
            heightCm: height,
            goalWeightKg: goalWeight,
            birthDate: _birthDate,
            gender: _gender,
            // Günlük enerji tahmini için makul varsayılan; Ayarlar'dan değişir.
            activityLevel: 'moderate',
          );

      // Başlangıç kilosunu ilk ölçüm olarak kaydet → grafik 1. noktasını alır.
      final w = _weight;
      if (w != null && w > 0) {
        await ref.read(bodyDaoProvider).insertMeasurement(
              BodyMeasurementsCompanion(
                date: Value(DateTime.now()),
                weightKg: Value(w),
              ),
            );
      }

      // Home ekranı taze profili + kiloyu görsün (H-05: kilo okuyan tüm
      // provider'lar).
      ref.invalidate(userProfileProvider);
      ref.invalidate(latestWeightProvider);
      ref.invalidate(weightTrendProvider);

      if (mounted) context.go('/home');
    } catch (_) {
      // Kayıt başarısız — kullanıcı bilsin ve tekrar deneyebilsin (M-10:
      // eskiden hata sessizce yutulup düğme takılı kalıyordu).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kaydedilemedi — tekrar dene')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressDots(current: _page, total: _lastPage + 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  _GoalSetupPage(
                    heightCtrl: _heightCtrl,
                    weightCtrl: _weightCtrl,
                    goalWeightCtrl: _goalWeightCtrl,
                    phase: _phase,
                    gender: _gender,
                    birthDate: _birthDate,
                    onGenderChanged: (g) => setState(() => _gender = g),
                    onBirthDateChanged: (d) => setState(() => _birthDate = d),
                    onPhaseChanged: (p) => setState(() {
                      _phase = p;
                      _refreshSuggestedGoals();
                    }),
                    onWeightChanged: () => setState(() {}),
                  ),
                  _GoalsPage(
                    kcalCtrl: _kcalCtrl,
                    proteinCtrl: _proteinCtrl,
                    onEdited: () => setState(() => _goalsEdited = true),
                  ),
                ],
              ),
            ),
            _NavBar(
              page: _page,
              lastPage: _lastPage,
              canAdvance: _canAdvance && !_saving,
              saving: _saving,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Sayfa 1: Hoş geldin

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: AppRadius.brLg,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: AppIconSize.xl,
              color: context.colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.vGapXl,
          Text('Fit Pack’e hoş geldin',
              style: context.texts.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.vGapMd,
          Text(
            'Antrenman, beslenme ve gelişimini tek yerde topla. '
            'Birkaç soruyla hedeflerini ayarlayalım — hepsini sonra '
            'değiştirebilirsin.',
            style: context.texts.bodyLarge
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────── Sayfa 2: Vücut + faz

class _GoalSetupPage extends StatelessWidget {
  const _GoalSetupPage({
    required this.heightCtrl,
    required this.weightCtrl,
    required this.goalWeightCtrl,
    required this.phase,
    required this.gender,
    required this.birthDate,
    required this.onGenderChanged,
    required this.onBirthDateChanged,
    required this.onPhaseChanged,
    required this.onWeightChanged,
  });

  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController goalWeightCtrl;
  final OnboardingPhase phase;
  final String? gender;
  final DateTime? birthDate;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<OnboardingPhase> onPhaseChanged;
  final VoidCallback onWeightChanged;

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, 12, 31),
      helpText: 'Doğum tarihini seç',
    );
    if (picked != null) onBirthDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('Seni tanıyalım',
            style: context.texts.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.vGapMd,
        Text('Hedef önerisi için kilon yeterli; gerisi opsiyonel '
            '(cinsiyet + doğum tarihi günlük enerji tahmini için).',
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        AppSpacing.vGapXl,
        Row(
          children: [
            Expanded(
              child: _NumField(
                controller: weightCtrl,
                label: 'Mevcut kilo',
                suffix: 'kg',
                onChanged: (_) => onWeightChanged(),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _NumField(
                controller: heightCtrl,
                label: 'Boy',
                suffix: 'cm',
              ),
            ),
          ],
        ),
        AppSpacing.vGapLg,
        _NumField(
          controller: goalWeightCtrl,
          label: 'Hedef kilo (opsiyonel)',
          suffix: 'kg',
        ),
        AppSpacing.vGapLg,
        // Cinsiyet (opsiyonel) — günlük enerji tahmini için.
        Row(
          children: [
            Expanded(
              child: _ChoiceChipTile(
                label: 'Erkek',
                selected: gender == 'male',
                onTap: () =>
                    onGenderChanged(gender == 'male' ? null : 'male'),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _ChoiceChipTile(
                label: 'Kadın',
                selected: gender == 'female',
                onTap: () =>
                    onGenderChanged(gender == 'female' ? null : 'female'),
              ),
            ),
          ],
        ),
        AppSpacing.vGapLg,
        // Doğum tarihi (opsiyonel).
        InkWell(
          onTap: () => _pickBirthDate(context),
          borderRadius: AppRadius.brMd,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Doğum tarihi (opsiyonel)',
              border: OutlineInputBorder(borderRadius: AppRadius.brMd),
              suffixIcon: Icon(Icons.calendar_today_rounded),
            ),
            child: Text(
              birthDate == null
                  ? 'Seç'
                  : '${birthDate!.day.toString().padLeft(2, '0')}.'
                      '${birthDate!.month.toString().padLeft(2, '0')}.'
                      '${birthDate!.year}',
              style: context.texts.bodyLarge?.copyWith(
                  color: birthDate == null
                      ? context.colors.onSurfaceVariant
                      : null),
            ),
          ),
        ),
        AppSpacing.vGapXl,
        Text('Hedefin', style: context.texts.titleMedium),
        AppSpacing.vGapSm,
        ...OnboardingPhase.values.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PhaseTile(
                phase: p,
                selected: p == phase,
                onTap: () => onPhaseChanged(p),
              ),
            )),
      ],
    );
  }
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile({
    required this.phase,
    required this.selected,
    required this.onTap,
  });

  final OnboardingPhase phase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.label,
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.onPrimaryContainer : null,
                      )),
                  Text(phase.description,
                      style: context.texts.bodySmall?.copyWith(
                        color: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── Sayfa 3: Hedefler

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({
    required this.kcalCtrl,
    required this.proteinCtrl,
    required this.onEdited,
  });

  final TextEditingController kcalCtrl;
  final TextEditingController proteinCtrl;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('Günlük hedeflerin',
            style: context.texts.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.vGapMd,
        Text('Hedefine göre önerildi. İstersen değiştir — sonra Ayarlar’dan '
            'da güncelleyebilirsin.',
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        AppSpacing.vGapXl,
        _NumField(
          controller: kcalCtrl,
          label: 'Günlük kalori hedefi',
          suffix: 'kcal',
          decimal: false,
          onChanged: (_) => onEdited(),
        ),
        AppSpacing.vGapLg,
        _NumField(
          controller: proteinCtrl,
          label: 'Günlük protein hedefi',
          suffix: 'g',
          decimal: false,
          onChanged: (_) => onEdited(),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── Ortak parçalar

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.decimal = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }
}

/// Onboarding'de cinsiyet seçimi için seçilebilir kart (tekrar dokun = bırak).
class _ChoiceChipTile extends StatelessWidget {
  const _ChoiceChipTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? colors.onPrimaryContainer : null,
            )),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: AppDuration.normal,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: active
                    ? context.colors.primary
                    : context.colors.surfaceContainerHighest,
                borderRadius: AppRadius.brSm,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.page,
    required this.lastPage,
    required this.canAdvance,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int page;
  final int lastPage;
  final bool canAdvance;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = page == lastPage;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        children: [
          if (page > 0)
            TextButton(
              onPressed: saving ? null : onBack,
              child: const Text('Geri'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: canAdvance ? onNext : null,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLast ? 'Tamamla' : 'İleri'),
          ),
        ],
      ),
    );
  }
}
