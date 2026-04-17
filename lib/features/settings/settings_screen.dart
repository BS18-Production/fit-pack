import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/constants/app_constants.dart';
import '../../data/providers.dart';
import '../../data/database/app_database.dart';
import '../home/providers/home_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil bulunamadı'));
          }
          return _SettingsBody(profile: profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final UserProfileData profile;
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  const _SettingsBody({required this.profile});

  Future<void> _save(WidgetRef ref, UserProfileData updated) async {
    await ref.read(userProfileDaoProvider).updateProfile(updated);
    ref.invalidate(userProfileProvider);
  }

  Future<void> _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String unit,
    required num initial,
    required bool isInt,
    required UserProfileData Function(num value) apply,
  }) async {
    final controller = TextEditingController(text: initial.toString());
    try {
      final result = await showDialog<num>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
            decoration: InputDecoration(suffixText: unit),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final v = isInt
                    ? int.tryParse(controller.text)
                    : double.tryParse(controller.text.replaceAll(',', '.'));
                if (v != null && v >= 0) Navigator.pop(ctx, v);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (result != null) {
        await _save(ref, apply(result));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _resetDeload(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deload Sıfırla'),
        content: const Text(
          'Deload tarihi şu ana ayarlanacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _save(
        ref,
        profile.copyWith(lastDeload: Value(DateTime.now())),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deload sıfırlandı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const _SectionHeader('Hedefler'),
        ListTile(
          leading: const Icon(Icons.local_fire_department, color: Colors.orange),
          title: const Text('Kalori Hedefi'),
          trailing: Text('${profile.kcalGoal} kcal'),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Kalori Hedefi',
            unit: 'kcal',
            initial: profile.kcalGoal,
            isInt: true,
            apply: (v) => profile.copyWith(kcalGoal: v.toInt()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.egg_outlined, color: Colors.red),
          title: const Text('Protein Hedefi'),
          trailing: Text('${profile.proteinGoal} g'),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Protein Hedefi',
            unit: 'g',
            initial: profile.proteinGoal,
            isInt: true,
            apply: (v) => profile.copyWith(proteinGoal: v.toInt()),
          ),
        ),

        const _SectionHeader('Program'),
        ListTile(
          leading: const Icon(Icons.timeline, color: Colors.blue),
          title: const Text('Faz'),
          trailing: Text('${profile.currentPhase}'),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Faz (1-3)',
            unit: '',
            initial: profile.currentPhase,
            isInt: true,
            apply: (v) =>
                profile.copyWith(currentPhase: v.toInt().clamp(1, 3)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month, color: Colors.purple),
          title: const Text('Hafta'),
          trailing: Text('${profile.currentWeek}'),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Hafta',
            unit: '',
            initial: profile.currentWeek,
            isInt: true,
            apply: (v) => profile.copyWith(currentWeek: v.toInt()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.teal),
          title: const Text('Son Deload'),
          subtitle: Text(
            profile.lastDeload == null
                ? 'Henüz deload yapılmadı'
                : _isoDate.format(profile.lastDeload!),
          ),
          trailing: const Icon(Icons.refresh),
          onTap: () => _resetDeload(context, ref),
        ),

        const _SectionHeader('Vücut'),
        ListTile(
          leading: const Icon(Icons.height, color: Colors.indigo),
          title: const Text('Boy'),
          trailing: Text(
            profile.heightCm != null ? '${profile.heightCm} cm' : '-',
          ),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Boy',
            unit: 'cm',
            initial: profile.heightCm ?? 175,
            isInt: false,
            apply: (v) =>
                profile.copyWith(heightCm: Value(v.toDouble())),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: Colors.green),
          title: const Text('Hedef Kilo'),
          trailing: Text(
            profile.goalWeightKg != null ? '${profile.goalWeightKg} kg' : '-',
          ),
          onTap: () => _editNumber(
            context,
            ref,
            title: 'Hedef Kilo',
            unit: 'kg',
            initial: profile.goalWeightKg ?? 80,
            isInt: false,
            apply: (v) =>
                profile.copyWith(goalWeightKg: Value(v.toDouble())),
          ),
        ),

        const _SectionHeader('Hakkında'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text(AppConstants.appName),
          subtitle: Text('Sürüm ${AppConstants.appVersion} · Kişisel fitness takibi'),
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Veri Export'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/export'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
