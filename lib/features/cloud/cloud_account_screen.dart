import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status_tile.dart';
import 'auth_service.dart';

/// Hesap paneli (docs/18-auth-and-sync.md) — Profil'den açılır.
///
/// Giriş/kayıt formu **artık burada değil**: hesap zorunlu olduğu için form
/// uygulamanın önündeki tam ekran kapıya taşındı
/// (`features/auth/auth_screen.dart`, docs/18 §5.1). Bu ekrana yalnız oturumu
/// açık kullanıcı ulaşır → burada yapılacak iş Çıkış ve Hesabı Sil.
///
/// **Elle bulut yedekleme KALDIRILDI (2026-07-21, docs/18 §1).** Veriler
/// hesaba otomatik senkron edilir (outbox deseni, docs/18 §6) — kullanıcının
/// "yedekle"/"geri yükle" düğmelerine basmasına gerek yok. Senkron durumu
/// göstergesi Aşama G'de bu ekrana eklenecek.
class CloudAccountScreen extends ConsumerWidget {
  const CloudAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).settingsCloudAccount)),
      // Çıkış anında oturum düşer; kapı bu ekranı zaten karşılamayla
      // değiştirecek — o tek kare için boş gövde yeter.
      body: user == null
          ? const SizedBox.shrink()
          : _AccountPanel(email: user.email ?? '—'),
    );
  }
}

// ───────────────────────────── Hesap paneli ─────────────────────────────

class _AccountPanel extends ConsumerStatefulWidget {
  final String email;
  const _AccountPanel({required this.email});
  @override
  ConsumerState<_AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends ConsumerState<_AccountPanel> {
  bool _busy = false;

  /// Çıkış. Ekranı BURADAN kapatmıyoruz: oturum düşünce kapı devreye girip
  /// yığını karşılamayla değiştiriyor (`refreshListenable`). Elle `pop` etmek
  /// o yeni yığından bir sayfa götürme riski taşır.
  ///
  /// **Bekleyen kayıt varken uyarı** (docs/18 §9): yüklenmemiş veri varken
  /// sessizce çıkmak, o veriyi bir dahaki girişe kadar sunucusuz bırakır.
  Future<void> _signOut() async {
    final l = AppL10n.of(context);
    final controller = ref.read(syncControllerProvider);
    final pending = await controller.pendingCount();
    if (!mounted) return;

    if (pending > 0) {
      final choice = await showDialog<_SignOutChoice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.signOutPendingTitle),
          content: Text(l.signOutPendingMsg(pending)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SignOutChoice.cancel),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SignOutChoice.syncFirst),
              child: Text(l.signOutSyncFirst),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SignOutChoice.anyway),
              child: Text(l.signOutAnyway,
                  style: TextStyle(color: context.colors.error)),
            ),
          ],
        ),
      );
      if (choice == null || choice == _SignOutChoice.cancel || !mounted) return;

      if (choice == _SignOutChoice.syncFirst) {
        setState(() => _busy = true);
        await controller.syncNow();
        final left = await controller.pendingCount();
        if (!mounted) return;
        setState(() => _busy = false);
        if (left > 0) {
          // Hâlâ bekliyor (ağ yok) → çıkma, kullanıcı tekrar deneyebilir.
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.signOutStillPending)));
          return;
        }
      }
      // syncFirst başarılı ya da "yine de çık" → devam.
    }

    await ref.read(authServiceProvider).signOut();
  }

  /// Hesabı kalıcı sil (docs/16 §4) — çift onay.
  /// Sunucudaki veriler `on delete cascade` ile hesapla birlikte silinir
  /// (docs/18 §7). Cihazdaki yerel veri etkilenmez.
  Future<void> _deleteAccount() async {
    final l = AppL10n.of(context);
    final ok1 = await confirmAction(
      context,
      title: l.cloudDeleteTitle,
      message: l.cloudDeleteMsg,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok1 || !mounted) return;
    final ok2 = await confirmAction(
      context,
      title: l.cloudDeleteConfirm2Title,
      message: l.cloudDeleteConfirm2Msg,
      confirmLabel: l.cloudDeleteAccount,
      destructive: true,
    );
    if (!ok2 || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        // Silme oturumu da kapatır → kapı karşılamaya döndürür (elle pop yok).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cloudDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cloudDeleteFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppL10n.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // hesap başlığı
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: c.primaryContainer,
              child: Icon(Icons.person_rounded, color: c.onPrimaryContainer),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsCloudSignedInFallback,
                      style: context.texts.labelMedium
                          ?.copyWith(color: c.onSurfaceVariant)),
                  Text(widget.email,
                      style: context.texts.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vGapLg,
        const SyncStatusTile(),
        AppSpacing.vGapxl_,
        // C-35: çıkış geri alınabilir, olağan bir işlem → nötr. Hesap silme
        // kalıcı → ayrı, kırmızı ve ne yaptığını söyleyen bir alt bölümde.
        OutlinedButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(l.cloudSignOut),
        ),
        AppSpacing.vGapxl_,
        const Divider(),
        AppSpacing.vGapSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: Icon(Icons.delete_forever_rounded, color: c.error),
            label:
                Text(l.cloudDeleteAccount, style: TextStyle(color: c.error)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(l.cloudDeleteHint,
              style: context.texts.bodySmall
                  ?.copyWith(color: c.onSurfaceVariant)),
        ),
      ],
    );
  }
}

enum _SignOutChoice { cancel, syncFirst, anyway }
