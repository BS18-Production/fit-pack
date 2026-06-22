import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final result = await showDialog<num>(
      context: context,
      builder: (_) => _NumberEditDialog(
        title: title,
        unit: unit,
        initial: initial,
        isInt: isInt,
        min: min,
        max: max,
      ),
    );
    if (result != null) {
      await _save(ref, apply(result));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedildi')),
        );
      }
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

/// Sayı düzenleme dialog'u. Controller'ı kendi State'inde tutar — dialog
/// kapanış animasyonu sırasında "disposed controller" hatasını önler.
class _NumberEditDialog extends StatefulWidget {
  final String title;
  final String unit;
  final num initial;
  final bool isInt;
  final num min;
  final num max;
  const _NumberEditDialog({
    required this.title,
    required this.unit,
    required this.initial,
    required this.isInt,
    required this.min,
    required this.max,
  });

  @override
  State<_NumberEditDialog> createState() => _NumberEditDialogState();
}

class _NumberEditDialogState extends State<_NumberEditDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = widget.isInt
        ? int.tryParse(_controller.text.trim())
        : double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (v == null) {
      setState(() => _error = 'Geçersiz sayı');
      return;
    }
    if (v < widget.min || v > widget.max) {
      setState(() => _error = '${widget.min} – ${widget.max} aralığında olmalı');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: widget.unit,
          helperText: 'Aralık: ${widget.min} – ${widget.max}',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
