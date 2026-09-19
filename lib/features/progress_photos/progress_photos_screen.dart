import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/formatting.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/database/app_database.dart';
import '../../data/services/photo_storage.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import 'progress_photos_providers.dart';

/// Açı anahtarının cihaz dilindeki adı.
String photoAngleLabel(AppL10n l, String angle) => switch (angle) {
      'front' => l.ppAngleFront,
      'side' => l.ppAngleSide,
      'back' => l.ppAngleBack,
      _ => angle,
    };

/// **İlerleme fotoğrafları galerisi** (docs/19 §2 dilim 1).
///
/// Tarihe göre gruplu ızgara + açı süzgeci + iki fotoğraf seçip
/// karşılaştırma. Fotoğraflar cihazdan çıkmaz; ekranın başında bunu söyleyen
/// kalıcı bir satır var — kullanıcı "yedeklendi" sanmasın.
class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  /// Açı süzgeci; `null` = tümü.
  String? _angle;

  /// Karşılaştırma seçimi açık mı ve seçilenler (en çok 2).
  bool _selecting = false;
  final _selected = <int>[];

  @override
  void initState() {
    super.initState();
    // Yetim dosya süpürmesi (docs/19 K-3): yerel ve ucuz, galeri açılışında.
    ref.read(progressPhotoActionsProvider).sweep().ignore();
  }

  void _toggleSelect(ProgressPhoto p) {
    setState(() {
      if (_selected.contains(p.id)) {
        _selected.remove(p.id);
      } else if (_selected.length < 2) {
        _selected.add(p.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final photosAsync = ref.watch(progressPhotosProvider);
    final dir = ref.watch(photoDirProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selecting ? l.ppSelected(_selected.length) : l.ppTitle),
        actions: [
          IconButton(
            tooltip: l.ppCompare,
            isSelected: _selecting,
            icon: const Icon(Icons.compare_rounded),
            onPressed: () => setState(() {
              _selecting = !_selecting;
              _selected.clear();
            }),
          ),
        ],
      ),
      floatingActionButton: _selecting
          ? (_selected.length == 2
              ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () => context.push(
                      AppRoutes.photoCompare(_selected[0], _selected[1])),
                  icon: const Icon(Icons.compare_rounded),
                  label: Text(l.ppCompare),
                )
              : null)
          : FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => showAddPhotoSheet(context),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text(l.ppAdd),
            ),
      body: photosAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: [Skeleton.card(height: 200)],
        ),
        error: (_, _) => ErrorState(
          message: l.ppLoadError,
          onRetry: () => ref.invalidate(progressPhotosProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return ListView(
              padding: AppSpacing.screen,
              children: [
                const _DeviceOnlyNote(),
                AppSpacing.vGapLg,
                EmptyState(
                  icon: Icons.photo_camera_outlined,
                  title: l.ppEmptyTitle,
                  message: l.ppEmptyMsg,
                  actionLabel: l.ppAdd,
                  onAction: () => showAddPhotoSheet(context),
                  compact: true,
                ),
              ],
            );
          }
          final photos =
              _angle == null ? all : all.where((p) => p.angle == _angle).toList();
          final groups = _groupByDay(photos);
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                AppSpacing.lg, AppSpacing.xxl * 3),
            children: [
              const _DeviceOnlyNote(),
              AppSpacing.vGapMd,
              if (_selecting) ...[
                Text(l.ppCompareHint,
                    style: context.texts.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
                AppSpacing.vGapSm,
              ],
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text(l.ppAll),
                    selected: _angle == null,
                    onSelected: (_) => setState(() => _angle = null),
                  ),
                  for (final a in photoAngles)
                    ChoiceChip(
                      label: Text(photoAngleLabel(l, a)),
                      selected: _angle == a,
                      onSelected: (_) => setState(() => _angle = a),
                    ),
                ],
              ),
              AppSpacing.vGapMd,
              for (final g in groups) ...[
                Text(context.dateFmt('d MMMM yyyy').format(g.day),
                    style: context.texts.titleSmall),
                AppSpacing.vGapSm,
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 3 / 4,
                  children: [
                    for (final p in g.photos)
                      _PhotoTile(
                        key: ValueKey('photo-${p.id}'),
                        photo: p,
                        dir: dir,
                        selected: _selected.contains(p.id),
                        onTap: _selecting
                            ? () => _toggleSelect(p)
                            : () => _openViewer(context, p, dir),
                      ),
                  ],
                ),
                AppSpacing.vGapLg,
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openViewer(
      BuildContext context, ProgressPhoto p, Directory? dir) async {
    final l = AppL10n.of(context);
    final file = dir == null ? null : PhotoStorage.fileIn(dir, p.imagePath);
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Center(
                  child: file == null
                      ? const SizedBox.shrink()
                      : Image.file(file,
                          errorBuilder: (_, _, _) => _Missing(l: l)),
                ),
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    tooltip: l.commonClose,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Expanded(
                    child: Text(
                      '${ctx.dateFmt('d MMM yyyy').format(p.date)} · '
                      '${photoAngleLabel(l, p.angle)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    color: Colors.white,
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final ok = await confirmAction(ctx,
                          title: l.ppDeleteTitle, message: l.ppDeleteMsg);
                      if (!ok) return;
                      await ref.read(progressPhotoActionsProvider).remove(p);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _DayGroup = ({DateTime day, List<ProgressPhoto> photos});

List<_DayGroup> _groupByDay(List<ProgressPhoto> photos) {
  final map = <DateTime, List<ProgressPhoto>>{};
  for (final p in photos) {
    final d = DateTime(p.date.year, p.date.month, p.date.day);
    map.putIfAbsent(d, () => []).add(p);
  }
  final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final d in days) (day: d, photos: map[d]!)];
}

class _DeviceOnlyNote extends StatelessWidget {
  const _DeviceOnlyNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: AppIconSize.sm, color: c.onSurfaceVariant),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            AppL10n.of(context).ppDeviceOnly,
            style: context.texts.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ProgressPhoto photo;
  final Directory? dir;
  final bool selected;
  final VoidCallback onTap;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.dir,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final file = dir == null ? null : PhotoStorage.fileIn(dir!, photo.imagePath);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surfaceContainerHighest),
            if (file != null)
              Image.file(
                file,
                fit: BoxFit.cover,
                // Küçük önizleme için küçük kod çözme — ızgarada 1440 px'lik
                // görselleri tam boy çözmek belleği boşa harcar.
                cacheWidth: 360,
                errorBuilder: (_, _, _) => _Missing(l: l),
              ),
            Positioned(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(photoAngleLabel(l, photo.angle),
                    style: context.texts.labelSmall
                        ?.copyWith(color: Colors.white)),
              ),
            ),
            if (selected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: c.primary, width: 3),
                  borderRadius: AppRadius.brMd,
                ),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.check_circle_rounded, color: c.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  final AppL10n l;
  const _Missing({required this.l});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(l.ppMissingFile,
              textAlign: TextAlign.center,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
      );
}

// ───────────────────────────── Ekleme paneli ─────────────────────────────

/// Fotoğraf ekleme paneli: açı + tarih seç, sonra kamera ya da galeri.
Future<void> showAddPhotoSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _AddPhotoSheet(),
    );

class _AddPhotoSheet extends ConsumerStatefulWidget {
  const _AddPhotoSheet();

  @override
  ConsumerState<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends ConsumerState<_AddPhotoSheet> {
  String _angle = 'front';
  DateTime _date = DateTime.now();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    final l = AppL10n.of(context);
    try {
      // Küçültme seçim anında (docs/19 §5): 1440 px, kalite 85 →
      // fotoğraf başına ~250–400 KB.
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (x == null) return; // kullanıcı vazgeçti
      await ref
          .read(progressPhotoActionsProvider)
          .add(File(x.path), _date, _angle);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.ppSaveError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (d != null) {
      // Seçilen gün + şimdiki saat: aynı güne birden çok fotoğraf sıralı kalsın.
      setState(() => _date =
          DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l.ppAdd),
            AppSpacing.vGapMd,
            Text(l.ppAngle, style: context.texts.labelMedium),
            AppSpacing.vGapXs,
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final a in photoAngles)
                  ButtonSegment(value: a, label: Text(photoAngleLabel(l, a))),
              ],
              selected: {_angle},
              onSelectionChanged: (s) => setState(() => _angle = s.first),
            ),
            AppSpacing.vGapMd,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(l.commonDate),
              trailing: Text(context.dateFmt('d MMM yyyy').format(_date)),
              onTap: _busy ? null : _pickDate,
            ),
            AppSpacing.vGapMd,
            FilledButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(l.ppCamera),
            ),
            AppSpacing.vGapSm,
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(l.ppGallery),
            ),
          ],
        ),
      ),
    );
  }
}
