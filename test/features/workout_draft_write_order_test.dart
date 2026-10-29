import 'dart:async';

import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _ControlledPreferences prefs;

  WorkoutDraftService service() =>
      WorkoutDraftService(preferences: () async => prefs);

  WorkoutDraft draft(String title) => WorkoutDraft(
        title: title,
        routineId: 12,
        startedAtMs: 1000,
        sessionDateMs: 1000,
        exercises: [
          DraftExercise(
            exerciseId: 4,
            restSec: 60,
            previous: null,
            sets: [DraftSet(weight: 40, reps: 8)],
          ),
        ],
      );

  setUp(() => prefs = _ControlledPreferences());

  test('okuma başlayan yazı bitmeden bellek kopyasındaki adayı döndürmez',
      () async {
    final writer = service();
    await writer.save(draft('önceki'));
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final pending = writer.save(draft('aday'));
    await gate.started.future;
    var readDone = false;
    final read = service().load().then((value) {
      readDone = true;
      return value;
    });
    try {
      await Future<void>.delayed(Duration.zero);
      expect(readDone, isFalse);
      expect(prefs.diskDraft!.title, 'önceki');
    } finally {
      gate.release.complete();
    }
    await pending;
    expect((await read)!.title, 'aday');
  });

  for (final failure in [_Failure.reject, _Failure.throwError]) {
    test('${failure.name} bekleyen yazıdan sonraki okuma eski taslağı döndürür',
        () async {
      final writer = service();
      await writer.save(draft('önceki'));
      final gate = _WriteGate();
      prefs.nextWrite = gate;
      prefs.nextWriteFailure = failure;
      final pending = writer.save(draft('başarısız aday'));
      final rejected = expectLater(pending, throwsStateError);
      await gate.started.future;
      var readDone = false;
      final read = service().load().then((value) {
        readDone = true;
        return value;
      });
      try {
        await Future<void>.delayed(Duration.zero);
        expect(readDone, isFalse);
      } finally {
        gate.release.complete();
      }
      await rejected;
      expect((await read)!.title, 'önceki');
      expect(prefs.diskDraft!.title, 'önceki');
    });
  }

  test('bekleyen yazı ve clear arkasındaki okuma temizlenmiş sonucu bekler',
      () async {
    final writer = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final pending = writer.save(draft('eski hesap'));
    await gate.started.future;
    final clear = service().clear();
    var readDone = false;
    final read = service().load().then((value) {
      readDone = true;
      return value;
    });
    try {
      await Future<void>.delayed(Duration.zero);
      expect(readDone, isFalse);
    } finally {
      gate.release.complete();
    }
    await Future.wait([pending, clear]);
    expect(await read, isNull);
  });

  test('okuma tercihleri beklerken daha yeni yazı araya giremez', () async {
    await service().save(draft('önceki'));
    final loading = Completer<SharedPreferences>();
    final started = Completer<void>();
    final reader = WorkoutDraftService(preferences: () {
      started.complete();
      return loading.future;
    });
    final read = reader.load();
    await started.future;
    final write = service().save(draft('sonraki'));
    try {
      await Future<void>.delayed(Duration.zero);
      expect(prefs.events, ['write:önceki']);
    } finally {
      loading.complete(prefs);
    }
    expect((await read)!.title, 'önceki');
    await write;
    expect(prefs.diskDraft!.title, 'sonraki');
  });

  test('iki servis yazmayı sırayla bitirir, son çağrı diskte kalır', () async {
    final first = service();
    final second = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final a = first.save(draft('ilk'));
    await gate.started.future;
    final b = second.save(draft('son'));
    await Future<void>.delayed(Duration.zero);
    expect(prefs.events, ['write:ilk']);

    gate.release.complete();
    await Future.wait([a, b]);
    expect(prefs.events, ['write:ilk', 'write:son']);
    expect(prefs.diskDraft!.title, 'son');
    expect((await first.load())!.title, 'son');
  });

  test('sırada beklerken mutable set değişirse çağrı anı korunur', () async {
    final writer = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final first = writer.save(draft('önce'));
    await gate.started.future;
    final snapshot = draft('bekleyen');
    final pending = writer.save(snapshot);
    snapshot.exercises.single.sets.single.weight = 999;

    gate.release.complete();
    await Future.wait([first, pending]);
    expect(prefs.diskDraft!.exercises.single.sets.single.weight, 40);
  });

  test('başlamış yazma sırasında clear eski kuyrukları ve yazıyı kaldırır',
      () async {
    final writer = service();
    final cleaner = service();
    final generation = writer.clearCount;
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final running = writer.saveIfCurrent(
      draft('başlamış'),
      expectedClearCount: generation,
    );
    await gate.started.future;
    final queued = writer.save(draft('eski normal'));
    final guarded = service().saveIfCurrent(
      draft('eski korumalı'),
      expectedClearCount: generation,
    );
    final clear = cleaner.clear();
    expect(writer.clearCount, generation + 1,
        reason: 'silme platform yazısını beklemeden nesli değiştirir');
    await Future<void>.delayed(Duration.zero);
    expect(prefs.events, ['write:başlamış']);

    gate.release.complete();
    expect(await running, isFalse);
    expect(await guarded, isFalse);
    await Future.wait([queued, clear]);
    expect(prefs.events.where((e) => e.startsWith('write:')),
        ['write:başlamış']);
    expect(prefs.diskDraft, isNull);
    expect(await writer.load(), isNull);
  });

  test('clear sonrası yeni nesil yazısı temizliğin ardından korunur', () async {
    final writer = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    final old = writer.save(draft('eski'));
    await gate.started.future;
    final clear = service().clear();
    final fresh = service().save(draft('yeni'));

    gate.release.complete();
    await Future.wait([old, clear, fresh]);
    expect(prefs.diskDraft!.title, 'yeni');
    expect(prefs.events.last, 'write:yeni');
  });

  test('eski nesil yazısı hiçbir platform yazması yapmaz', () async {
    final writer = service();
    final generation = writer.clearCount;
    await service().clear();
    prefs.events.clear();
    expect(
      await writer.saveIfCurrent(draft('bayat'),
          expectedClearCount: generation),
      isFalse,
    );
    expect(prefs.events, isEmpty);
    expect(prefs.diskDraft, isNull);
  });

  test('tercih yüklenirken değişen sahiplik yazmayı engeller', () async {
    final loading = Completer<SharedPreferences>();
    final started = Completer<void>();
    final writer = WorkoutDraftService(preferences: () {
      started.complete();
      return loading.future;
    });
    var current = true;
    final pending = writer.saveIfCurrent(
      draft('eski hesap'),
      expectedClearCount: writer.clearCount,
      isCurrent: () => current,
    );
    await started.future;
    current = false;
    loading.complete(prefs);
    expect(await pending, isFalse);
    expect(prefs.events, isEmpty);
  });

  test('yazarken değişen sahiplik yalnız eski yazıyı kuyruk içinde temizler',
      () async {
    final writer = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    var current = true;
    final old = writer.saveIfCurrent(
      draft('eski hesap'),
      expectedClearCount: writer.clearCount,
      isCurrent: () => current,
    );
    await gate.started.future;
    current = false;
    final fresh = service().save(draft('yeni hesap'));
    gate.release.complete();

    expect(await old, isFalse);
    await fresh;
    expect(prefs.events, ['write:eski hesap', 'remove', 'write:yeni hesap']);
    expect(prefs.diskDraft!.title, 'yeni hesap');
  });

  for (final failure in [_Failure.reject, _Failure.throwError]) {
    test('${failure.name} yazma hatası taslağı korur, sonraki yazı çalışır',
        () async {
      final writer = service();
      await writer.save(draft('kayıtlı'));
      prefs.nextWriteFailure = failure;
      await expectLater(
        writer.saveIfCurrent(draft('başarısız'),
            expectedClearCount: writer.clearCount),
        throwsStateError,
      );
      expect(prefs.diskDraft!.title, 'kayıtlı');
      expect((await writer.load())!.title, 'kayıtlı',
          reason: 'SharedPreferences bellek kopyası da yeniden okunur');

      await service().save(draft('yeniden deneme'));
      expect(prefs.diskDraft!.title, 'yeniden deneme');
    });
  }

  test('bayat yazı temizlenemezse false başarı yerine hata döner', () async {
    final writer = service();
    final gate = _WriteGate();
    prefs.nextWrite = gate;
    prefs.nextRemoveFailure = _Failure.reject;
    var current = true;
    final old = writer.saveIfCurrent(
      draft('eski hesap'),
      expectedClearCount: writer.clearCount,
      isCurrent: () => current,
    );
    final rejected = expectLater(old, throwsStateError);
    await gate.started.future;
    current = false;
    gate.release.complete();
    await rejected;
    // Temizleme hatası gizlenmez; sonraki açık temizleme kuyruğu kurtarır.
    expect(prefs.diskDraft!.title, 'eski hesap');
    await service().clear();
    expect(prefs.diskDraft, isNull);
  });

  test('normal save de false platform sonucunu hata olarak bildirir', () async {
    prefs.nextWriteFailure = _Failure.reject;
    await expectLater(service().save(draft('başarısız')), throwsStateError);
    await service().save(draft('başarılı'));
    expect(prefs.diskDraft!.title, 'başarılı');
  });
}

enum _Failure { reject, throwError }

class _WriteGate {
  final started = Completer<void>();
  final release = Completer<void>();
}

/// SharedPreferences'in platform yazısından önce değişen bellek kopyasını
/// da modeller; tamamlanmamış bir yazı diske erken uygulanmaz.
class _ControlledPreferences extends Fake implements SharedPreferences {
  final _stored = <String, String>{};
  final _cache = <String, String>{};
  final events = <String>[];
  _WriteGate? nextWrite;
  _Failure? nextWriteFailure;
  _Failure? nextRemoveFailure;

  WorkoutDraft? get diskDraft => _stored.values.isEmpty
      ? null
      : WorkoutDraft.decode(_stored.values.single);

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<bool> setString(String key, String value) async {
    final gate = nextWrite;
    final failure = nextWriteFailure;
    nextWrite = null;
    nextWriteFailure = null;
    _cache[key] = value;
    events.add('write:${WorkoutDraft.decode(value)!.title}');
    if (gate != null) {
      gate.started.complete();
      await gate.release.future;
    }
    if (failure == _Failure.throwError) throw StateError('platform write');
    if (failure == _Failure.reject) return false;
    _stored[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final failure = nextRemoveFailure;
    nextRemoveFailure = null;
    events.add('remove');
    _cache.remove(key);
    if (failure == _Failure.throwError) throw StateError('platform remove');
    if (failure == _Failure.reject) return false;
    _stored.remove(key);
    return true;
  }

  @override
  Future<void> reload() async {
    _cache
      ..clear()
      ..addAll(_stored);
  }
}
