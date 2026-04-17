class AppConstants {
  AppConstants._();

  static const String appName = 'Fit Pack';
  static const String appVersion = '1.0.0';

  // Rest Timer defaults (seconds)
  static const int compoundRestSeconds = 90;
  static const int isolationRestSeconds = 60;

  // Streak
  static const int streakBronze = 10;
  static const int streakSilver = 25;
  static const int streakGold = 50;
  static const int streakDiamond = 100;

  // Deload
  static const int deloadWeekThreshold = 5;

  // Posture volume target (sets per week)
  static const int postureVolumeTarget = 6;

  // Progressive overload
  static const double weightIncrementKg = 2.5;

  // Phases
  static const int phase1Weeks = 4;
  static const int phase2Weeks = 4;
}
