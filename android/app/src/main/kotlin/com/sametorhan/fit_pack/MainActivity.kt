package com.sametorhan.fit_pack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Dinlenme sayacı servisi (docs/25) — Dart: core/feedback/rest_alarm.dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fit_pack/rest_timer")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            RestTimerService.start(
                                this,
                                deadlineMs = call.argument<Number>("deadlineMs")!!.toLong(),
                                sound = call.argument<Boolean>("sound") ?: true,
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
    }
}
