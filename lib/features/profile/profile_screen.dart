import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/i18n/enum_labels.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/setting_tiles.dart';
import '../body_metrics/body_metrics_screen.dart';
import '../home/providers/home_providers.dart';
import '../workout/calorie_estimate.dart';

/// Profil (docs/16) — kullanıcının "kim olduğu": hedefler, vücut, kimlik,
/// tahmini günlük harcama. Sık düzenlenen kişisel veri burada; uygulama
/// konfigürasyonu Ayarlar'da (sağ üst ⚙️).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          IconButton(
            tooltip: l.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: l.settingsProfileNotFound,
              message: l.settingsProfileNotFoundHint,
            );
          }
          return _ProfileBody(profile: profile);
        },
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [
            Skeleton.card(height: 64),
            AppSpacing.vGapMd,
            Skeleton.card(height: 64),
            AppSpacing.vGapMd,
            Skeleton.card(height: 64),
          ],
        ),
        error: (_, _) => ErrorState(
          message: l.settingsLoadError,
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserProfileData profile;

  const _ProfileBody({required this.profile});

  Future<void> _save(WidgetRef ref, UserProfileData updated) async {
    await ref.read(userProfileDaoProvider).updateProfile(updated);
    ref.invalidate(userProfileProvider);
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _editGender(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final picked = await pickOptionDialog(
      context,
      title: l.settingsGender,
      options: [
        ('male', l.settingsGenderMale),
        ('female', l.settingsGenderFemale),
      ],
      current: profile.gender,
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(gender: Value(picked)));
    }
  }

  Future<void> _editActivity(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final picked = await pickOptionDialog(
      context,
      title: l.settingsActivityLevel,
      options: [for (final k in activityLevelKeys) (k, activityLabel(l, k))],
      current: profile.activityLevel,
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(activityLevel: Value(picked)));
    }
  }

  /// Boy düzenleme — metrikte tek cm alanı, imperial'de ft+in çift alan.
  /// DB'ye her zaman cm yazılır (docs/16 §3).
  Future<void> _editHeight(
      BuildContext context, WidgetRef ref, Units units) async {
    final l = AppL10n.of(context);
    if (!units.imperial) {
      return _editNumber(context, ref,
          title: l.settingsHeight,
          unit: 'cm',
          initial: profile.heightCm ?? 175,
          isInt: false,
          min: 120,
          max: 230,
          apply: (v) => profile.copyWith(heightCm: Value(v.toDouble())));
    }
    final cm = await showDialog<double>(
      context: context,
      builder: (_) => _FtInDialog(
          title: l.settingsHeight, initialCm: profile.heightCm ?? 175),
    );
    if (cm != null) {
      await _save(ref, profile.copyWith(heightCm: Value(cm)));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).commonSaved)),
        );
      }
    }
  }

  Future<void> _editBirthDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: profile.birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, 12, 31), // en az 10 yaş
      helpText: AppL10n.of(context).settingsPickBirthDate,
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(birthDate: Value(picked)));
    }
  }

  Future<void> _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String unit,
    required num initial,
    required bool isInt,
    required num min,
    required num max,
    required UserProfileData Function(num value) apply,
  }) async {
    final result = await showNumberEditDialog(
      context,
      title: title,
      unit: unit,
      initial: initial,
      isInt: isInt,
      min: min,
      max: max,
    );
    if (result != null) {
      await _save(ref, apply(result));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).commonSaved)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final units = ref.watch(unitsProvider);
    return ListView(
      children: [
        SettingsSectionHeader(l.settingsSectionGoals),
        SettingTile(
          icon: Icons.local_fire_department_rounded,
          title: l.settingsKcalGoal,
          value: '${profile.kcalGoal} kcal',
          onTap: () => _editNumber(context, ref,
              title: l.settingsKcalGoal,
              unit: 'kcal',
              initial: profile.kcalGoal,
              isInt: true,
              min: 800,
              max: 6000,
              apply: (v) => profile.copyWith(kcalGoal: v.toInt())),
        ),
        SettingTile(
          icon: Icons.egg_alt_outlined,
          title: l.settingsProteinGoal,
          value: '${profile.proteinGoal} g',
          onTap: () => _editNumber(context, ref,
              title: l.settingsProteinGoal,
              unit: 'g',
              initial: profile.proteinGoal,
              isInt: true,
              min: 30,
              max: 400,
              apply: (v) => profile.copyWith(proteinGoal: v.toInt())),
        ),
        SettingsSectionHeader(l.settingsSectionBody),
        SettingTile(
          icon: Icons.height_rounded,
          title: l.settingsHeight,
          value:
              profile.heightCm != null ? units.height(profile.heightCm!) : '—',
          onTap: () => _editHeight(context, ref, units),
        ),
        SettingTile(
          icon: Icons.flag_outlined,
          title: l.settingsGoalWeight,
          value: profile.goalWeightKg != null
              ? units.weight(profile.goalWeightKg!)
              : '—',
          onTap: () => _editNumber(context, ref,
              title: l.settingsGoalWeight,
              unit: units.weightUnit,
              initial: double.parse(units
                  .weightFromKg(profile.goalWeightKg ?? 80)
                  .toStringAsFixed(1)),
              isInt: false,
              min: units.weightFromKg(40).floor(),
              max: units.weightFromKg(250).ceil(),
              apply: (v) => profile.copyWith(
                  goalWeightKg: Value(units.weightToKg(v)))),
        ),
        // Güncel kilo/bel/kol tek form üzerinden girilir (İlerleme'deki ile aynı
        // sheet). Eskiden `context.go(progress)` idi; push'lu Profil'i yok edip
        // tab'a ışınlıyordu — formu yerinde açıyoruz (docs/16 §2.1, S1).
        SettingTile(
          icon: Icons.straighten_rounded,
          title: l.profileMeasurements,
          subtitle: l.profileMeasurementsSubtitle,
          onTap: () => showAddMeasurementSheet(context),
        ),
        SettingsSectionHeader(l.profileSectionIdentity),
        SettingTile(
          icon: Icons.wc_rounded,
          title: l.settingsGender,
          value: genderLabel(l, profile.gender),
          onTap: () => _editGender(context, ref),
        ),
        SettingTile(
          icon: Icons.cake_outlined,
          title: l.settingsBirthDate,
          value: profile.birthDate != null
              ? l.settingsBirthDateValue(_fmtDate(profile.birthDate!),
                  ageFromBirthDate(profile.birthDate) ?? 0)
              : '—',
          onTap: () => _editBirthDate(context, ref),
        ),
        SettingTile(
          icon: Icons.directions_walk_rounded,
          title: l.settingsActivityLevel,
          value: activityLabel(l, profile.activityLevel),
          onTap: () => _editActivity(context, ref),
        ),
        _DailyEnergyTile(profile: profile),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Tahmini Günlük Harcama (TDEE) — profil + en güncel kilodan hesaplar.
/// Eksik veri varsa neyin gerektiğini söyler.
class _DailyEnergyTile extends ConsumerWidget {
  final UserProfileData profile;
  const _DailyEnergyTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = ref.watch(latestWeightProvider).valueOrNull?.weightKg;
    final age = ageFromBirthDate(profile.birthDate);
    final bmr = mifflinStJeorBmr(
      weightKg: weight,
      heightCm: profile.heightCm,
      age: age,
      gender: profile.gender,
    );
    final total = tdee(bmr: bmr, activityLevel: profile.activityLevel);

    final l = AppL10n.of(context);
    final c = context.colors;
    final ready = total != null;
    final missing = <String>[
      if (weight == null) l.settingsMissingWeight,
      if (profile.heightCm == null) l.settingsMissingHeight,
      if (age == null) l.settingsMissingBirthDate,
      if (profile.gender != 'male' && profile.gender != 'female')
        l.settingsMissingGender,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.primaryContainer.withValues(alpha: ready ? 1 : 0.5),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: c.onPrimaryContainer, size: AppIconSize.lg),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.settingsDailyEnergyTitle,
                    style: context.texts.labelLarge?.copyWith(
                        color: c.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
                AppSpacing.vGapXs,
                if (ready)
                  Text(
                    l.settingsDailyEnergyValue(total.round(), bmr!.round()),
                    style: context.texts.bodyMedium?.copyWith(
                        color: c.onPrimaryContainer.withValues(alpha: 0.85)),
                  )
                else
                  Text(
                    l.settingsDailyEnergyMissing(missing.join(", ")),
                    style: context.texts.bodySmall?.copyWith(
                        color: c.onPrimaryContainer.withValues(alpha: 0.85)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// İmperial boy girişi: feet + inches iki alan. Sonuç cm döner (DB kanonik).
class _FtInDialog extends StatefulWidget {
  final String title;
  final double initialCm;
  const _FtInDialog({required this.title, required this.initialCm});

  @override
  State<_FtInDialog> createState() => _FtInDialogState();
}

class _FtInDialogState extends State<_FtInDialog> {
  late final TextEditingController _ft;
  late final TextEditingController _in;
  String? _error;

  @override
  void initState() {
    super.initState();
    final (ft, inch) = Units.heightToFtIn(widget.initialCm);
    _ft = TextEditingController(text: '$ft');
    _in = TextEditingController(text: '$inch');
  }

  @override
  void dispose() {
    _ft.dispose();
    _in.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppL10n.of(context);
    final ft = int.tryParse(_ft.text.trim());
    final inch = int.tryParse(_in.text.trim());
    if (ft == null || inch == null) {
      setState(() => _error = l.commonInvalidNumber);
      return;
    }
    // 120–230 cm aralığının imperial karşılığı (~3'11" – 7'7").
    final cm = Units.ftInToCm(ft, inch);
    if (inch > 11 || cm < 120 || cm > 230) {
      setState(() => _error = l.commonRangeError("3'11\"", "7'7\""));
      return;
    }
    Navigator.pop(context, cm);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ft,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: 'ft'),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: TextField(
              controller: _in,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
              decoration:
                  InputDecoration(suffixText: 'in', errorText: _error),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.commonSave)),
      ],
    );
  }
}
