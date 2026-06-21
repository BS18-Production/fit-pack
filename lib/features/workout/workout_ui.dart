import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Antrenman ekranları için paylaşılan görsel yardımcılar (Claude Design
/// `Fit Pack Antrenman.dc.html` reskin'i — docs/08-design-brief.md).
///
/// Hareket/ekipman/kas adları İngilizce (salon standardı), arayüz Türkçe.
class WorkoutUi {
  WorkoutUi._();

  /// Calisthenics kategori rengi — palette'te mor yok, design'daki violet.
  static const violet = Color(0xFF7C3AED);
  static const violetBright = Color(0xFFA78BFA);

  /// Kategori → vurgu rengi (design: compound→indigo, isolation→teal,
  /// calisthenics→violet, cardio→blue, flexibility→amber).
  static Color categoryColor(BuildContext context, String category) {
    final s = context.semantic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (category) {
      case 'isolation':
        return context.colors.secondary;
      case 'calisthenics':
        return dark ? violetBright : violet;
      case 'cardio':
        return s.info;
      case 'flexibility':
        return s.warning;
      case 'compound':
      default:
        return context.colors.primary;
    }
  }

  static const _categoryLabels = {
    'compound': 'Compound',
    'isolation': 'Isolation',
    'calisthenics': 'Calisthenics',
    'cardio': 'Cardio',
    'flexibility': 'Flexibility',
  };

  static String categoryLabel(String category) =>
      _categoryLabels[category] ?? category;

  static const _muscleLabels = {
    'chest': 'Chest',
    'upper_chest': 'Upper Chest',
    'back': 'Back',
    'shoulders': 'Shoulders',
    'front_delt': 'Front Delt',
    'rear_delt': 'Rear Delt',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'forearms': 'Forearms',
    'legs': 'Legs',
    'quads': 'Quads',
    'hamstrings': 'Hamstrings',
    'glutes': 'Glutes',
    'calves': 'Calves',
    'core': 'Core',
    'full_body': 'Full Body',
  };

  /// İngilizce kas adı (chip + altyazı için). Bilinmeyen değerleri
  /// kelime başlarını büyüterek gösterir.
  static String muscleLabel(String? muscle) {
    if (muscle == null || muscle.isEmpty) return '';
    return _muscleLabels[muscle] ?? _titleize(muscle);
  }

  static const _equipmentLabels = {
    'barbell': 'Barbell',
    'dumbbell': 'Dumbbell',
    'machine': 'Machine',
    'cable': 'Cable',
    'smith': 'Smith Machine',
    'kettlebell': 'Kettlebell',
    'bodyweight': 'Bodyweight',
    'cardio': 'Cardio Machine',
    'none': 'None',
  };

  static String equipmentLabel(String? equipment) {
    if (equipment == null || equipment.isEmpty) return '';
    return _equipmentLabels[equipment] ?? _titleize(equipment);
  }

  /// Ekipman → Material ikonu (design'daki ekipman rozet ikonları).
  static IconData equipmentIcon(String? equipment) {
    switch (equipment) {
      case 'cable':
        return Icons.cable_rounded;
      case 'machine':
        return Icons.precision_manufacturing_rounded;
      case 'smith':
        return Icons.view_week_rounded;
      case 'bodyweight':
        return Icons.accessibility_new_rounded;
      case 'cardio':
        return Icons.monitor_heart_rounded;
      case 'none':
        return Icons.self_improvement_rounded;
      case 'barbell':
      case 'dumbbell':
      case 'kettlebell':
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// Kategoriye göre önerilen varsayılan dinlenme süresi (saniye).
  /// Kullanıcı rutin oluştururken değiştirebilir.
  static int defaultRestSec(String category) {
    switch (category) {
      case 'compound':
        return 180; // ağır bileşik → uzun dinlenme
      case 'isolation':
        return 90;
      case 'calisthenics':
        return 90;
      case 'cardio':
        return 60;
      case 'flexibility':
        return 30;
      default:
        return 90;
    }
  }

  /// Dinlenme süresini etiketler: null/0 → "Yok", aksi halde "dk:sn".
  static String restLabel(int? sec) {
    if (sec == null || sec <= 0) return 'Yok';
    final m = sec ~/ 60;
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Rutin oluştururken sunulan dinlenme süresi seçenekleri (saniye).
  static const restOptions = <int>[
    0, 30, 45, 60, 75, 90, 120, 150, 180, 210, 240, 300,
  ];

  /// "Muscle · Equipment" altyazısı (İngilizce).
  static String muscleEquip(String? muscle, String? equipment) {
    final m = muscleLabel(muscle);
    final e = equipmentLabel(equipment);
    if (m.isEmpty) return e;
    if (e.isEmpty) return m;
    return '$m · $e';
  }

  static String _titleize(String raw) => raw
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  // ───────── Türkçe arama desteği ─────────
  // İngilizce hareket adlarının yanında Türkçe terimlerle de bulunabilsin
  // ("göğüs", "arka kol", "makine"). Kullanıcı eklemek zorunda kalmasın.

  static const _trMuscleTerms = {
    'chest': ['gogus', 'gogus kasi', 'pec'],
    'upper_chest': ['ust gogus'],
    'back': ['sirt', 'kanat', 'lat'],
    'shoulders': ['omuz', 'delt'],
    'front_delt': ['on omuz'],
    'rear_delt': ['arka omuz'],
    'side_delt': ['yan omuz'],
    'biceps': ['biceps', 'pazi', 'on kol', 'kol'],
    'triceps': ['triceps', 'arka kol', 'kol'],
    'forearms': ['on kol', 'bilek'],
    'legs': ['bacak', 'quad', 'on bacak'],
    'quads': ['bacak', 'on bacak', 'quad'],
    'hamstrings': ['arka bacak', 'hamstring'],
    'adductors': ['ic bacak'],
    'glutes': ['kalca', 'basen', 'popo', 'glute'],
    'core': ['karin', 'gobek', 'abs', 'core'],
    'obliques': ['yan karin', 'oblik'],
    'calves': ['baldir', 'kalf'],
    'traps': ['trapez', 'kapuze'],
    'lower_back': ['bel', 'alt sirt'],
    'full_body': ['tum vucut', 'full body', 'genel'],
    'cardio': ['kardiyo', 'kondisyon'],
    'neck': ['boyun'],
    'spine': ['omurga', 'bel'],
    'hip_flexors': ['kalca fleksor'],
  };

  static const _trEquipTerms = {
    'barbell': ['halter', 'bar', 'serbest'],
    'dumbbell': ['dambil', 'dumbell', 'serbest'],
    'machine': ['makine', 'makina', 'aletli'],
    'cable': ['kablo', 'makara', 'pulley'],
    'smith': ['smith', 'smith makinesi'],
    'kettlebell': ['kettlebell', 'girya'],
    'bodyweight': ['vucut agirligi', 'kendi agirligi', 'ekipmansiz'],
    'cardio': ['kardiyo', 'kardiyo makinesi'],
    'none': ['ekipmansiz'],
  };

  static const _trCategoryTerms = {
    'compound': ['bilesik', 'compound', 'cok eklemli'],
    'isolation': ['izolasyon', 'isolation', 'tek kas'],
    'calisthenics': ['kalistenik', 'vucut agirligi', 'calisthenics'],
    'cardio': ['kardiyo', 'cardio', 'kondisyon'],
    'flexibility': ['esneklik', 'germe', 'stretch', 'flexibility'],
  };

  /// Türkçe karakterleri sadeleştirip küçük harfe çevirir (arama için).
  static String normalize(String s) {
    final lower = s.toLowerCase();
    const map = {
      'ı': 'i', 'İ': 'i', 'ş': 's', 'ç': 'c', 'ö': 'o', 'ü': 'u', 'ğ': 'g',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Bir hareketin aranabilir tüm metni (İngilizce ad + İngilizce/Türkçe
  /// kas + ekipman + kategori), normalize edilmiş. `matchesQuery` kullanır.
  static String searchHaystack({
    required String name,
    required String category,
    String? primaryMuscle,
    String? equipment,
    List<String> muscles = const [],
  }) {
    final parts = <String>[
      name,
      category,
      categoryLabel(category),
      ...(_trCategoryTerms[category] ?? const []),
      if (primaryMuscle != null) ...[
        primaryMuscle,
        muscleLabel(primaryMuscle),
        ...(_trMuscleTerms[primaryMuscle] ?? const []),
      ],
      for (final m in muscles) ...[
        m,
        ...(_trMuscleTerms[m] ?? const []),
      ],
      if (equipment != null) ...[
        equipment,
        equipmentLabel(equipment),
        ...(_trEquipTerms[equipment] ?? const []),
      ],
    ];
    return normalize(parts.join(' '));
  }

  /// Boşlukla ayrılmış tüm kelimeler haystack içinde geçiyor mu (AND).
  static bool matchesQuery(String haystack, String query) {
    final q = normalize(query).trim();
    if (q.isEmpty) return true;
    for (final token in q.split(RegExp(r'\s+'))) {
      if (!haystack.contains(token)) return false;
    }
    return true;
  }
}

/// Design'daki indigo gradient birincil buton (Kaydet / Başla / CTA).
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.indigo, AppColors.indigoDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigoDeep.withValues(alpha: 0.26),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.brLg,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg + 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      AppSpacing.hGapSm,
                    ],
                    Text(label,
                        style: context.texts.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kesik çizgili dış çerçeve (design'daki "1px dashed" kutular için).
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final double radius;
  const DottedBorderBox({super.key, required this.child, this.radius = AppRadius.lg});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: context.colors.outline, radius: radius),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Design'daki yumuşak "chip" rozeti (kas grubu, kategori vb.).
class WorkoutChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool soft;
  const WorkoutChip(this.label, {super.key, this.color, this.soft = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurfaceVariant;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: soft
            ? c.withValues(alpha: dark ? 0.16 : 0.12)
            : context.colors.onSurface.withValues(alpha: dark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.texts.labelSmall?.copyWith(
          color: soft ? c : context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
