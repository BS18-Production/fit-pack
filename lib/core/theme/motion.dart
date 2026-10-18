import 'package:flutter/widgets.dart';

/// Sistem "hareketi azalt" tercihine uyan animasyon süresi (deneyim
/// araştırması A6 §1.5): tercih açıksa geçiş anında olur.
Duration motionDuration(BuildContext context, Duration d) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : d;

/// Tercih açık mı — sürekli dönen animasyonlar durdurulur.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
