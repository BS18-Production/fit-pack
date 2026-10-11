import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/fitpack_icon.dart';
import 'health_prefs.dart';
import 'step_providers.dart';
import 'step_stats.dart';

Future<void> showStepPermissionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      // Sistem izin penceresi açıkken sheet'in ref'i yaşamaya devam eder.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _StepPermissionSheet(),
    );

Future<void> showStepWeekSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _StepWeekSheet(),
    );

Future<void> showStepGoalSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _StepGoalSheet(),
    );

/// Scroll ve klavye/güvenli alan boşluğu bütün sağlık panellerinde ortak.
class _SheetBody extends StatelessWidget {
  final Widget child;
  const _SheetBody({required this.child});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.xl,
      context.sheetBottomInset + AppSpacing.xl,
    ),
    child: child,
  );
}

class _StepPermissionSheet extends ConsumerStatefulWidget {
  const _StepPermissionSheet();

  @override
  ConsumerState<_StepPermissionSheet> createState() =>
      _StepPermissionSheetState();
}

class _StepPermissionSheetState extends ConsumerState<_StepPermissionSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var connected = false;
    try {
      await connectSteps(ref);
      if (!mounted) return;
      connected = ref.read(healthPrefsProvider).connected;
      if (!connected) _error = AppL10n.of(context).healthConnectError;
    } catch (_) {
      if (mounted) _error = AppL10n.of(context).healthConnectError;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && connected) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return PopScope(
      canPop: !_busy,
      child: _SheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.healthPermissionTitle, style: context.texts.titleLarge),
            AppSpacing.vGapXl,
            _PermissionLine(
              icon: Icons.directions_walk_rounded,
              text: l.healthPermissionStepsOnly,
            ),
            AppSpacing.vGapLg,
            _PermissionLine(
              icon: Icons.phone_iphone_rounded,
              text: l.healthPermissionOnDevice,
            ),
            AppSpacing.vGapLg,
            _PermissionLine(
              icon: Icons.lock_outline_rounded,
              text: l.healthPermissionNoSharing,
            ),
            if (_error != null) ...[
              AppSpacing.vGapLg,
              Text(
                _error!,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            AppSpacing.vGapXl,
            FilledButton(
              onPressed: _busy ? null : _connect,
              child: Text(l.healthConnect),
            ),
            AppSpacing.vGapSm,
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(l.healthNotNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PermissionLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FitPackIcon.material(icon, color: context.colors.primary),
      AppSpacing.hGapMd,
      Expanded(child: Text(text, style: context.texts.bodyMedium)),
    ],
  );
}

class _StepWeekSheet extends ConsumerStatefulWidget {
  const _StepWeekSheet();

  @override
  ConsumerState<_StepWeekSheet> createState() => _StepWeekSheetState();
}

class _StepWeekSheetState extends ConsumerState<_StepWeekSheet> {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final link = ref.watch(stepLinkStateProvider).valueOrNull;
    return _SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.healthWeekTitle, style: context.texts.titleLarge),
          AppSpacing.vGapXl,
          ref
              .watch(stepWeekProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Column(
                  children: [
                    Text(l.healthReadError),
                    TextButton(
                      onPressed: () => ref.invalidate(stepWeekProvider),
                      child: Text(l.healthRetry),
                    ),
                  ],
                ),
                data: (week) => week == null
                    ? Text(
                        link == StepLinkState.notConnected
                            ? l.healthNotConnected
                            : l.healthReadError,
                      )
                    : _StepWeekContent(week: week),
              ),
          AppSpacing.vGapLg,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonClose),
          ),
        ],
      ),
    );
  }
}

class _StepWeekContent extends StatelessWidget {
  final StepWeek week;
  const _StepWeekContent({required this.week});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final maxSteps = week.days.fold<int>(
      0,
      (v, day) => math.max(v, day.steps ?? 0),
    );
    final maxY = math.max(1000, (maxSteps / 1000).ceil() * 1000).toDouble();
    final sparseLabels =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (week.state == StepWeekState.noData) ...[
          Text(l.healthNoData, style: context.texts.bodyMedium),
          AppSpacing.vGapLg,
        ],
        Text(
          l.healthAverage,
          style: context.texts.bodySmall?.copyWith(color: c.onSurfaceVariant),
        ),
        Text(
          week.average == null
              ? '—'
              : l.healthStepCount(context.numFmt.format(week.average)),
          key: const ValueKey('health.average'),
          style: context.texts.headlineSmall,
        ),
        AppSpacing.vGapXl,
        Semantics(
          label: l.healthWeekTitle,
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: c.outlineVariant, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: sparseLabels ? 44 : 32,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 ||
                            i >= week.days.length ||
                            (sparseLabels && i.isOdd)) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            context.dateFmt('EE').format(week.days[i].day),
                            style: context.texts.labelSmall?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < week.days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        if (week.days[i].steps != null)
                          BarChartRodData(
                            toY: week.days[i].steps!.toDouble(),
                            color: c.primary,
                            width: AppSpacing.lg,
                            borderRadius: AppRadius.brSm,
                          ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => c.surfaceContainerHigh,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${context.dateFmt('d MMM').format(week.days[group.x].day)}\n${l.healthStepCount(context.numFmt.format(rod.toY.round()))}',
                      context.texts.labelSmall!.copyWith(color: c.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AppSpacing.vGapLg,
        // Grafik dışında tüm günler okunabilir; boş gün de açıkça "—".
        for (final day in week.days)
          Padding(
            key: ValueKey(day.day),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.dateFmt('EEE · d MMM').format(day.day),
                    style: context.texts.bodySmall,
                  ),
                ),
                AppSpacing.hGapSm,
                Flexible(
                  child: Text(
                    day.steps == null
                        ? '—'
                        : l.healthStepCount(context.numFmt.format(day.steps)),
                    style: context.texts.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepGoalSheet extends ConsumerStatefulWidget {
  const _StepGoalSheet();

  @override
  ConsumerState<_StepGoalSheet> createState() => _StepGoalSheetState();
}

class _StepGoalSheetState extends ConsumerState<_StepGoalSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(healthPrefsProvider).stepGoal;
    _controller = TextEditingController(text: goal?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final text = _controller.text.trim();
    final goal = text.isEmpty ? null : int.tryParse(text);
    if (text.isNotEmpty && (goal == null || goal < 0)) {
      setState(() => _error = AppL10n.of(context).commonInvalidNumber);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    var saved = false;
    try {
      await ref.read(healthPrefsProvider.notifier).setStepGoal(goal);
      if (!mounted) return;
      ref.invalidate(stepWeekProvider);
      saved = true;
    } catch (_) {
      if (mounted) _error = AppL10n.of(context).healthGoalSaveError;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted && saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return PopScope(
      canPop: !_saving,
      child: _SheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.healthStepGoal, style: context.texts.titleLarge),
            AppSpacing.vGapLg,
            TextField(
              key: const ValueKey('health.goalInput'),
              controller: _controller,
              autofocus: true,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l.healthSteps,
                helperText: l.healthGoalHint,
                helperMaxLines: 3,
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
            AppSpacing.vGapXl,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.commonSave),
            ),
            AppSpacing.vGapSm,
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(l.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}
