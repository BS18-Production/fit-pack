/// Karb/yağ hedefleri kalori + protein hedefinden türetilir — kullanıcıya
/// ekstra ayar sormadan üç makro da hedefli görünür.
///
/// Dağılım: yağ = kalorinin ~%27,5'i (hormonal sağlık için 0,8 g/kg üstü
/// kalır), karb = kalan kalori. 1 g protein/karb = 4 kcal, 1 g yağ = 9 kcal.
({int carb, int fat}) deriveMacroGoals({
  required int kcalGoal,
  required int proteinGoal,
}) {
  final fat = (kcalGoal * 0.275 / 9).round();
  final carbKcal = kcalGoal - proteinGoal * 4 - fat * 9;
  final carb = carbKcal > 0 ? (carbKcal / 4).round() : 0;
  return (carb: carb, fat: fat);
}
