import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/nutrition_dao.dart';
import '../home/providers/home_providers.dart';

/// Selected date for nutrition log
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Food logs for selected date
final foodLogsForDateProvider = FutureProvider<List<FoodLog>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(nutritionDaoProvider).getLogsForDate(date);
});

/// Nutrition totals for selected date
final nutritionTotalsProvider = FutureProvider<DailyNutrition>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(nutritionDaoProvider).getDailyTotals(date);
});

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final totalsAsync = ref.watch(nutritionTotalsProvider);
    final logsAsync = ref.watch(foodLogsForDateProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beslenme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).state = picked;
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      date.subtract(const Duration(days: 1));
                },
              ),
              Text(
                DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(date),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final tomorrow = date.add(const Duration(days: 1));
                  if (tomorrow.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                    ref.read(selectedDateProvider.notifier).state = tomorrow;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macro summary card
          totalsAsync.when(
            data: (totals) => profileAsync.when(
              data: (profile) => _MacroSummaryCard(
                totals: totals,
                kcalGoal: profile?.kcalGoal ?? 2200,
                proteinGoal: profile?.proteinGoal ?? 180,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Meal sections
          ...['breakfast', 'lunch', 'dinner', 'snack'].map((mealType) {
            return logsAsync.when(
              data: (logs) {
                final mealLogs = logs.where((l) => l.mealType == mealType).toList();
                return _MealSection(
                  mealType: mealType,
                  logs: mealLogs,
                  onAddFood: () => _showAddFoodDialog(context, ref, mealType: mealType),
                  onDelete: (id) async {
                    await ref.read(nutritionDaoProvider).deleteFoodLog(id);
                    ref.invalidate(foodLogsForDateProvider);
                    ref.invalidate(nutritionTotalsProvider);
                    ref.invalidate(todayNutritionProvider);
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            );
          }),
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref, {String? mealType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddFoodSheet(
        mealType: mealType ?? 'lunch',
        ref: ref,
      ),
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final DailyNutrition totals;
  final int kcalGoal;
  final int proteinGoal;

  const _MacroSummaryCard({
    required this.totals,
    required this.kcalGoal,
    required this.proteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${totals.kcal.round()} / $kcalGoal kcal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (totals.kcal / kcalGoal).clamp(0.0, 1.0),
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip(
                  label: 'Protein',
                  value: '${totals.protein.round()}g',
                  goal: '${proteinGoal}g',
                  color: Colors.red,
                ),
                _MacroChip(
                  label: 'Karb',
                  value: '${totals.carb.round()}g',
                  goal: '--',
                  color: Colors.blue,
                ),
                _MacroChip(
                  label: 'Yağ',
                  value: '${totals.fat.round()}g',
                  goal: '--',
                  color: Colors.yellow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(goal, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

String _mealName(String type) {
  switch (type) {
    case 'breakfast':
      return 'Kahvaltı';
    case 'lunch':
      return 'Öğle';
    case 'dinner':
      return 'Akşam';
    case 'snack':
      return 'Atıştırma';
    default:
      return type;
  }
}

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLog> logs;
  final VoidCallback onAddFood;
  final Function(int) onDelete;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onAddFood,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalKcal = logs.fold<double>(0, (sum, l) => sum + l.computedKcal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _mealName(mealType),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Text(
                      '${totalKcal.round()} kcal',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: onAddFood,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Henüz kayıt yok',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )
            else
              ...logs.map((log) => Dismissible(
                    key: ValueKey(log.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => onDelete(log.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${log.computedKcal.round()} kcal',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            'P:${log.computedProtein.round()} K:${log.computedCarb.round()} Y:${log.computedFat.round()}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AddFoodSheet extends StatefulWidget {
  final String mealType;
  final WidgetRef ref;

  const _AddFoodSheet({required this.mealType, required this.ref});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _searchController = TextEditingController();
  List<Food> _results = [];
  Food? _selected;
  final _gramsController = TextEditingController(text: '100');
  String _currentMealType = 'lunch';

  @override
  void initState() {
    super.initState();
    _currentMealType = widget.mealType;
    _loadAllFoods();
  }

  Future<void> _loadAllFoods() async {
    final dao = widget.ref.read(nutritionDaoProvider);
    final foods = await dao.getAllFoods();
    setState(() => _results = foods.take(20).toList());
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadAllFoods();
      return;
    }
    final dao = widget.ref.read(nutritionDaoProvider);
    final foods = await dao.searchFoods(query);
    setState(() => _results = foods);
  }

  Future<void> _addFood() async {
    if (_selected == null) return;
    final grams = double.tryParse(_gramsController.text) ?? 100;
    final ratio = grams / 100;
    final date = widget.ref.read(selectedDateProvider);

    await widget.ref.read(nutritionDaoProvider).insertFoodLog(FoodLogsCompanion(
          date: Value(date),
          mealType: Value(_currentMealType),
          foodId: Value(_selected!.id),
          grams: Value(grams),
          computedKcal: Value(_selected!.kcalPer100g * ratio),
          computedProtein: Value(_selected!.proteinPer100g * ratio),
          computedCarb: Value(_selected!.carbPer100g * ratio),
          computedFat: Value(_selected!.fatPer100g * ratio),
        ));

    widget.ref.invalidate(foodLogsForDateProvider);
    widget.ref.invalidate(nutritionTotalsProvider);
    widget.ref.invalidate(todayNutritionProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            children: [
              // Meal type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'breakfast', label: Text('Kahvaltı')),
                  ButtonSegment(value: 'lunch', label: Text('Öğle')),
                  ButtonSegment(value: 'dinner', label: Text('Akşam')),
                  ButtonSegment(value: 'snack', label: Text('Atıştırma')),
                ],
                selected: {_currentMealType},
                onSelectionChanged: (v) => setState(() => _currentMealType = v.first),
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Yemek ara...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _search,
              ),
              const SizedBox(height: 12),

              // Results
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final food = _results[index];
                    final isSelected = _selected?.id == food.id;

                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.kcalPer100g.round()} kcal | P:${food.proteinPer100g.round()} K:${food.carbPer100g.round()} Y:${food.fatPer100g.round()} (100g)',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      onTap: () => setState(() => _selected = food),
                    );
                  },
                ),
              ),

              // Grams input + Add button
              if (_selected != null) ...[
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _gramsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(suffixText: 'g'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addFood,
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
