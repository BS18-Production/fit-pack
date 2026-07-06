import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// Tutarlı boş/hata/yükleniyor durumları + onay diyaloğu.
/// Tüm ekranlar bunları kullanır — durum gösterimi tek elden.

/// Veri yokken gösterilir: ikon + başlık + açıklama + (opsiyonel) aksiyon.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Dar alanlarda (örn. klavye açık modal sheet) Column taşmasın diye
    // kaydırılabilir + ortalanmış. Yer varsa ortada durur, yoksa kayar.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: compact ? AppIconSize.lg : AppIconSize.xl,
                  color: context.colors.onSurfaceVariant),
            ),
            AppSpacing.vGapLg,
            Text(title,
                textAlign: TextAlign.center,
                style: context.texts.titleMedium),
            if (message != null) ...[
              AppSpacing.vGapSm,
              Text(message!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.vGapLg,
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hata durumu: kullanıcı-dostu mesaj + (opsiyonel) yeniden dene.
/// Teknik detayı KULLANICIYA göstermez (log'a bırakılır).
class ErrorState extends StatelessWidget {
  /// null → genel "Bir şeyler ters gitti" (locale'e göre, build'de çözülür).
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: AppIconSize.lg, color: context.colors.error),
            ),
            AppSpacing.vGapLg,
            Text(message ?? AppL10n.of(context).errorGeneric,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium),
            if (onRetry != null) ...[
              AppSpacing.vGapLg,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded,
                    size: AppIconSize.sm),
                label: Text(AppL10n.of(context).commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer'lı iskelet kutu — gerçek skeleton yükleme (spinner değil).
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.brSm,
  });

  /// Hazır kart yüksekliğinde iskelet.
  static Widget card({double height = 96}) => _SkeletonCard(height: height);

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema OKUMASI build()'de yapılır — AnimatedBuilder'ın builder'ı içinde
    // DEĞİL. Aksi halde sürekli repeat eden controller her tick'te
    // Theme.of(context) çağırır; kısa ömürlü skeleton hızlı mount/unmount
    // olunca InheritedElement'te dangling dependent kalır
    // (InheritedElement.debugDeactivated: _dependents.isEmpty assertion).
    final base = context.colors.surfaceContainerHigh;
    final highlight = context.colors.surfaceContainerHighest;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(-1 - 2 * _c.value, 0),
                end: Alignment(1 - 2 * _c.value, 0),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    // Tek shimmer blok — taşma riski yok, her yükseklikte çalışır.
    return Skeleton(
      height: height,
      borderRadius: AppRadius.brLg,
    );
  }
}

/// Bottom sheet başlığı: tutamaç (grabber) + başlık + kapat (X).
/// Her modal sheet bunu en üste koyar → kullanıcı ASLA kapatamadan kalmaz.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSpacing.vGapSm,
        // Grabber — aşağı sürükleyerek kapatılabileceğini gösterir.
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: AppRadius.brSm,
          ),
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleLarge),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              tooltip: AppL10n.of(context).commonClose,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surfaceContainerHigh,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Veritabanı bağlantısı kapandıktan sonra (yedekten geri yükleme) gösterilen
/// KAPATILAMAZ diyalog. Geri tuşu dahil hiçbir yolla geçilemez — uygulama
/// kapalı bağlantıyla çalışmaya devam edemez, tek çıkış yeniden başlatmak.
Future<void> showRestartDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(AppL10n.of(ctx).commonCloseApp),
          ),
        ],
      ),
    ),
  );
}

/// Tehlikeli işlem öncesi onay. true dönerse devam et.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel, // null → "Sil"/"Delete" (locale'e göre)
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppL10n.of(ctx).commonCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: ctx.colors.error,
                  foregroundColor: ctx.colors.onError)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? AppL10n.of(ctx).commonDelete),
        ),
      ],
    ),
  );
  return result ?? false;
}
