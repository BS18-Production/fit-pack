import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Takvim günü bir veri bağımlılığıdır** (CR-010).
///
/// "Bugün", "bu hafta", "son 30 gün" hesaplayan provider'lar tablo değişimini
/// izler ama gece yarısını bilmez. Eskiden gün bekçisi bunları elle
/// invalidate ediyordu; liste elle büyüdüğü için bazıları unutulmuştu
/// (son 30 gün, kayıt haftası, rekor, her zamanki öğün). Artık güne bağlı her
/// provider [currentDayProvider]'ı `ref.watch` eder: gün ilerleyince
/// kendiliğinden yeniden kurulur. Yeni bir güne bağlı provider da aynısını
/// yapmalı.
///
/// Değeri yalnız gün bekçisi (`app.dart`) ilerletir: ön planda gece yarısı
/// zamanlayıcısıyla ([MidnightTimer]) ve uygulama öne her geldiğinde.
final currentDayProvider = StateProvider<DateTime>(
  (ref) => dayStart(DateTime.now()),
);

/// Yerel 00:00.
DateTime dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

/// [t]'nin gününden [n] takvim günü sonrasının 00:00'ı. `Duration(days: n)`
/// DEĞİL: yaz saati gününde 24 saat sonrası gece yarısı olmaz (CR-011).
DateTime addDays(DateTime t, int n) => DateTime(t.year, t.month, t.day + n);

/// Ön planda gece yarısını yakalar: bir sonraki yerel gece yarısına (+1 sn
/// pay) zamanlayıcı kurar, tetiklenince [onMidnight]'ı çağırıp yeniden kurar.
/// Arka planda işletim sistemi zamanlayıcıyı bekletebilir; öne gelişte
/// [arm] yeniden çağrılır.
class MidnightTimer {
  final DateTime Function() now;
  final void Function() onMidnight;
  Timer? _timer;

  MidnightTimer({required this.onMidnight, this.now = DateTime.now});

  void arm() {
    _timer?.cancel();
    final t = now();
    final wait = addDays(t, 1).difference(t) + const Duration(seconds: 1);
    _timer = Timer(wait, () {
      onMidnight();
      arm();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
