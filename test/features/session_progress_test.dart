import 'package:fit_pack/features/workout/session_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// C-16 — aktif seansta "0/6 set" ilerleme göstergesi.
void main() {
  test('hareketler arası toplam ve tamamlanan setler sayılır', () {
    final p = SessionProgress.of([
      [true, false, false],
      [true, true, false],
    ]);
    expect(p.done, 3);
    expect(p.total, 6);
    expect(p.fraction, 0.5);
    expect(p.isComplete, isFalse);
  });

  test('boş seans: toplam 0, oran 0, gösterilmez', () {
    final p = SessionProgress.of(const []);
    expect(p.isEmpty, isTrue);
    expect(p.fraction, 0);
    expect(p.isComplete, isFalse);
  });

  test('setsiz hareket toplamı değiştirmez', () {
    final p = SessionProgress.of([
      const <bool>[],
      [false],
    ]);
    expect(p.total, 1);
    expect(p.done, 0);
  });

  test('hepsi tamamsa bitti sayılır', () {
    final p = SessionProgress.of([
      [true, true],
      [true],
    ]);
    expect(p.isComplete, isTrue);
    expect(p.fraction, 1);
  });
}
