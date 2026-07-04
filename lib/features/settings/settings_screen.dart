import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_state_views.dart';
import '../home/providers/home_providers.dart';
import '../workout/calorie_estimate.dart';
import '../cloud/auth_service.dart';
import 'backup_service.dart';

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

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _editGender(BuildContext context, WidgetRef ref) async {
    final picked = await _pickOption(
      context,
      title: 'Cinsiyet',
      options: const [('male', 'Erkek'), ('female', 'Kadın')],
      current: profile.gender,
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(gender: Value(picked)));
    }
  }

  Future<void> _editActivity(BuildContext context, WidgetRef ref) async {
    final picked = await _pickOption(
      context,
      title: 'Aktiflik Düzeyi',
      options: activityLabelsTr.entries.map((e) => (e.key, e.value)).toList(),
      current: profile.activityLevel,
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(activityLevel: Value(picked)));
    }
  }

  Future<void> _editBirthDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: profile.birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, 12, 31), // en az 10 yaş
      helpText: 'Doğum tarihini seç',
    );
    if (picked != null) {
      await _save(ref, profile.copyWith(birthDate: Value(picked)));
    }
  }

  /// Basit tek-seçim listesi dialog'u.
  Future<String?> _pickOption(
    BuildContext context, {
    required String title,
    required List<(String, String)> options,
    required String? current,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == current
                  ? Icon(Icons.check_rounded, color: ctx.colors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
  }

  /// Tüm veritabanını (.sqlite) paylaşım sayfasıyla dışa aktar — Drive/Dosyalar/
  /// e-postaya kaydet. Geri yüklenebilir tam yedek (rapor dışa aktarımından farklı).
  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider).shareBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek oluşturulamadı: $e')),
        );
      }
    }
  }

  /// Bir yedek dosyası seç → onay → canlı DB'nin üstüne yaz → uygulamayı kapat.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    if (picked == null || picked.files.single.path == null) return;
    final file = File(picked.files.single.path!);

    if (!context.mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Yedekten geri yükle',
      message:
          'Şu anki tüm verinin yerine bu yedek yüklenecek. Bu işlem geri alınamaz. '
          'Devam edilsin mi?',
      confirmLabel: 'Geri Yükle',
      destructive: true,
    );
    if (!ok) return;

    try {
      await ref.read(backupServiceProvider).restoreFromFile(file);
    } on FormatException catch (e) {
      // Doğrulama hatası — DB kapanmadan reddedildi, uygulama çalışır durumda.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    } on RestoreNeedsRestartException {
      // Kopyalama yarıda kesildi; mevcut veri korundu ama bağlantı kapalı.
      if (context.mounted) {
        await showRestartDialog(
          context,
          title: 'Geri yükleme başarısız',
          message: 'Bir sorun oluştu, mevcut verin korundu. Uygulama '
              'kapanacak — tekrar açman yeterli.',
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geri yükleme başarısız: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await showRestartDialog(
      context,
      title: 'Geri yüklendi',
      message: 'Veriler geri yüklendi. Değişikliklerin görünmesi için '
          'uygulama kapanacak — tekrar açman yeterli.',
    );
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
        // ── BMR/TDEE girdileri (docs/12) ──
        _SettingTile(
          icon: Icons.wc_rounded,
          title: 'Cinsiyet',
          value: switch (profile.gender) {
            'male' => 'Erkek',
            'female' => 'Kadın',
            _ => '—',
          },
          onTap: () => _editGender(context, ref),
        ),
        _SettingTile(
          icon: Icons.cake_outlined,
          title: 'Doğum Tarihi',
          value: profile.birthDate != null
              ? '${_fmtDate(profile.birthDate!)} · ${ageFromBirthDate(profile.birthDate)} yaş'
              : '—',
          onTap: () => _editBirthDate(context, ref),
        ),
        _SettingTile(
          icon: Icons.directions_walk_rounded,
          title: 'Aktiflik Düzeyi',
          value: activityLabelsTr[profile.activityLevel] ?? '—',
          onTap: () => _editActivity(context, ref),
        ),
        _DailyEnergyTile(profile: profile),
        const _SectionHeader('Beslenme'),
        _SettingTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Yemekler',
          subtitle: 'Besin veritabanı — değerleri gör, düzenle, ekle',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/foods'),
        ),
        const _SectionHeader('Verilerim'),
        _CloudAccountTile(),
        _SettingTile(
          icon: Icons.backup_rounded,
          title: 'Cihaza Yedekle',
          subtitle: 'Verini dosya olarak kaydet (Drive/Dosyalar) — geri yüklenebilir',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _backup(context, ref),
        ),
        _SettingTile(
          icon: Icons.restore_rounded,
          title: 'Yedekten Geri Yükle',
          subtitle: 'Daha önce aldığın yedek dosyasını geri yükle',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _restore(context, ref),
        ),
        _SettingTile(
          icon: Icons.ios_share_rounded,
          title: 'Veri Dışa Aktar (rapor)',
          subtitle: 'Okunabilir rapor — Markdown / JSON / CSV',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/export'),
        ),
        const _SectionHeader('Hakkında'),
        _SettingTile(
          icon: Icons.info_outline_rounded,
          title: AppConstants.appName,
          subtitle:
              'Sürüm ${AppConstants.appVersion} · Kişisel fitness takibi',
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Tahmini Günlük Harcama (TDEE) — profil + en güncel kilodan hesaplar.
/// Eksik veri varsa neyin gerektiğini söyler (tıklanınca açıklama).
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

    final c = context.colors;
    final ready = total != null;
    final missing = <String>[
      if (weight == null) 'kilo',
      if (profile.heightCm == null) 'boy',
      if (age == null) 'doğum tarihi',
      if (profile.gender != 'male' && profile.gender != 'female') 'cinsiyet',
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
                Text('Tahmini Günlük Harcama',
                    style: context.texts.labelLarge?.copyWith(
                        color: c.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
                AppSpacing.vGapXs,
                if (ready)
                  Text(
                    '~${total.round()} kcal/gün'
                    '  ·  dinlenme ${bmr!.round()}',
                    style: context.texts.bodyMedium?.copyWith(
                        color: c.onPrimaryContainer.withValues(alpha: 0.85)),
                  )
                else
                  Text(
                    'Hesaplamak için gir: ${missing.join(", ")}',
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

/// Bulut hesabı satırı — oturum durumuna göre e-posta ya da "Giriş yap" gösterir.
class _CloudAccountTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final signedIn = user != null;
    return _SettingTile(
      icon: signedIn ? Icons.cloud_done_rounded : Icons.cloud_outlined,
      title: 'Bulut Hesabı',
      subtitle: signedIn
          ? '${user.email ?? "Giriş yapıldı"} · buluta yedekle / geri yükle'
          : 'Giriş yap → verini buluta yedekle, yeni cihazda geri yükle',
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/cloud'),
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
