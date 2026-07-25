import 'package:fit_pack/shared/widgets/exercise_demo.dart';
import 'package:flutter_test/flutter_test.dart';

/// İki kareli form gösterimi (içerik zenginleştirme turu, 2026-07-25).
///
/// free-exercise-db her harekette `0.jpg` (başlangıç) + `1.jpg` (bitiş) tutar.
/// Kare adresi yanlış üretilirse animasyon SESSİZCE ölür — kullanıcı tek kare
/// görür ve kimse fark etmez. Bu yüzden üretim saf fonksiyon + testli.
void main() {
  group('ExerciseDemoImage.frameUrl', () {
    test('başlangıç ve bitiş karesi aynı klasörden üretilir', () {
      const path = 'assets/exercise_img/Barbell_Squat/0.jpg';
      expect(
        ExerciseDemoImage.frameUrl(path, 0),
        'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat/0.jpg',
      );
      expect(
        ExerciseDemoImage.frameUrl(path, 1),
        'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat/1.jpg',
      );
    });

    test('kaynakta hangi kare yazılıysa yazılsın bitiş karesi doğru üretilir',
        () {
      // Seed `1.jpg` ile gelirse de bitiş karesi yine 1, başlangıç yine 0
      // olmalı — dosya adı değil, klasör belirleyici.
      const path = 'assets/exercise_img/3_4_Sit-Up/1.jpg';
      expect(ExerciseDemoImage.frameUrl(path, 0)?.endsWith('3_4_Sit-Up/0.jpg'),
          isTrue);
      expect(ExerciseDemoImage.frameUrl(path, 1)?.endsWith('3_4_Sit-Up/1.jpg'),
          isTrue);
    });

    test('boşluklu/özel karakterli klasör adı korunur', () {
      const path = 'assets/exercise_img/Kneeling_Cable_Triceps_Extension/0.jpg';
      expect(
        ExerciseDemoImage.frameUrl(path, 1),
        endsWith('/Kneeling_Cable_Triceps_Extension/1.jpg'),
      );
    });

    test('kullanıcının özel hareketinde görsel yok → null', () {
      // isCustom hareketlerde imagePath boştur; widget hiç çizilmemeli.
      expect(ExerciseDemoImage.frameUrl(null, 0), isNull);
      expect(ExerciseDemoImage.frameUrl('', 0), isNull);
    });

    test('beklenmeyen önek → null (yanlış CDN adresi üretme)', () {
      expect(ExerciseDemoImage.frameUrl('https://başka/yer/0.jpg', 0), isNull);
      expect(ExerciseDemoImage.frameUrl('assets/images/foo.png', 0), isNull);
    });

    test('klasörsüz yol → null', () {
      expect(ExerciseDemoImage.frameUrl('assets/exercise_img/0.jpg', 0), isNull);
    });
  });
}
