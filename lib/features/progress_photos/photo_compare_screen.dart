import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/services/photo_storage.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'progress_photos_providers.dart';
import 'progress_photos_screen.dart' show photoAngleLabel;

/// İki fotoğraf yan yana (docs/19 §2 — "özelliğin asıl değeri").
///
/// Eski olan **solda**, yeni olan sağda — seçim sırası ne olursa olsun.
/// Zaman soldan sağa akmazsa karşılaştırma ters okunur.
class PhotoCompareScreen extends ConsumerWidget {
  final int a;
  final int b;

  const PhotoCompareScreen({super.key, required this.a, required this.b});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final photosAsync = ref.watch(progressPhotosProvider);
    final dir = ref.watch(photoDirProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.ppCompare)),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: l.ppLoadError,
          onRetry: () => ref.invalidate(progressPhotosProvider),
        ),
        data: (all) {
          final byId = {for (final p in all) p.id: p};
          final pa = byId[a];
          final pb = byId[b];
          if (pa == null || pb == null || dir == null) {
            return EmptyState(
              icon: Icons.broken_image_outlined,
              title: l.ppMissingFile,
              message: l.ppCompareHint,
            );
          }
          final (eski, yeni) =
              pa.date.isAfter(pb.date) ? (pb, pa) : (pa, pb);
          final gun = DateTime(yeni.date.year, yeni.date.month, yeni.date.day)
              .difference(
                  DateTime(eski.date.year, eski.date.month, eski.date.day))
              .inDays;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(l.ppDaysApart(gun), style: context.texts.titleMedium),
                AppSpacing.vGapMd,
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _Side(photo: eski, dir: dir)),
                      AppSpacing.hGapSm,
                      Expanded(child: _Side(photo: yeni, dir: dir)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final ProgressPhoto photo;
  final Directory dir;

  const _Side({required this.photo, required this.dir});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final file = PhotoStorage.fileIn(dir, photo.imagePath);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.brMd,
            child: ColoredBox(
              color: context.colors.surfaceContainerHighest,
              child: file == null
                  ? const SizedBox.shrink()
                  : InteractiveViewer(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(l.ppMissingFile,
                              style: context.texts.bodySmall),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        AppSpacing.vGapSm,
        Text(
          '${context.dateFmt('d MMM yyyy').format(photo.date)} · '
          '${photoAngleLabel(l, photo.angle)}',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium,
        ),
      ],
    );
  }
}
