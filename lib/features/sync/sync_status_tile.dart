import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/providers.dart';
import '../../l10n/app_l10n.dart';
import 'sync_health.dart';
import 'sync_providers.dart';
import 'sync_status.dart';

/// Senkron durumu satırı (docs/18 §9, docs/20 §9). "Korkutma yok, durum
/// bilgisi var" — mesaj daima "kaydedildi" güvencesiyle başlar.
///
/// Üç katman:
/// 1. Ana satır: dört durumdan biri (güncel / yükleniyor / bekliyor / hata).
/// 2. Alt satır: **"Son yedekleme: bugün 14:32"** — verinin gerçekten sunucuya
///    ulaştığını görmenin tek yolu.
/// 3. Gerekirse iki uyarı: 3 günden uzun kesinti ve kalıcı hatalı satırlar.
///    İkisi de turuncu, kırmızı değil: veri kaybolmadı, telefonda duruyor.
class SyncStatusTile extends ConsumerWidget {
  const SyncStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final async = ref.watch(syncStatusProvider);
    final status = async.valueOrNull;
    // İlk kare / hata: sessiz kal (gösterge yanıp sönmesin).
    if (status == null) return const SizedBox.shrink();

    final (IconData icon, Color tint, String text, bool spin) = switch (
        status.state) {
      SyncState.synced => (
          Icons.cloud_done_rounded,
          context.semantic.success,
          l.syncUpToDate,
          false
        ),
      SyncState.syncing => (
          Icons.cloud_sync_rounded,
          c.primary,
          l.syncSyncing,
          true
        ),
      SyncState.pending => (
          Icons.cloud_queue_rounded,
          c.onSurfaceVariant,
          l.syncPendingOffline(status.pending),
          false
        ),
      SyncState.failed => (
          Icons.cloud_off_rounded,
          c.onSurfaceVariant,
          l.syncPendingWaiting(status.pending),
          false
        ),
    };

    final lastOk = status.lastOk;
    final outageDays = status.longOutageDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceContainerHighest,
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: spin
                    ? CircularProgressIndicator(strokeWidth: 2, color: tint)
                    : Icon(icon, color: tint, size: AppIconSize.md),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: c.onSurfaceVariant)),
                    if (lastOk != null)
                      Text(
                        l.syncLastBackup(
                            _formatWhen(context, lastOk, status.now)),
                        style: context.texts.bodySmall
                            ?.copyWith(color: c.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (outageDays != null) ...[
          AppSpacing.vGapSm,
          _SyncNotice(
            icon: Icons.schedule_rounded,
            text: l.syncLongOutage(outageDays),
          ),
        ],
        if (status.failed > 0) ...[
          AppSpacing.vGapSm,
          _SyncNotice(
            icon: Icons.error_outline_rounded,
            text: l.syncFailedRows(status.failed),
            onTap: () => ref.read(syncControllerProvider).retryFailed(),
          ),
        ],
        // Ret sessiz kalmamalı (docs/23 §2.3). Hata değil — bu yüzden
        // "yüklenemedi" satırından AYRI ve farklı simgeyle. Dokunmak
        // bildirimi kapatır: kullanıcı gördü, sayaç sıfırlanır.
        if (status.replaced > 0) ...[
          AppSpacing.vGapSm,
          _SyncNotice(
            icon: Icons.cloud_download_outlined,
            text: l.syncReplacedRows(status.replaced),
            onTap: () => SyncHealth(ref.read(databaseProvider)).clearReplaced(),
          ),
        ],
      ],
    );
  }

  /// "bugün 14:32" / "dün 09:10" / "12 Eyl 14:32" — cihaz diline göre.
  static String _formatWhen(BuildContext context, DateTime when, DateTime now) {
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale).format(when);
    final bugun = DateTime(now.year, now.month, now.day);
    final gun = DateTime(when.year, when.month, when.day);
    final fark = bugun.difference(gun).inDays;
    if (fark == 0) return l.syncWhenToday(time);
    if (fark == 1) return l.syncWhenYesterday(time);
    return DateFormat.MMMd(locale).add_Hm().format(when);
  }
}

/// Senkron satırının altındaki uyarı kutusu — turuncu, kırmızı değil: veri
/// kaybolmadı, telefonda duruyor. [onTap] verilirse dokunulabilir.
class _SyncNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _SyncNotice({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final warn = context.semantic.warning;
    return Material(
      color: warn.withValues(alpha: 0.12),
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: warn, size: AppIconSize.md),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(text,
                    style: context.texts.bodyMedium
                        ?.copyWith(color: context.colors.onSurface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
