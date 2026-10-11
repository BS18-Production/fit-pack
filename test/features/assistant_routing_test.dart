import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/features/assistant/assistant_contract.dart';
import 'package:fit_pack/features/assistant/assistant_routing.dart';

void main() {
  final frozen =
      jsonDecode(
            File('assets/data/assistant_router_v2.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final router = FrozenAssistantRouter(frozen);
  final fixture =
      jsonDecode(
            File('test/fixtures/assistant_routing_v2.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  test('istemci ve sunucu aynı dondurulmuş istem/şema', () {
    expect(
      File(
        'supabase/functions/ask-route/frozen_router.json',
      ).readAsStringSync(),
      File('assets/data/assistant_router_v2.json').readAsStringSync(),
    );
    expect(fixture['fingerprint'], assistantFingerprint);
    expect(fixture['cases'], hasLength(120));
  });
  for (final row in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test('Python karar eşliği ${row['id']}', () {
      final q = row['question'] as String;
      expect(assistantPrefilter(q), row['blocked']);
      if (row['blocked'] == true) {
        expect(row['expected'], 'fallback');
        return;
      }
      final route = AssistantRoute.fromJson(
        row['route'] as Map<String, dynamic>,
        router.exerciseIds,
      );
      expect(router.decide(route, q).name, row['expected']);
    });
  }
  test(
    'ek alan / yanlış tür / sınırsız alternatif / yabancı hareket reddi',
    () {
      final valid =
          (fixture['cases'] as List).first['route'] as Map<String, dynamic>;
      for (final bad in [
        {...valid, 'text': 'hello'},
        {...valid, 'advice': 'false'},
        {...valid, 'exercise': 'private_id'},
        {
          ...valid,
          'alternatives': ['weight_trend', 'streak', 'protein_goal'],
        },
        {...valid, 'period': 'last_year'},
        {...valid, 'query': 'delete'},
      ]) {
        expect(
          () => AssistantRoute.fromJson(bad, router.exerciseIds),
          throwsA(anything),
        );
      }
    },
  );
  test('ek gizlilik koruması ve yerel özel hareket ağırlığı', () {
    for (final s in [
      'mailim fitpack@example.org',
      'telefonum +90 555 000 00 00',
      '82 kg oldum',
      'diyabetim var',
      'teşhis sonucumu yorumla',
    ]) {
      expect(assistantSensitiveInput(s), isTrue, reason: s);
    }
    expect(
      assistantSensitiveInput('son 30 gün antrenmanlarım nasıldı'),
      isFalse,
    );
    final route = AssistantRoute(
      query: AssistantQuery.weightTrend,
      period: 'this_week',
      exercise: 'none',
      multiIntent: false,
      advice: false,
      interpretation: false,
      ambiguous: false,
      alternatives: const [],
    );
    expect(
      router.decide(
        route,
        'Kendi presimde ağırlığım arttı mı',
        localNames: ['Kendi pres'],
      ),
      RoutingDecision.fallback,
    );
  });
}
