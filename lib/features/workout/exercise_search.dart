import 'dart:convert';

import 'workout_ui.dart';

/// Hareket arama v2 (docs/21 §2 #11) — saf mantık, arayüz ve DB bilmez.
///
/// Eski arama adı ve kas/ekipman terimlerini tek metinde **kelime parçası**
/// olarak arıyordu ve sıralama yapmıyordu: "lat" 485 sonuç veriyordu (plate,
/// lateral, alternating…), "şınav" hiç sonuç vermiyordu (adlar İngilizce).
/// Bu modül:
/// - **kelime başından** eşleştirir ("lat" → "Lat Pulldown", "plate" değil),
/// - tire/boşluk/çoğul farkını yok sayar ("pullup" = "Pull-Up" = "pull ups"),
/// - Türkçe karşılıkları kural dosyasından üretir
///   (`assets/data/exercise_terms_tr.json`),
/// - sonuçları **alakaya göre** sıralar: ad > Türkçe ad > birincil kas >
///   ekipman/kategori > ikincil kas; temel hareketler ve kullanıcının son
///   yaptıkları öne çıkar.

// ─────────────────────────────────────────────── Metin sadeleştirme

const _trFold = {
  'ı': 'i',
  'i̇': 'i',
  'ş': 's',
  'ç': 'c',
  'ö': 'o',
  'ü': 'u',
  'ğ': 'g',
  'â': 'a',
  'î': 'i',
  'û': 'u',
};

/// Birleşik yazılan hareket kelimeleri → ayrı kelimeler.
const _compounds = {
  'pushup': ['push', 'up'],
  'pullup': ['pull', 'up'],
  'chinup': ['chin', 'up'],
  'situp': ['sit', 'up'],
  'stepup': ['step', 'up'],
  'warmup': ['warm', 'up'],
  'muscleup': ['muscle', 'up'],
};

/// Çoğul/ek farkı: arama ve kurallar tekil kelimeyle çalışır.
const _irregularSingular = {
  'flyes': 'fly',
  'flies': 'fly',
  'presses': 'press',
  'crunches': 'crunch',
  'triceps': 'tricep',
  'biceps': 'bicep',
  'ups': 'up',
};

/// Küçük harf, Türkçe harfler ASCII, noktalama → boşluk.
String searchNormalize(String input) {
  var s = input.toLowerCase();
  // "İ".toLowerCase() → "i" + birleşik nokta (U+0307)
  s = s.replaceAll('̇', '');
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(_trFold[ch] ?? ch);
  }
  return buf.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _singular(String w) {
  final irregular = _irregularSingular[w];
  if (irregular != null) return irregular;
  if (w.length > 4 && w.endsWith('s') && !w.endsWith('ss')) {
    return w.substring(0, w.length - 1);
  }
  return w;
}

/// Aramanın kullandığı kelime dizisi: sadeleştir, böl, birleşikleri ayır,
/// tekil yap.
List<String> searchWords(String input) {
  final out = <String>[];
  for (final raw in searchNormalize(input).split(' ')) {
    if (raw.isEmpty) continue;
    final w = _singular(raw);
    final parts = _compounds[w];
    if (parts != null) {
      out.addAll(parts);
    } else {
      out.add(w);
    }
  }
  return out;
}

// ─────────────────────────────────────────────── Türkçe terim kuralları

class ExerciseTermRule {
  final List<String> en; // addaki ardışık kelimeler (searchWords biçiminde)
  final List<List<String>> tr; // her Türkçe karşılığın kelimeleri
  final Set<String>? muscles; // yalnız bu birincil kaslarda geçerli
  final bool weak; // niteleyici (oturarak, tek kol…) — zayıf eşleşme

  const ExerciseTermRule({
    required this.en,
    required this.tr,
    this.muscles,
    this.weak = false,
  });
}

class ExerciseTermData {
  final List<ExerciseTermRule> rules;
  final Set<String> staples; // "temel" hareket adları

  const ExerciseTermData({this.rules = const [], this.staples = const {}});

  static const empty = ExerciseTermData();

  factory ExerciseTermData.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rules = [
      for (final r in (data['rules'] as List).cast<Map<String, dynamic>>())
        ExerciseTermRule(
          en: searchWords(r['en'] as String),
          tr: [
            for (final t in (r['tr'] as List).cast<String>()) searchWords(t),
          ],
          muscles: (r['muscles'] as List?)?.cast<String>().toSet(),
          weak: r['weak'] == true,
        ),
    ];
    final staples = ((data['temel'] as List?) ?? const []).cast<String>();
    return ExerciseTermData(rules: rules, staples: staples.toSet());
  }
}

// ─────────────────────────────────────────────── Aranabilir hareket

/// Aramanın ihtiyaç duyduğu alanlar (drift `Exercise`'tan bağımsız — test
/// edilebilsin).
class SearchableExercise {
  final int id;
  final String name;
  final String category;
  final String? primaryMuscle;
  final String? equipment;
  final List<String> muscles;

  /// Küratörlü seed (salonda yaygın) hareket mi — çeşitler arasında öne çıkar.
  final bool isCurated;

  const SearchableExercise({
    required this.id,
    required this.name,
    required this.category,
    this.primaryMuscle,
    this.equipment,
    this.muscles = const [],
    this.isCurated = false,
  });
}

/// Puanlar — büyük olan önce. Aynı alanda tam kelime > kelime başı.
class _Score {
  static const nameExact = 30;
  static const namePrefix = 20;
  static const aliasExact = 26;
  static const aliasPrefix = 18;
  static const weakAliasExact = 10;
  static const weakAliasPrefix = 7;
  static const primaryExact = 12;
  // Kullanıcı bir kas adı yazdıysa ("omuz", "kol") niyet o kasın
  // hareketleridir: birincil kas eşleşmesi Türkçe ad eşleşmesini geçer, o
  // kelimenin Türkçe ad eşleşmesi ("omuz silkme", "tek kol") zayıf sayılır.
  static const primaryIntent = 18;
  static const primaryPrefix = 8;
  static const equipExact = 10;
  static const equipPrefix = 7;
  static const categoryExact = 6;
  static const categoryPrefix = 4;
  static const secondaryExact = 4;
  static const secondaryPrefix = 2;
  static const phrase = 25;
  static const staple = 6;
  static const curated = 8;
  static const recentUse = 10;
  static const maxUseBonus = 10;
  static const maxShortNameBonus = 5;
}

/// Kelime başı eşleşmesi için en kısa arama parçası (1 harf yalnız tam
/// kelimeyle eşleşir).
const _minPrefix = 2;

/// Birleşik yazım karşılaştırması için en kısa parça ("pushup" gibi).
const _minJoined = 4;

class _Entry {
  final SearchableExercise ex;
  final List<String> nameWords;
  final List<String> nameJoined; // ardışık 2-3 kelimenin bitişik hali
  final List<List<String>> aliases;
  final List<List<String>> weakAliases;
  final Set<String> primaryTerms;
  final Set<String> secondaryTerms;
  final Set<String> equipTerms;
  final Set<String> categoryTerms;
  final bool isStaple;

  _Entry({
    required this.ex,
    required this.nameWords,
    required this.nameJoined,
    required this.aliases,
    required this.weakAliases,
    required this.primaryTerms,
    required this.secondaryTerms,
    required this.equipTerms,
    required this.categoryTerms,
    required this.isStaple,
  });
}

/// Bir kez kurulur (katalog değişince yeniden), her tuşta [search] çalışır.
class ExerciseSearchIndex {
  final List<_Entry> _entries;

  /// Katalogdaki tüm kas terimleri — bir arama kelimesi kas adı mı?
  final Set<String> _muscleVocabulary;

  ExerciseSearchIndex._(this._entries)
    : _muscleVocabulary = {
        for (final e in _entries) ...e.primaryTerms,
        for (final e in _entries) ...e.secondaryTerms,
      };

  factory ExerciseSearchIndex(
    List<SearchableExercise> items,
    ExerciseTermData terms,
  ) => ExerciseSearchIndex._([for (final e in items) _build(e, terms)]);

  static _Entry _build(SearchableExercise e, ExerciseTermData terms) {
    final words = searchWords(e.name);
    final joined = <String>[
      for (var i = 0; i + 1 < words.length; i++) words[i] + words[i + 1],
      for (var i = 0; i + 2 < words.length; i++)
        words[i] + words[i + 1] + words[i + 2],
    ];
    final aliases = <List<String>>[];
    final weak = <List<String>>[];
    for (final rule in terms.rules) {
      if (rule.muscles != null && !rule.muscles!.contains(e.primaryMuscle)) {
        continue;
      }
      if (!_containsSequence(words, rule.en)) continue;
      (rule.weak ? weak : aliases).addAll(rule.tr);
    }

    Set<String> termsOf(
      String? key,
      List<String> Function(String) tr,
      String Function(String?) label,
    ) {
      if (key == null || key.isEmpty) return const {};
      return {
        ...searchWords(key),
        ...searchWords(label(key)),
        for (final t in tr(key)) ...searchWords(t),
      };
    }

    return _Entry(
      ex: e,
      nameWords: words,
      nameJoined: joined,
      aliases: aliases,
      weakAliases: weak,
      primaryTerms: termsOf(
        e.primaryMuscle,
        WorkoutUi.trMuscleTermsOf,
        WorkoutUi.muscleLabel,
      ),
      secondaryTerms: {
        for (final m in e.muscles)
          ...termsOf(m, WorkoutUi.trMuscleTermsOf, WorkoutUi.muscleLabel),
      },
      equipTerms: termsOf(
        e.equipment,
        WorkoutUi.trEquipTermsOf,
        WorkoutUi.equipmentLabel,
      ),
      categoryTerms: termsOf(
        e.category,
        WorkoutUi.trCategoryTermsOf,
        (k) => WorkoutUi.categoryLabel(k ?? ''),
      ),
      isStaple: terms.staples.contains(e.name),
    );
  }

  /// [query] ile eşleşen hareketlerin kimlikleri, en alakalıdan başlayarak.
  /// Boş sorgu → boş liste (çağıran tarafta gruplu liste gösterilir).
  ///
  /// [usage]: hareket kimliği → son dönemde yapılma sayısı; yapılanlar öne
  /// çıkar.
  List<int> search(String query, {Map<int, int> usage = const {}}) {
    final tokens = searchWords(query);
    if (tokens.isEmpty) return const [];
    final scored = <({int id, int score, String name})>[];
    for (final e in _entries) {
      final s = _scoreEntry(e, tokens, _muscleVocabulary);
      if (s == null) continue;
      final used = usage[e.ex.id] ?? 0;
      final bonus =
          (e.isStaple ? _Score.staple : 0) +
          (e.ex.isCurated ? _Score.curated : 0) +
          (used > 0
              ? _Score.recentUse +
                    (used > _Score.maxUseBonus ? _Score.maxUseBonus : used)
              : 0) +
          _shortNameBonus(e.nameWords.length);
      scored.add((id: e.ex.id, score: s + bonus, name: e.ex.name));
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.name.compareTo(b.name);
    });
    return [for (final r in scored) r.id];
  }

  static int _shortNameBonus(int words) {
    final b = _Score.maxShortNameBonus - words;
    return b < 0 ? 0 : b;
  }

  /// Her kelime bir alanda eşleşmeli (VE). Eşleşmeyen varsa `null`.
  static int? _scoreEntry(
    _Entry e,
    List<String> tokens,
    Set<String> muscleVocabulary,
  ) {
    var total = 0;
    for (final t in tokens) {
      var best = 0;
      int take(int v) => v > best ? best = v : best;
      final muscleIntent = muscleVocabulary.contains(t);

      final inName = _match(e.nameWords, t);
      if (inName == _Hit.exact) take(_Score.nameExact);
      if (inName == _Hit.prefix) take(_Score.namePrefix);
      if (inName == _Hit.none &&
          t.length >= _minJoined &&
          e.nameJoined.any((j) => j.startsWith(t))) {
        take(_Score.namePrefix);
      }
      for (final a in e.aliases) {
        final h = _match(a, t);
        if (h == _Hit.exact) {
          take(muscleIntent ? _Score.weakAliasExact : _Score.aliasExact);
        }
        if (h == _Hit.prefix) {
          take(muscleIntent ? _Score.weakAliasPrefix : _Score.aliasPrefix);
        }
      }
      for (final a in e.weakAliases) {
        final h = _match(a, t);
        if (h == _Hit.exact) take(_Score.weakAliasExact);
        if (h == _Hit.prefix) take(_Score.weakAliasPrefix);
      }
      _termScore(
        e.primaryTerms,
        t,
        muscleIntent ? _Score.primaryIntent : _Score.primaryExact,
        _Score.primaryPrefix,
        take,
      );
      _termScore(e.equipTerms, t, _Score.equipExact, _Score.equipPrefix, take);
      _termScore(
        e.categoryTerms,
        t,
        _Score.categoryExact,
        _Score.categoryPrefix,
        take,
      );
      _termScore(
        e.secondaryTerms,
        t,
        _Score.secondaryExact,
        _Score.secondaryPrefix,
        take,
      );

      if (best == 0) return null;
      total += best;
    }
    if (tokens.length > 1) {
      if (_containsSequence(e.nameWords, tokens, lastPrefix: true)) {
        total += _Score.phrase;
      } else if (e.aliases.any(
        (a) => _containsSequence(a, tokens, lastPrefix: true),
      )) {
        total += _Score.phrase;
      }
    }
    return total;
  }

  static void _termScore(
    Set<String> terms,
    String t,
    int exact,
    int prefix,
    int Function(int) take,
  ) {
    if (terms.contains(t)) {
      take(exact);
    } else if (t.length >= _minPrefix && terms.any((w) => w.startsWith(t))) {
      take(prefix);
    }
  }
}

enum _Hit { none, prefix, exact }

_Hit _match(List<String> words, String t) {
  var hit = _Hit.none;
  for (final w in words) {
    if (w == t) return _Hit.exact;
    if (t.length >= _minPrefix && w.startsWith(t)) hit = _Hit.prefix;
  }
  return hit;
}

/// [needle] kelimeleri [hay] içinde ardışık geçiyor mu. [lastPrefix]:
/// son kelime yarım yazılmış olabilir (kullanıcı hâlâ yazıyor).
bool _containsSequence(
  List<String> hay,
  List<String> needle, {
  bool lastPrefix = false,
}) {
  if (needle.isEmpty || needle.length > hay.length) return false;
  for (var i = 0; i + needle.length <= hay.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      final w = hay[i + j];
      final n = needle[j];
      final last = j == needle.length - 1;
      if (!(w == n || (lastPrefix && last && w.startsWith(n)))) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
