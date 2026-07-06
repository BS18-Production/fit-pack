import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/i18n/enum_labels.dart';
import '../../core/i18n/formatting.dart';
import '../../core/i18n/locale_provider.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/setting_tiles.dart';
import '../cloud/auth_service.dart';
import 'backup_service.dart';
import '../../core/router/app_routes.dart';

/// Ayarlar (docs/16) — yalnız uygulama konfigürasyonu + veri araçları +
/// yasal/hakkında. Kişisel veri (hedefler/vücut/kimlik/TDEE) Profil'de.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editTheme(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final picked = await pickOptionDialog(
      context,
      title: l.settingsTheme,
      options:
          ThemeMode.values.map((m) => (m.name, themeModeLabel(l, m))).toList(),
      current: ref.read(themeModeProvider).name,
    );
    if (picked != null) {
      final mode = ThemeMode.values
          .firstWhere((m) => m.name == picked, orElse: () => ThemeMode.system);
      await ref.read(themeModeProvider.notifier).setMode(mode);
    }
  }

  Future<void> _editLanguage(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    // 'system' | 'en' | 'tr' — 'system' cihaz dilini takip eder.
    final current = ref.read(localeProvider)?.languageCode ?? 'system';
    final picked = await pickOptionDialog(
      context,
      title: l.settingsLanguage,
      options: [
        ('system', l.languageSystem),
        ('en', l.languageEnglish),
        ('tr', l.languageTurkish),
      ],
      current: current,
    );
    if (picked != null) {
      final locale = picked == 'system' ? null : Locale(picked);
      await ref.read(localeProvider.notifier).setLocale(locale);
    }
  }

  Future<void> _editUnits(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final picked = await pickOptionDialog(
      context,
      title: l.settingsUnits,
      options: [
        (UnitSystem.metric.name, l.unitsMetric),
        (UnitSystem.imperial.name, l.unitsImperial),
      ],
      current: ref.read(unitSystemProvider).name,
    );
    if (picked != null) {
      await ref.read(unitSystemProvider.notifier).setSystem(
          picked == UnitSystem.imperial.name
              ? UnitSystem.imperial
              : UnitSystem.metric);
    }
  }

  Future<void> _editWeekStart(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    // Gün adları locale'den — ekstra çeviri anahtarı gerekmez.
    final picked = await pickOptionDialog(
      context,
      title: l.settingsWeekStart,
      options: [
        ('${DateTime.monday}', context.weekdayName(DateTime.monday)),
        ('${DateTime.sunday}', context.weekdayName(DateTime.sunday)),
      ],
      current: '${ref.read(weekStartProvider)}',
    );
    if (picked != null) {
      await ref.read(weekStartProvider.notifier).setWeekStart(int.parse(picked));
    }
  }

  /// Tüm veritabanını (.sqlite) paylaşım sayfasıyla dışa aktar — Drive/Dosyalar/
  /// e-postaya kaydet. Geri yüklenebilir tam yedek (rapor dışa aktarımından farklı).
  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider).shareBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppL10n.of(context).settingsBackupFailed(e.toString()))),
        );
      }
    }
  }

  /// Bir yedek dosyası seç → onay → canlı DB'nin üstüne yaz → uygulamayı kapat.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    if (picked == null || picked.files.single.path == null) return;
    final file = File(picked.files.single.path!);

    if (!context.mounted) return;
    final ok = await confirmAction(
      context,
      title: l.settingsRestoreConfirmTitle,
      message: l.settingsRestoreConfirmMessage,
      confirmLabel: l.settingsRestoreConfirmAction,
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
          title: l.settingsRestoreFailedTitle,
          message: l.settingsRestoreFailedMessage,
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.settingsRestoreFailed(e.toString()))),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await showRestartDialog(
      context,
      title: l.settingsRestoredTitle,
      message: l.settingsRestoredMessage,
    );
  }

  /// Geri bildirim: e-posta uygulamasını konu satırı doldurulmuş açar.
  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: 'subject=${Uri.encodeComponent('Fit Pack ${AppConstants.appVersion} — Feedback')}',
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      // E-posta uygulaması yoksa adresi göster (kopyalanabilir SnackBar).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConstants.supportEmail)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          SettingsSectionHeader(l.settingsSectionPreferences),
          SettingTile(
            icon: Icons.brightness_6_rounded,
            title: l.settingsTheme,
            value: themeModeLabel(l, ref.watch(themeModeProvider)),
            onTap: () => _editTheme(context, ref),
          ),
          SettingTile(
            icon: Icons.language_rounded,
            title: l.settingsLanguage,
            value: localeLabel(l, ref.watch(localeProvider)),
            onTap: () => _editLanguage(context, ref),
          ),
          SettingTile(
            icon: Icons.straighten_rounded,
            title: l.settingsUnits,
            value: ref.watch(unitSystemProvider) == UnitSystem.imperial
                ? l.unitsImperial
                : l.unitsMetric,
            onTap: () => _editUnits(context, ref),
          ),
          SettingTile(
            icon: Icons.calendar_view_week_rounded,
            title: l.settingsWeekStart,
            value: context.weekdayName(ref.watch(weekStartProvider)),
            onTap: () => _editWeekStart(context, ref),
          ),
          SettingTile(
            icon: Icons.notifications_outlined,
            title: l.settingsNotifications,
            subtitle: l.settingsNotificationsSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          SettingsSectionHeader(l.settingsSectionNutrition),
          SettingTile(
            icon: Icons.restaurant_menu_rounded,
            title: l.settingsFoods,
            subtitle: l.settingsFoodsSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.foods),
          ),
          SettingsSectionHeader(l.settingsSectionMyData),
          _CloudAccountTile(),
          SettingTile(
            icon: Icons.backup_rounded,
            title: l.settingsBackup,
            subtitle: l.settingsBackupSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _backup(context, ref),
          ),
          SettingTile(
            icon: Icons.restore_rounded,
            title: l.settingsRestore,
            subtitle: l.settingsRestoreSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _restore(context, ref),
          ),
          SettingTile(
            icon: Icons.ios_share_rounded,
            title: l.settingsExport,
            subtitle: l.settingsExportSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.export),
          ),
          SettingsSectionHeader(l.settingsSectionAbout),
          SettingTile(
            icon: Icons.info_outline_rounded,
            title: AppConstants.appName,
            subtitle: l.settingsAboutSubtitle(AppConstants.appVersion),
            trailing: const Icon(Icons.chevron_right_rounded),
            // Flutter'ın hazır lisans sayfası — tüm paket lisansları (B2).
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            ),
          ),
          SettingTile(
            icon: Icons.public_rounded,
            title: l.settingsAttribution,
            subtitle: l.settingsAttributionSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.attribution),
          ),
          SettingTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: l.settingsFeedback,
            subtitle: l.settingsFeedbackSubtitle,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _sendFeedback(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Bulut hesabı satırı — oturum durumuna göre e-posta ya da "Giriş yap" gösterir.
class _CloudAccountTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final user = ref.watch(currentUserProvider);
    final signedIn = user != null;
    return SettingTile(
      icon: signedIn ? Icons.cloud_done_rounded : Icons.cloud_outlined,
      title: l.settingsCloudAccount,
      subtitle: signedIn
          ? l.settingsCloudSignedIn(user.email ?? l.settingsCloudSignedInFallback)
          : l.settingsCloudSignedOut,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(AppRoutes.cloud),
    );
  }
}
