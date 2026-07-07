import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../home/providers/home_providers.dart';
import 'onboarding_calc.dart';

/// İlk açılış akışı V2 (docs/15 — glass tema + değer + öğretme).
///
/// 4 sayfa: Karşılama → Seni tanıyalım (vücut + faz) → Planın hazır
/// (kalori/protein + değer projeksiyonu) → İçeride ne var (4 sekme haritası).
/// Tamamla → profil yazılır, başlangıç kilosu ölçüm olarak kaydedilir,
/// onboarded=1, Home'a geçilir. Sekme başına ilk-kullanım ipuçları
/// (coach mark) ayrı: `core/onboarding/first_run_hints.dart`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Faz etiketi — lokalize (docs/14; enum görünen metin taşımaz).
String phaseLabel(AppL10n l, OnboardingPhase p) => switch (p) {
      OnboardingPhase.cut => l.phaseCut,
      OnboardingPhase.maintenance => l.phaseMaintain,
      OnboardingPhase.bulk => l.phaseBulk,
    };

String phaseDescription(AppL10n l, OnboardingPhase p) => switch (p) {
      OnboardingPhase.cut => l.phaseCutDesc,
      OnboardingPhase.maintenance => l.phaseMaintainDesc,
      OnboardingPhase.bulk => l.phaseBulkDesc,
    };

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Sayfa 2 — vücut bilgileri
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  OnboardingPhase _phase = OnboardingPhase.cut;
  String? _gender; // 'male' | 'female' — günlük enerji tahmini için (opsiyonel)
  DateTime? _birthDate; // yaş — günlük enerji tahmini için (opsiyonel)

  // Sayfa 3 — hedefler
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  bool _goalsEdited = false; // kullanıcı elle değiştirdiyse üzerine yazma

  bool _saving = false;

  static const _lastPage = 3;

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

  // Girişler görüntü biriminde okunur, kg'a çevrilir (docs/16 §3) —
  // suggestGoals/projectWeeks/DB hepsi kg bekler.
  double? get _weight {
    final v = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    return v == null ? null : ref.read(unitsProvider).weightToKg(v);
  }

  double? get _goalWeight {
    final v = double.tryParse(_goalWeightCtrl.text.replaceAll(',', '.'));
    return v == null ? null : ref.read(unitsProvider).weightToKg(v);
  }

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
    final l = AppL10n.of(context);
    // Hedefler sayı olarak okunamıyorsa kaydetmeye hiç girme — kullanıcıya
    // söyle (M-10: eski int.parse boş alanda sessizce çöküyordu).
    final kcal = int.tryParse(_kcalCtrl.text);
    final protein = int.tryParse(_proteinCtrl.text);
    if (kcal == null || protein == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.onbGoalsNumberError)));
      return;
    }
    setState(() => _saving = true);
    try {
      final heightRaw =
          double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
      final height = heightRaw == null
          ? null
          : ref.read(unitsProvider).lengthToCm(heightRaw);
      final goalWeight = _goalWeight;

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

      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      // Kayıt başarısız — kullanıcı bilsin ve tekrar deneyebilsin (M-10:
      // eskiden hata sessizce yutulup düğme takılı kalıyordu).
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.onbSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Zemin (GlassBackground) app.dart'ta tüm ekranlara bir kez verilir.
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
                    _AboutYouPage(
                      heightCtrl: _heightCtrl,
                      weightCtrl: _weightCtrl,
                      goalWeightCtrl: _goalWeightCtrl,
                      phase: _phase,
                      gender: _gender,
                      birthDate: _birthDate,
                      onGenderChanged: (g) => setState(() => _gender = g),
                      onBirthDateChanged: (d) =>
                          setState(() => _birthDate = d),
                      onPhaseChanged: (p) => setState(() {
                        _phase = p;
                        _refreshSuggestedGoals();
                      }),
                      onWeightChanged: () => setState(() {}),
                    ),
                    _PlanPage(
                      kcalCtrl: _kcalCtrl,
                      proteinCtrl: _proteinCtrl,
                      weightKg: _weight,
                      goalWeightKg: _goalWeight,
                      phase: _phase,
                      onEdited: () => setState(() => _goalsEdited = true),
                    ),
                    const _TourPage(),
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

// ─────────────────────────────────────────────────────── Sayfa 1: Karşılama

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final muted = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marka rozeti — Ana Sayfa CTA'sıyla aynı gradient dil.
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brXl,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.indigo, AppColors.indigoDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigoDeep.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                size: 40, color: AppColors.onGradient),
          ),
          AppSpacing.vGapXl,
          Text(l.onbWelcomeTitle,
              style: context.texts.displaySmall?.copyWith(height: 1.1)),
          AppSpacing.vGapMd,
          Text(l.onbWelcomeTagline,
              style: context.texts.bodyLarge?.copyWith(color: muted)),
          AppSpacing.vGapXl,
          Row(
            children: [
              Icon(Icons.timer_outlined, size: AppIconSize.sm, color: muted),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(l.onbWelcomeHint,
                    style: context.texts.bodySmall?.copyWith(color: muted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────── Sayfa 2: Seni tanıyalım

class _AboutYouPage extends ConsumerWidget {
  const _AboutYouPage({
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
      helpText: AppL10n.of(context).settingsPickBirthDate,
    );
    if (picked != null) onBirthDateChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      children: [
        Text(l.onbAboutYouTitle, style: context.texts.headlineSmall),
        AppSpacing.vGapSm,
        Text(l.onbAboutYouSubtitle,
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        AppSpacing.vGapLg,
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _NumField(
                      controller: weightCtrl,
                      label: l.onbCurrentWeight,
                      suffix: units.weightUnit,
                      onChanged: (_) => onWeightChanged(),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: _NumField(
                      controller: heightCtrl,
                      label: l.settingsHeight,
                      suffix: units.lengthUnit,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapLg,
              _NumField(
                controller: goalWeightCtrl,
                label: l.onbGoalWeightOptional,
                suffix: units.weightUnit,
              ),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChipTile(
                      label: l.settingsGenderMale,
                      selected: gender == 'male',
                      onTap: () =>
                          onGenderChanged(gender == 'male' ? null : 'male'),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: _ChoiceChipTile(
                      label: l.settingsGenderFemale,
                      selected: gender == 'female',
                      onTap: () => onGenderChanged(
                          gender == 'female' ? null : 'female'),
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapLg,
              InkWell(
                onTap: () => _pickBirthDate(context),
                borderRadius: AppRadius.brMd,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.onbBirthDateOptional,
                    border:
                        const OutlineInputBorder(borderRadius: AppRadius.brMd),
                    suffixIcon: const Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    birthDate == null
                        ? l.commonSelect
                        : context.dateFmt('d MMMM y').format(birthDate!),
                    style: context.texts.bodyLarge?.copyWith(
                        color: birthDate == null
                            ? context.colors.onSurfaceVariant
                            : null),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        Text(l.onbYourGoal, style: context.texts.titleMedium),
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
    final l = AppL10n.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
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
                  Text(phaseLabel(l, phase),
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.onPrimaryContainer : null,
                      )),
                  Text(phaseDescription(l, phase),
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

// ─────────────────────────────────────────────── Sayfa 3: Planın hazır

class _PlanPage extends ConsumerWidget {
  const _PlanPage({
    required this.kcalCtrl,
    required this.proteinCtrl,
    required this.weightKg,
    required this.goalWeightKg,
    required this.phase,
    required this.onEdited,
  });

  final TextEditingController kcalCtrl;
  final TextEditingController proteinCtrl;
  final double? weightKg;
  final double? goalWeightKg;
  final OnboardingPhase phase;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final muted = context.colors.onSurfaceVariant;
    final units = ref.watch(unitsProvider);

    // Projeksiyon — kullanıcının GİRDİĞİ kaloriyle hesaplanır (düzenledikçe
    // dürüstçe güncellenir). Veri tutarsızsa hiç gösterilmez (docs/15 §A3).
    final weeks = weightKg == null
        ? null
        : projectWeeks(
            weightKg: weightKg!,
            goalWeightKg: goalWeightKg,
            phase: phase,
            kcalGoal: int.tryParse(kcalCtrl.text),
          );
    // Projeksiyon metni görüntü biriminde ("78 kg" / "172 lb").
    final goalStr =
        goalWeightKg == null ? '' : units.weight(goalWeightKg!);

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: l.onbPlanReadyTitle),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 22, color: context.colors.secondary),
              ),
            ),
          ]),
          style: context.texts.headlineSmall,
        ),
        AppSpacing.vGapSm,
        Text(l.onbPlanReadySubtitle,
            style: context.texts.bodyMedium?.copyWith(color: muted)),
        AppSpacing.vGapLg,
        GlassCard(
          child: Column(
            children: [
              _NumField(
                controller: kcalCtrl,
                label: l.onbDailyKcal,
                suffix: 'kcal',
                decimal: false,
                onChanged: (_) => onEdited(),
              ),
              AppSpacing.vGapLg,
              _NumField(
                controller: proteinCtrl,
                label: l.onbDailyProtein,
                suffix: 'g',
                decimal: false,
                onChanged: (_) => onEdited(),
              ),
            ],
          ),
        ),
        if (weeks != null) ...[
          AppSpacing.vGapMd,
          GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.semantic.success.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(Icons.trending_up_rounded,
                      color: context.semantic.success),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase == OnboardingPhase.bulk
                            ? l.onbProjectionBulk(goalStr, weeks)
                            : l.onbProjectionCut(goalStr, weeks),
                        style: context.texts.titleSmall,
                      ),
                      AppSpacing.vGapXs,
                      Text(l.onbProjectionNote,
                          style: context.texts.bodySmall
                              ?.copyWith(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────── Sayfa 4: İçeride ne var

class _TourPage extends StatelessWidget {
  const _TourPage();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final s = context.semantic;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      children: [
        Text(l.onbWhatsInsideTitle, style: context.texts.headlineSmall),
        AppSpacing.vGapSm,
        Text(l.onbWhatsInsideSubtitle,
            style: context.texts.bodyMedium
                ?.copyWith(color: c.onSurfaceVariant)),
        AppSpacing.vGapLg,
        _TourRow(
            icon: Icons.home_rounded,
            tint: c.primary,
            title: l.navHome,
            description: l.onbTourHomeDesc),
        AppSpacing.vGapMd,
        _TourRow(
            icon: Icons.fitness_center_rounded,
            tint: c.tertiary,
            title: l.navWorkout,
            description: l.onbTourWorkoutDesc),
        AppSpacing.vGapMd,
        _TourRow(
            icon: Icons.restaurant_rounded,
            tint: c.secondary,
            title: l.navNutrition,
            description: l.onbTourNutritionDesc),
        AppSpacing.vGapMd,
        _TourRow(
            icon: Icons.trending_up_rounded,
            tint: s.success,
            title: l.navProgress,
            description: l.onbTourProgressDesc),
      ],
    );
  }
}

class _TourRow extends StatelessWidget {
  const _TourRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, color: tint),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: context.texts.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description,
                    style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── Ortak parçalar

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
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
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
    final l = AppL10n.of(context);
    final isLast = page == lastPage;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          if (page > 0)
            TextButton(
              onPressed: saving ? null : onBack,
              child: Text(l.commonBack),
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
                : Text(isLast ? l.onbStart : l.commonNext),
          ),
        ],
      ),
    );
  }
}
