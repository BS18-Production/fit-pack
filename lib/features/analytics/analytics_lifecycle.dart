import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud/auth_service.dart';
import 'analytics_controller.dart';
import 'analytics_events.dart';
import 'analytics_providers.dart';

/// Mevcut oturum ve uygulama yaşam döngüsünü izler; iş verisi okumaz.
class AnalyticsLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  const AnalyticsLifecycle({super.key, required this.child});

  @override
  ConsumerState<AnalyticsLifecycle> createState() => _AnalyticsLifecycleState();
}

class _AnalyticsLifecycleState extends ConsumerState<AnalyticsLifecycle>
    with WidgetsBindingObserver {
  late final AnalyticsController _analytics = ref.read(
    analyticsControllerProvider,
  );
  ProviderSubscription<dynamic>? _account;
  String? _owner;
  int _epoch = 0;
  bool _started = false;
  bool _foreground = true;
  void Function(FlutterErrorDetails)? _previousFlutterError;
  bool Function(Object, StackTrace)? _previousPlatformError;
  late final void Function(FlutterErrorDetails) _flutterError;
  late final bool Function(Object, StackTrace) _platformError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _account = ref.listenManual(currentUserProvider, (_, user) {
      scheduleMicrotask(() {
        if (mounted) unawaited(_bind(user?.id));
      });
    }, fireImmediately: true);
    _previousFlutterError = FlutterError.onError;
    _previousPlatformError = PlatformDispatcher.instance.onError;
    _flutterError = (details) {
      unawaited(
        _analytics.trackOwned(_owner, AnalyticsEventName.appError, const {
          'code': 'ui',
          'screen': 'app',
        }),
      );
      _previousFlutterError?.call(details);
    };
    _platformError = (error, stack) {
      unawaited(
        _analytics.trackOwned(_owner, AnalyticsEventName.appError, const {
          'code': 'unknown',
          'screen': 'app',
        }),
      );
      return _previousPlatformError?.call(error, stack) ?? false;
    };
    FlutterError.onError = _flutterError;
    PlatformDispatcher.instance.onError = _platformError;
  }

  Future<void> _bind(String? owner) async {
    if (_started && owner == _owner) return;
    final coldStart = !_started;
    _started = true;
    _owner = owner;
    final epoch = ++_epoch;
    await _analytics.setAccount(owner);
    if (!mounted || epoch != _epoch || !_foreground) return;
    await _analytics.onForeground(coldStart: coldStart);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_foreground) {
      _foreground = true;
      unawaited(_analytics.onForeground());
    } else if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) &&
        _foreground) {
      _foreground = false;
      unawaited(_analytics.onBackground());
    }
  }

  @override
  void dispose() {
    _epoch++;
    _account?.close();
    WidgetsBinding.instance.removeObserver(this);
    if (identical(FlutterError.onError, _flutterError)) {
      FlutterError.onError = _previousFlutterError;
    }
    if (identical(PlatformDispatcher.instance.onError, _platformError)) {
      PlatformDispatcher.instance.onError = _previousPlatformError;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
