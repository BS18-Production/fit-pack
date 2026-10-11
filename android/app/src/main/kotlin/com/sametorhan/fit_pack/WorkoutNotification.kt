package com.sametorhan.fit_pack

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Seans boyu kilit ekranı bildirimi (docs/45 §2) — iOS Canlı Etkinlik'in
 * Android karşılığı. Dart `fit_pack/live_activity` kanalından durumu gönderir
 * (`core/live_activity/workout_live_activity.dart`).
 *
 * **Tek bildirim.** Kimlik dinlenme servisinin ön plan bildirimiyle AYNI
 * ([RestTimerService.ID_LIVE]): dinlenme sürerken servis bu bildirimi
 * sahiplenir, bitince geri bırakır. Kilit ekranında iki kart çıkmaz.
 *
 * **Eylemler** kilit açılmadan çalışır (yayın → [LiveActionReceiver]) ve
 * Dart'taki açık seansa iletilir; seans durumunun tek sahibi orası.
 */
object WorkoutNotification {
    /**
     * Önem VARSAYILAN, ses/titreşim yok. DÜŞÜK önemli ("sessiz") bildirim
     * Android'in varsayılan ayarında kilit ekranında GİZLENİR (emülatörde
     * görüldü, 2026-10-11) — kart kilit ekranında görünmeli. Kanal önemi
     * sonradan değiştirilemediği için yeni kimlik; ilk sürümün kanalı silinir.
     */
    const val CHANNEL = "workout_session"
    private const val OLD_CHANNEL = "workout_live"
    const val ACTION_PREFIX = "fit_pack.live."

    data class Labels(
        val rest: String,
        val restOver: String,
        val next: String,
        val completeSet: String,
        val addRest: String,
        val skipRest: String,
        val elapsed: String,
    )

    data class State(
        val title: String,
        val startedAtMs: Long,
        val exercise: String,
        val setLabel: String,
        val target: String,
        val restEndsAtMs: Long?,
        val doneSets: Int,
        val totalSets: Int,
        val canComplete: Boolean,
        val labels: Labels,
        /** Dinlenme Dart uyurken bitti (servis bildirdi) — "Dinlenme bitti". */
        val restOver: Boolean = false,
    )

    @Volatile
    var state: State? = null
        private set

    /** Açık Flutter motorunun kanalı; motor yoksa null. */
    @Volatile
    var channel: MethodChannel? = null

    fun show(context: Context, next: State) {
        state = next
        post(context)
    }

    fun end(context: Context) {
        state = null
        // Servis ön plandaysa bildirimi o kaldırır (kapanınca).
        if (!RestTimerService.isRunning) nm(context)?.cancel(RestTimerService.ID_LIVE)
    }

    /** Servis dinlenme bitişini gördü (Dart arka planda uyuyor olabilir). */
    fun restEnded(context: Context) {
        val s = state ?: return
        state = s.copy(restEndsAtMs = null, restOver = true)
        post(context)
    }

    fun post(context: Context) {
        val n = build(context) ?: return
        nm(context)?.notify(RestTimerService.ID_LIVE, n)
    }

    /** Geçerli durumun bildirimi; seans yoksa null. */
    fun build(context: Context): Notification? {
        val s = state ?: return null
        ensureChannel(context)
        val now = System.currentTimeMillis()
        val restEnds = s.restEndsAtMs?.takeIf { it > now }
        val l = s.labels
        val nextLine = if (s.target.isEmpty()) s.setLabel else "${s.setLabel} · ${s.target}"
        val b = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_workout)
            .setColor(LIME)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .setContentIntent(openAppIntent(context))
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setUsesChronometer(true)
            .setShowWhen(true)

        if (restEnds != null) {
            // Dinlenme: başlık geri sayar (sistem çizer), sıradaki set altta.
            b.setContentTitle(l.rest)
                .setContentText("${l.next}: ${s.exercise} · $nextLine")
                .setSubText(s.title)
                .setWhen(restEnds)
                .setChronometerCountDown(true)
                .addAction(0, l.addRest, actionIntent(context, "addRest"))
                .addAction(0, l.skipRest, actionIntent(context, "skipRest"))
        } else {
            // Set: hareket + hedef; kronometre toplam antrenman süresi.
            b.setContentTitle(if (s.restOver) "${l.restOver} · ${s.exercise}" else s.exercise)
                .setContentText(nextLine)
                .setSubText(if (l.elapsed.isEmpty()) s.title else "${s.title} · ${l.elapsed}")
                .setWhen(s.startedAtMs)
                .setChronometerCountDown(false)
            if (s.totalSets > 0) b.setProgress(s.totalSets, s.doneSets, false)
            if (s.canComplete) {
                b.addAction(0, l.completeSet, actionIntent(context, "completeSet"))
            }
        }
        return b.build()
    }

    /**
     * Eylemi Dart'a iletir. Motor yoksa (uygulama süreci yeniden başladı)
     * bildirim bayattır: kaldırılır — seans açılınca taslaktan yeniden kurulur.
     */
    fun dispatch(context: Context, action: String, done: () -> Unit) {
        val ch = channel
        if (ch == null || state == null) {
            nm(context)?.cancel(RestTimerService.ID_LIVE)
            done()
            return
        }
        val main = Handler(Looper.getMainLooper())
        var finished = false
        val finish = {
            if (!finished) {
                finished = true
                done()
            }
        }
        main.post {
            ch.invokeMethod("action", action, object : MethodChannel.Result {
                override fun success(result: Any?) = finish()
                override fun error(code: String, msg: String?, details: Any?) = finish()
                override fun notImplemented() = finish()
            })
        }
        // Dart cevap vermezse alıcı süresiz beklemesin.
        main.postDelayed(finish, 8000)
    }

    private fun actionIntent(context: Context, action: String): PendingIntent {
        val i = Intent(context, LiveActionReceiver::class.java).setAction(ACTION_PREFIX + action)
        return PendingIntent.getBroadcast(
            context, action.hashCode(), i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = nm(context) ?: return
        nm.deleteNotificationChannel(OLD_CHANNEL)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, "Workout in progress",
                NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Current set and rest timer on the lock screen"
                setShowBadge(false)
                setSound(null, null) // ses dinlenme servisinden gelir
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
        )
    }

    private fun nm(context: Context) = context.getSystemService(NotificationManager::class.java)

    /** FitPack neon lime. */
    private const val LIME = 0xFFCCFF00.toInt()

    /** Dart'tan gelen kanal argümanlarını duruma çevirir. */
    fun fromArgs(a: Map<*, *>): State {
        val l = a["labels"] as? Map<*, *> ?: emptyMap<Any, Any>()
        fun str(m: Map<*, *>, k: String) = m[k] as? String ?: ""
        return State(
            title = str(a, "title"),
            startedAtMs = (a["startedAtMs"] as? Number)?.toLong() ?: System.currentTimeMillis(),
            exercise = str(a, "exercise"),
            setLabel = str(a, "setLabel"),
            target = str(a, "target"),
            restEndsAtMs = (a["restEndsAtMs"] as? Number)?.toLong(),
            doneSets = (a["doneSets"] as? Number)?.toInt() ?: 0,
            totalSets = (a["totalSets"] as? Number)?.toInt() ?: 0,
            canComplete = a["canComplete"] as? Boolean ?: false,
            labels = Labels(
                rest = str(l, "rest"),
                restOver = str(l, "restOver"),
                next = str(l, "next"),
                completeSet = str(l, "completeSet"),
                addRest = str(l, "addRest"),
                skipRest = str(l, "skipRest"),
                elapsed = str(l, "elapsed"),
            ),
        )
    }
}

/** Kilit ekranı bildirim eylemleri — kilit açılmadan, uygulama arka planda. */
class LiveActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action?.removePrefix(WorkoutNotification.ACTION_PREFIX) ?: return
        val pending = goAsync()
        WorkoutNotification.dispatch(context.applicationContext, action) { pending.finish() }
    }
}
