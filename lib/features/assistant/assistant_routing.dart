import '../../data/database/app_database.dart';
import 'assistant_contract.dart';

// Python'un Unicode sözcük sınırları Türkçe karakterlerle korunur.
const _word = r'a-z0-9_çğıöşü';
final _injection = <RegExp>[
  RegExp(r'[{}]'),
  RegExp(
    '(?<![$_word])(query|period|confidence|exercise|criteria|noul|choice)\\s*[=:]',
  ),
  RegExp('(?<![$_word])[a-z]+_[a-z_]+(?![$_word])'),
  RegExp(
    '^\\s*(sistem|system|yönetici|admin|developer|geliştirici)(?![$_word])[^\\n]{0,20}[:：]',
  ),
  RegExp(
    '(talimat|kural|komut|instruction|rule)[$_word]*[^$_word]+([$_word]+[^$_word]+){0,3}(unut|boşver|yok say|görmezden|ignore|forget)',
  ),
  RegExp(
    '(unut|boşver|yok say|görmezden gel|ignore|forget)[$_word]*[^$_word]+([$_word]+[^$_word]+){0,3}(talimat|kural|instruction|rule)',
  ),
  RegExp('(?<![$_word])(prompt|jailbreak)(?![$_word])'),
];
bool assistantPrefilter(String question) =>
    _injection.any((r) => r.hasMatch(question.toLowerCase()));

class FrozenAssistantRouter {
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> families;
  FrozenAssistantRouter(Map<String, dynamic> data)
    : exercises = (data['exercises']['exercises'] as List)
          .cast<Map<String, dynamic>>(),
      families = (data['exercises']['families'] as List)
          .cast<Map<String, dynamic>>() {
    if (data['fingerprint'] != assistantFingerprint ||
        data['model'] != assistantModel) {
      throw const FormatException('Unsupported frozen router');
    }
  }
  Set<String> get exerciseIds => {
    'none',
    for (final e in exercises) e['id'] as String,
    for (final f in families) f['id'] as String,
  };
  bool mentionsExercise(
    String question, {
    Iterable<String> localNames = const [],
  }) {
    final keywords = {
      for (final e in exercises) ...((e['keywords'] as List).cast<String>()),
      ...localNames,
    };
    final t = question.toLowerCase();
    return keywords.any(
      (k) =>
          k.isNotEmpty &&
          RegExp(
            "(?<![a-zçğıöşü])${RegExp.escape(k.toLowerCase())}[a-zçğıöşü']{0,6}(?![a-zçğıöşü])",
          ).hasMatch(t),
    );
  }

  RoutingDecision decide(
    AssistantRoute p,
    String question, {
    Iterable<String> localNames = const [],
  }) {
    if (assistantPrefilter(question)) return RoutingDecision.fallback;
    if (p.multiIntent) return RoutingDecision.multi;
    if (p.advice || p.query == AssistantQuery.outOfScope || p.ambiguous) {
      return RoutingDecision.fallback;
    }
    if (p.query == AssistantQuery.weightTrend &&
        (p.exercise != 'none' ||
            mentionsExercise(question, localNames: localNames))) {
      return RoutingDecision.fallback;
    }
    if (p.query == AssistantQuery.todayRemaining &&
        !{'today', 'unspecified'}.contains(p.period)) {
      return RoutingDecision.fallback;
    }
    if (p.query == AssistantQuery.exerciseHistory) {
      if (exercises.any(
        (e) => e['id'] == p.exercise && e['measurement'] != 'weight_reps',
      )) {
        return RoutingDecision.fallback;
      }
      if (p.exercise == 'none') {
        return RoutingDecision.clarify;
      }
    }
    if (p.query != AssistantQuery.streak &&
        p.query != AssistantQuery.todayRemaining &&
        !p.query.periods.any((v) => periodId(v) == p.period)) {
      return RoutingDecision.clarify;
    }
    return RoutingDecision.auto;
  }

  /// Açık ad eşlemesi; belirsiz metin benzerliğiyle farklı varyant seçilmez.
  List<Exercise> candidates(String id, Iterable<Exercise> local) {
    final specs = id.startsWith('fam_')
        ? exercises.where((e) => 'fam_${e['family']}' == id)
        : exercises.where((e) => e['id'] == id);
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const aliases = {
      'ex_barbell_bench_press': ['Bench Press'],
      'ex_barbell_back_squat': ['Barbell Squat', 'Back Squat'],
      'ex_conventional_deadlift': ['Deadlift'],
      'ex_pull_up': ['Pull Ups'],
      'ex_leg_extension': ['Leg Extensions'],
      'ex_barbell_curl': ['Barbell Curls'],
      'ex_hammer_curl': ['Hammer Curls'],
    };
    final names = {
      for (final e in specs) norm(e['name'] as String),
      for (final e in specs) ...[
        for (final n in aliases[e['id']] ?? <String>[]) norm(n),
      ],
    };
    return local.where((e) => names.contains(norm(e.name))).toList();
  }
}

/// Donmuş eşleyiciden ayrı gizlilik koruması; sağlık/kimlik metni gönderilmez.
bool assistantSensitiveInput(String question) {
  final t = question.toLowerCase();
  return RegExp(r'[\w.+-]+@[\w.-]+\.[a-z]{2,}').hasMatch(t) ||
      RegExp(r'\b\d{11}\b|(?:\+?\d[\s()-]*){10,}').hasMatch(t) ||
      RegExp(
        r'\b(hiv|aids|diyabet|diabetes|kanser|cancer|hamile|pregnan|depresyon|depression|hastal|sakat|injur|diagnos|teşhis|ilac|ilaç)\w*',
        unicode: true,
      ).hasMatch(t) ||
      RegExp(
        r'\d+(?:[.,]\d+)?\s*(?:kg|kilo|cm|kcal|kalori|gram|mg)\b',
      ).hasMatch(t);
}
