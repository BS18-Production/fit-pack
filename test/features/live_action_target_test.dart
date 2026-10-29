import 'package:fit_pack/features/workout/live_action_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aynı set/değer görüntüsü aynı anahtarı korur', () {
    final target = LiveActionTarget();
    final set = Object();
    expect(target.keyFor((set, 60, 10)), target.keyFor((set, 60, 10)));
  });

  test('yinelenen hareketin farklı set nesneleri çakışmaz', () {
    final target = LiveActionTarget();
    final first = target.keyFor((Object(), 60, 10));
    expect(target.keyFor((Object(), 60, 10)), isNot(first));
  });

  test('değiştirip geri alma ve yeniden açılış eski komutu canlandırmaz', () {
    final set = Object();
    final target = LiveActionTarget();
    final original = target.keyFor((set, 60, 10));
    target.keyFor((set, 65, 10));
    expect(target.keyFor((set, 60, 10)), isNot(original));
    expect(LiveActionTarget().keyFor((set, 60, 10)), isNot(original));
  });

  test('set ve mola yaşam döngüleri bağımsızdır', () {
    final setTarget = LiveActionTarget();
    final restTarget = LiveActionTarget();
    final set = Object();
    final setKey = setTarget.keyFor((set, 60, 10));
    final restKey = restTarget.keyFor(1000);
    expect(restTarget.keyFor(15000), isNot(restKey));
    restTarget.clear();
    expect(setTarget.keyFor((set, 60, 10)), setKey);
    expect(restTarget.keyFor(1000), isNot(restKey));
  });
}
