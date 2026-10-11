import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../insights/insight_window.dart';
import 'assistant_calculator.dart';
import 'assistant_contract.dart';
import 'assistant_labels.dart';

Future<AssistantSelection?> pickAssistantSelection(
  BuildContext context,
  AssistantSelection initial,
  AssistantData data,
) => showModalBottomSheet<AssistantSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AssistantSelectionSheet(initial: initial, data: data),
);

class AssistantSelectionSheet extends ConsumerStatefulWidget {
  final AssistantSelection initial;
  final AssistantData data;
  const AssistantSelectionSheet({
    super.key,
    required this.initial,
    required this.data,
  });
  @override
  ConsumerState<AssistantSelectionSheet> createState() => _SelectionState();
}

class _SelectionState extends ConsumerState<AssistantSelectionSheet> {
  late AssistantQuery _query = widget.initial.query;
  late InsightPeriod _period = widget.initial.period;
  late int? _exercise = widget.initial.exerciseId;
  late String? _meal = widget.initial.mealType;
  late bool _interpretation = widget.initial.interpretation;
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final usedIds = widget.data.points.map((e) => e.exerciseId).toSet();
    final exercises =
        widget.data.exercises.values
            .where((e) => usedIds.contains(e.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return FractionallySizedBox(
      heightFactor: .85,
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.assistantChange, style: context.texts.titleLarge),
            AppSpacing.vGapLg,
            Expanded(
              child: ListView(
                children: [
                  DropdownButtonFormField<AssistantQuery>(
                    initialValue: _query,
                    isExpanded: true,
                    items: [
                      for (final q in AssistantQuery.values.where(
                        (q) => q != AssistantQuery.outOfScope,
                      ))
                        DropdownMenuItem(
                          value: q,
                          child: Text(queryLabel(l, q)),
                        ),
                    ],
                    onChanged: (q) {
                      if (q == null) return;
                      setState(() {
                        _query = q;
                        if (!q.periods.contains(_period)) {
                          _period = q.periods.first;
                        }
                      });
                    },
                  ),
                  AppSpacing.vGapLg,
                  Text(l.assistantPeriod, style: context.texts.labelLarge),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in _query.periods)
                        ChoiceChip(
                          label: Text(assistantPeriodLabel(l, p)),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
                        ),
                    ],
                  ),
                  if (_query == AssistantQuery.exerciseHistory) ...[
                    AppSpacing.vGapLg,
                    Text(l.assistantExercise, style: context.texts.labelLarge),
                    if (exercises.isEmpty) Text(l.assistantNoData),
                    RadioGroup<int>(
                      groupValue: _exercise,
                      onChanged: (id) => setState(() => _exercise = id),
                      child: Column(
                        children: [
                          for (final e in exercises)
                            RadioListTile<int>(
                              title: Text(e.name),
                              value: e.id,
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_query == AssistantQuery.todayRemaining) ...[
                    AppSpacing.vGapLg,
                    Text(l.assistantMeal, style: context.texts.labelLarge),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: Text(l.assistantNoMeal),
                          selected: _meal == null,
                          onSelected: (_) => setState(() => _meal = null),
                        ),
                        for (final e in {
                          'breakfast': l.mealBreakfast,
                          'lunch': l.mealLunch,
                          'dinner': l.mealDinner,
                          'snack': l.mealSnack,
                        }.entries)
                          ChoiceChip(
                            label: Text(e.value),
                            selected: _meal == e.key,
                            onSelected: (_) => setState(() => _meal = e.key),
                          ),
                      ],
                    ),
                  ],
                  AppSpacing.vGapLg,
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.assistantInterpretation),
                    value: _interpretation,
                    onChanged: (v) => setState(() => _interpretation = v),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed:
                  _query == AssistantQuery.exerciseHistory && _exercise == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      AssistantSelection(
                        query: _query,
                        period: _period,
                        exerciseId: _query == AssistantQuery.exerciseHistory
                            ? _exercise
                            : null,
                        mealType: _query == AssistantQuery.todayRemaining
                            ? _meal
                            : null,
                        interpretation: _interpretation,
                      ),
                    ),
              child: Text(l.assistantApply),
            ),
          ],
        ),
      ),
    );
  }
}
