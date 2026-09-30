package com.sametorhan.fit_pack

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

/**
 * Dinlenme sayacı — ön plan servisi (docs/25).
 *
 * **Neden var.** Geri sayım sesi Dart zamanlayıcısıyla çalınıyordu. Uygulama
 * alta alınınca Samsung gibi üreticilerin arka plan dondurucusu (Freecess)
 * süreci birkaç saniyede donduruyor → son 3 saniyenin sesi hiç çalmıyordu.
 * Ön plan servisi süreci canlı tutar; kısmi uyanıklık kilidi (partial wake
 * lock) ekran kapalıyken de zamanlamayı korur.
 *
 * **Ne yapar.** Dinlenme boyunca bildirimde canlı geri sayım gösterir;
 * bitişten 3 sn önce tek parça geri sayım sesini (`rest_countdown.wav`: 3 tık
 * + bitiş) çalar, bitişte titreştirir ve "dinlenme bitti" bildirimi bırakır.
 * Ses ve titreşim yalnız buradan gelir (Android'de Dart çalmaz) — iki kaynak
 * olursa bipler üst üste biner.
 */
class RestTimerService : Service() {

    companion object {
        const val ACTION_START = "fit_pack.rest.START"
        const val ACTION_STOP = "fit_pack.rest.STOP"
        const val EXTRA_DEADLINE = "deadline"
        const val EXTRA_SOUND = "sound"
        const val EXTRA_TITLE = "title"
        const val EXTRA_DONE_TITLE = "doneTitle"
        const val EXTRA_DONE_BODY = "doneBody"

        private const val CHANNEL_LIVE = "rest_timer_live"
        private const val CHANNEL_DONE = "rest_timer_done"
        private const val ID_LIVE = 7101
        // flutter_local_notifications'taki idRest ile aynı değil — o kanal
        // artık yalnız iOS'ta kullanılıyor.
        private const val ID_DONE = 7102

        /** Geri sayım dosyasında bitiş sesinin başladığı an (ms). */
        private const val COUNTDOWN_LEAD_MS = 3000L
        private const val WAKE_LOCK_TAG = "fit_pack:rest"

        fun start(
            context: Context,
            deadlineMs: Long,
            sound: Boolean,
            title: String,
            doneTitle: String,
            doneBody: String,
        ) {
            val i = Intent(context, RestTimerService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_DEADLINE, deadlineMs)
                .putExtra(EXTRA_SOUND, sound)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_DONE_TITLE, doneTitle)
                .putExtra(EXTRA_DONE_BODY, doneBody)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, RestTimerService::class.java))
        }

        /** "Dinlenme bitti" bildirimini kaldırır (uygulama öne gelince). */
        fun dismissDone(context: Context) {
            context.getSystemService(NotificationManager::class.java)?.cancel(ID_DONE)
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var focusRequest: AudioFocusRequest? = null
    private var deadlineMs = 0L
    private var sound = true
    private var doneTitle = ""
    private var doneBody = ""

    private val playCountdown = Runnable { startCountdown() }
    private val finish = Runnable { onDeadline() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        deadlineMs = intent?.getLongExtra(EXTRA_DEADLINE, 0L) ?: 0L
        sound = intent?.getBooleanExtra(EXTRA_SOUND, true) ?: true
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        doneTitle = intent?.getStringExtra(EXTRA_DONE_TITLE) ?: ""
        doneBody = intent?.getStringExtra(EXTRA_DONE_BODY) ?: ""

        ensureChannels()
        // startForegroundService'ten sonra 5 sn içinde ÇAĞRILMALI — her durumda.
        val live = liveNotification(title)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(ID_LIVE, live, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(ID_LIVE, live)
        }
        dismissDone(this)

        val left = deadlineMs - System.currentTimeMillis()
        if (left <= 0) {
            stopSelf()
            return START_NOT_STICKY
        }
        acquireWakeLock(left)
        schedule(left)
        // Süreç öldürülürse yeniden başlatma: bitiş anı geçmiş olur, anlamsız.
        return START_NOT_STICKY
    }

    /** Sesi ve bitişi kurar; süre değiştiyse (±15 sn) öncekini iptal eder. */
    private fun schedule(leftMs: Long) {
        handler.removeCallbacks(playCountdown)
        handler.removeCallbacks(finish)
        releasePlayer()
        if (sound) {
            preparePlayer()
            val untilCountdown = leftMs - COUNTDOWN_LEAD_MS
            if (untilCountdown > 0) {
                handler.postDelayed(playCountdown, untilCountdown)
            } else {
                // Kalan süre 3 sn'den az (−15 sn ile kısaltıldı): dosyanın
                // ortasından, doğru bipten başla.
                startCountdown()
            }
        }
        handler.postDelayed(finish, leftMs)
    }

    private fun preparePlayer() {
        val attrs = AudioAttributes.Builder()
            // Navigasyon uyarısı gibi: medya sesi, müziği kısar (duck), sessiz
            // modda da duyulur — salonda telefon çoğunlukla sessizde.
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val afd = resources.openRawResourceFd(R.raw.rest_countdown) ?: return
        player = try {
            MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                prepare() // önceden hazırla: çalma anında yükleme gecikmesi olmasın
                setOnCompletionListener { abandonFocus() }
            }
        } catch (e: Exception) {
            null // ses en iyi çaba; titreşim ve bildirim yine çalışır
        } finally {
            afd.close()
        }
    }

    private fun startCountdown() {
        val p = player ?: return
        val offset = COUNTDOWN_LEAD_MS - (deadlineMs - System.currentTimeMillis())
        try {
            requestFocus()
            if (offset > 0) p.seekTo(offset.toInt())
            p.start()
        } catch (e: Exception) {
            abandonFocus()
        }
    }

    private fun onDeadline() {
        vibrate()
        // Uygulama ekrandaysa sayaç zaten görünüyor — bildirim gereksiz.
        // Boş başlık = kullanıcı mola bildirimini kapatmış.
        if (doneTitle.isNotEmpty() && !appInForeground()) {
            getSystemService(NotificationManager::class.java)
                ?.notify(ID_DONE, doneNotification())
        }
        // Bitiş sesi (~0,6 sn) bitsin, sonra servisi kapat.
        handler.postDelayed({ stopSelf() }, 1500)
    }

    private fun appInForeground(): Boolean {
        val info = ActivityManager.RunningAppProcessInfo()
        ActivityManager.getMyMemoryState(info)
        // Ön plan servisi varken bile IMPORTANCE_FOREGROUND yalnız görünür
        // aktivitede olur (servis tek başına FOREGROUND_SERVICE verir).
        return info.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
    }

    private fun vibrate() {
        val v: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as? Vibrator
        }
        if (v == null || !v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 250, 120, 250), -1))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(longArrayOf(0, 250, 120, 250), -1)
        }
    }

    private fun requestFocus() {
        val am = getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .build()
            focusRequest = req
            am.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        }
    }

    private fun abandonFocus() {
        val am = getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { am.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(null)
        }
    }

    private fun acquireWakeLock(leftMs: Long) {
        if (wakeLock?.isHeld == true) wakeLock?.release()
        val pm = getSystemService(PowerManager::class.java) ?: return
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG).apply {
            setReferenceCounted(false)
            // Güvenlik payı: servis kapanmasa bile kilit kendiliğinden düşer.
            acquire(leftMs + 5000)
        }
    }

    private fun openAppIntent(): PendingIntent {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            this, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun liveNotification(title: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_LIVE)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            // Sistem saati geri sayımı kendisi çizer — güncelleme gerekmez.
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(deadlineMs)
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setContentIntent(openAppIntent())
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()

    private fun doneNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_DONE)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(doneTitle)
            .setContentText(doneBody)
            .setAutoCancel(true)
            // Ses geri sayım dosyasından geldi; bildirim yalnız görsel.
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(openAppIntent())
            .build()

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java) ?: return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_LIVE, "Rest countdown",
                NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shows the running rest timer"
                setShowBadge(false)
            }
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_DONE, "Rest over",
                NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Alerts when the rest between sets is over"
                setSound(null, null)
                enableVibration(false) // titreşim servisten, deseniyle
            }
        )
    }

    private fun releasePlayer() {
        player?.release()
        player = null
        abandonFocus()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releasePlayer()
        if (wakeLock?.isHeld == true) wakeLock?.release()
        wakeLock = null
        super.onDestroy()
    }
}
