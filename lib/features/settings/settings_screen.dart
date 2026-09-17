import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/i18n/enum_labels.dart';
import '../../core/i18n/formatting.dart';
import '../../core/i18n/locale_provider.dart';
import '../../core/prefs/training_prefs.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/units/units.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/setting_tiles.dart';
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

  /// İlerleme önerisindeki kilo artışı (docs/21 #3). Seçenekler görüntü
  /// biriminde; kayıt kg.
  Future<void> _editIncrement(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final units = ref.read(unitsProvider);
    final options = units.imperial ? incrementOptionsLb : incrementOptionsKg;
    final currentKg = ref.read(effectiveIncrementKgProvider);
    final picked = await pickOptionDialog(
      context,
      title: l.settingsWeightIncrement,
      options: [
        for (final v in options)
          ('$v', units.lift(units.weightToKg(v))),
      ],
      current: options
          .map((v) => '$v')
          .firstWhere(
              (v) => (units.weightToKg(double.parse(v)) - currentKg).abs() <
                  0.001,
              orElse: () => ''),
    );
    if (picked != null) {
      await ref
          .read(weightIncrementProvider.notifier)
          .setIncrementKg(units.weightToKg(double.parse(picked)));
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
      // Bölümler cam kartlarda gruplanır (liquid glass dili) — çıplak tile yok.
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
            context.bottomScrollInset),
        children: [
          SettingsSection(
            title: l.settingsSectionPreferences,
            children: [
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
                icon: Icons.trending_up_rounded,
                title: l.settingsWeightIncrement,
                value: ref
                    .watch(unitsProvider)
                    .lift(ref.watch(effectiveIncrementKgProvider)),
                onTap: () => _editIncrement(context, ref),
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
            ],
          ),
          SettingsSection(
            title: l.settingsSectionNutrition,
            children: [
              SettingTile(
                icon: Icons.restaurant_menu_rounded,
                title: l.settingsFoods,
                subtitle: l.settingsFoodsSubtitle,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.foods),
              ),
            ],
          ),
          // "Veri & Gizlilik" bölümü KALDIRILDI (2026-07-21, docs/18 §1.2):
          // elle yedekleme/geri yükleme/dışa aktarma — otomatik senkron varken
          // gereksiz. Hesap satırı **Profil'e taşındı** (mağaza hesap-silme
          // zorunluluğu, docs/16 §4 — yok edilemez).
          SettingsSection(
            title: l.settingsSectionAbout,
            children: [
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
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Bulut hesabı satırı — oturum durumuna göre e-posta ya da "Giriş yap" gösterir.
