package com.sametorhan.fit_pack

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: Health Connect izin penceresi (health paketi)
// ActivityResult API ister; FlutterActivity ile açılmaz (docs/39).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Dinlenme sayacı servisi (docs/25) — Dart: core/feedback/rest_alarm.dart
        MethodChannel(messenger, "fit_pack/rest_timer")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            RestTimerService.start(
                                this,
                                deadlineMs = call.argument<Number>("deadlineMs")!!.toLong(),
                                sound = call.argument<Boolean>("sound") ?: true,
                                soundAsset = call.argument<String>("soundAsset") ?: "",
                                title = call.argument<String>("title") ?: "",
                                doneTitle = call.argument<String>("doneTitle") ?: "",
                                doneBody = call.argument<String>("doneBody") ?: "",
                            )
                            result.success(true)
                        }
                        "stop" -> {
                            RestTimerService.stop(this)
                            result.success(null)
                        }
                        "dismissDone" -> {
                            RestTimerService.dismissDone(this)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    // Ör. arka plandan başlatma yasağı: Dart yedek yola düşer.
                    result.error("rest_timer", e.message, null)
                }
            }
        // Seans kilit ekranı bildirimi (docs/45) — Dart:
        // core/live_activity/workout_live_activity.dart (iOS ile aynı kanal).
        val live = MethodChannel(messenger, "fit_pack/live_activity")
        live.setMethodCallHandler { call, result ->
            when (call.method) {
                "start", "update" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) WorkoutNotification.show(this, WorkoutNotification.fromArgs(args))
                    result.success(true)
                }
                "end" -> {
                    WorkoutNotification.end(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        WorkoutNotification.channel = live
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WorkoutNotification.channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
