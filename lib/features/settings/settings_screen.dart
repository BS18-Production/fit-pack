import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profil bulunamadı',
              message: 'Uygulamayı yeniden başlatmayı dene',
            );
          }
          return _SettingsBody(profile: profile);
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
          message: 'Ayarlar yüklenemedi',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final UserProfileData profile;
  static final DateFormat _isoDate = DateFormat('d MMM yyyy', 'tr_TR');

  const _SettingsBody({required this.profile});

  Future<void> _save(WidgetRef ref, UserProfileData updated) async {
    await ref.read(userProfileDaoProvider).updateProfile(updated);
    ref.invalidate(userProfileProvider);
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
    final controller = TextEditingController(text: initial.toString());
    try {
      final result = await showDialog<num>(
        context: context,
        builder: (ctx) {
          String? error;
          return StatefulBuilder(
            builder: (ctx, setLocal) => AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    TextInputType.numberWithOptions(decimal: !isInt),
                decoration: InputDecoration(
                  suffixText: unit,
                  helperText: 'Aralık: $min – $max',
                  errorText: error,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final v = isInt
                        ? int.tryParse(controller.text.trim())
                        : double.tryParse(
                            controller.text.trim().replaceAll(',', '.'));
                    if (v == null) {
                      setLocal(() => error = 'Geçersiz sayı');
                      return;
                    }
                    if (v < min || v > max) {
                      setLocal(() => error = '$min – $max aralığında olmalı');
                      return;
                    }
                    Navigator.pop(ctx, v);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
        },
      );
      if (result != null) {
        await _save(ref, apply(result));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kaydedildi')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _resetDeload(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Deload Sıfırla',
      message: 'Deload tarihi şu ana ayarlanacak. Devam edilsin mi?',
      confirmLabel: 'Sıfırla',
      destructive: false,
    );
    if (!ok) return;
    await _save(ref, profile.copyWith(lastDeload: Value(DateTime.now())));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deload sıfırlandı')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const _SectionHeader('Hedefler'),
        _SettingTile(
          icon: Icons.local_fire_department_rounded,
          title: 'Kalori Hedefi',
          value: '${profile.kcalGoal} kcal',
          onTap: () => _editNumber(context, ref,
              title: 'Kalori Hedefi',
              unit: 'kcal',
              initial: profile.kcalGoal,
              isInt: true,
              min: 800,
              max: 6000,
              apply: (v) => profile.copyWith(kcalGoal: v.toInt())),
        ),
        _SettingTile(
          icon: Icons.egg_alt_outlined,
          title: 'Protein Hedefi',
          value: '${profile.proteinGoal} g',
          onTap: () => _editNumber(context, ref,
              title: 'Protein Hedefi',
              unit: 'g',
              initial: profile.proteinGoal,
              isInt: true,
              min: 30,
              max: 400,
              apply: (v) => profile.copyWith(proteinGoal: v.toInt())),
        ),
        const _SectionHeader('Program'),
        _SettingTile(
          icon: Icons.timeline_rounded,
          title: 'Faz',
          value: '${profile.currentPhase}',
          onTap: () => _editNumber(context, ref,
              title: 'Faz (1-3)',
              unit: '',
              initial: profile.currentPhase,
              isInt: true,
              min: 1,
              max: 3,
              apply: (v) =>
                  profile.copyWith(currentPhase: v.toInt().clamp(1, 3))),
        ),
        _SettingTile(
          icon: Icons.calendar_month_rounded,
          title: 'Hafta',
          value: '${profile.currentWeek}',
          onTap: () => _editNumber(context, ref,
              title: 'Hafta',
              unit: '',
              initial: profile.currentWeek,
              isInt: true,
              min: 1,
              max: 52,
              apply: (v) => profile.copyWith(currentWeek: v.toInt())),
        ),
        _SettingTile(
          icon: Icons.restore_rounded,
          title: 'Son Deload',
          subtitle: profile.lastDeload == null
              ? 'Henüz deload yapılmadı'
              : _isoDate.format(profile.lastDeload!),
          trailing: const Icon(Icons.refresh_rounded),
          onTap: () => _resetDeload(context, ref),
        ),
        const _SectionHeader('Vücut'),
        _SettingTile(
          icon: Icons.height_rounded,
          title: 'Boy',
          value: profile.heightCm != null ? '${profile.heightCm} cm' : '—',
          onTap: () => _editNumber(context, ref,
              title: 'Boy',
              unit: 'cm',
              initial: profile.heightCm ?? 175,
              isInt: false,
              min: 120,
              max: 230,
              apply: (v) =>
                  profile.copyWith(heightCm: Value(v.toDouble()))),
        ),
        _SettingTile(
          icon: Icons.flag_outlined,
          title: 'Hedef Kilo',
          value: profile.goalWeightKg != null
              ? '${profile.goalWeightKg} kg'
              : '—',
          onTap: () => _editNumber(context, ref,
              title: 'Hedef Kilo',
              unit: 'kg',
              initial: profile.goalWeightKg ?? 80,
              isInt: false,
              min: 40,
              max: 250,
              apply: (v) =>
                  profile.copyWith(goalWeightKg: Value(v.toDouble()))),
        ),
        const _SectionHeader('Beslenme'),
        _SettingTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Yemekler',
          subtitle: 'Besin veritabanı — değerleri gör, düzenle, ekle',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/foods'),
        ),
        const _SectionHeader('Hakkında'),
        _SettingTile(
          icon: Icons.info_outline_rounded,
          title: AppConstants.appName,
          subtitle:
              'Sürüm ${AppConstants.appVersion} · Kişisel fitness takibi',
        ),
        _SettingTile(
          icon: Icons.ios_share_rounded,
          title: 'Veri Dışa Aktar',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/export'),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Tutarlı, sakin (Pro) ayar satırı — primary-tonlu ikon rozeti.
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.14),
          borderRadius: AppRadius.brSm,
        ),
        child: Icon(icon,
            color: context.colors.primary, size: AppIconSize.sm + 2),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (value != null
              ? Text(value!,
                  style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600))
              : null),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
