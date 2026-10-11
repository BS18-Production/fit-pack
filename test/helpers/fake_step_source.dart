import 'dart:async';

import 'package:fit_pack/features/health/step_source.dart';

/// Platform kanalı kullanmadan gerçek adım provider'larını çalıştırır.
class FakeStepSource implements StepSource {
  StepPlatformStatus status;
  bool? access;
  bool requestResult = true;
  bool failInstall = false;
  bool failRead = false;
  Completer<bool>? requestCompletion;
  int requests = 0;
  int installs = 0;
  final reads = <({DateTime start, DateTime end})>[];
  int? Function(DateTime start) steps = (_) => 5000;

  FakeStepSource({this.status = StepPlatformStatus.available, this.access});

  @override
  Future<StepPlatformStatus> platformStatus() async => status;

  @override
  Future<bool> requestAccess() async {
    requests++;
    return requestCompletion == null
        ? requestResult
        : await requestCompletion!.future;
  }

  @override
  Future<bool?> hasAccess() async => access;

  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async {
    reads.add((start: start, end: end));
    if (failRead) throw StateError('read failed');
    return steps(start);
  }

  @override
  Future<void> openInstall() async {
    installs++;
    if (failInstall) throw StateError('install failed');
  }
}
