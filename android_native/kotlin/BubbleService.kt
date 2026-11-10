package com.sohoj.sohoj_scan

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.ImageView
import kotlin.math.abs

/**
 * The floating bubble (design: FloatingBubble). A plain ImageView in a
 * foreground service: no second Flutter engine, < 10 MB RAM.
 * Needs: SYSTEM_ALERT_WINDOW, FOREGROUND_SERVICE, FOREGROUND_SERVICE_SPECIAL_USE,
 * POST_NOTIFICATIONS (13+). See manifest-snippet.xml.
 */
class BubbleService : Service() {

    companion object {
        private const val NOTIF_CHANNEL = "bubble"
        private const val NOTIF_ID = 7
        fun start(ctx: Context) = ctx.startForegroundService(Intent(ctx, BubbleService::class.java))
        fun stop(ctx: Context) = ctx.stopService(Intent(ctx, BubbleService::class.java))
    }

    private lateinit var wm: WindowManager
    private var bubble: ImageView? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        startAsForeground()
        addBubble()
    }

    override fun onDestroy() {
        bubble?.let { wm.removeView(it) }
        bubble = null
        super.onDestroy()
    }

    private fun startAsForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(NOTIF_CHANNEL, "নাম্বার স্ক্যান বাবল", NotificationManager.IMPORTANCE_MIN)
        )
        val n: Notification = Notification.Builder(this, NOTIF_CHANNEL)
            .setSmallIcon(R.drawable.ic_scan)
            .setContentTitle("বাবল চালু আছে")
            .setContentText("বন্ধ করতে বাবলটা নিচে টেনে আনুন")
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun addBubble() {
        val sizePx = (64 * resources.displayMetrics.density).toInt()   // size-bubble
        val marginPx = (16 * resources.displayMetrics.density).toInt()  // space-4
        val params = WindowManager.LayoutParams(
            sizePx, sizePx,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - sizePx - marginPx
            y = resources.displayMetrics.heightPixels / 3
        }

        val view = ImageView(this).apply {
            setImageResource(R.drawable.bubble_mark)          // from assets/Logos/sohoj-mark.svg
            contentDescription = "নাম্বার স্ক্যান খুলুন"
            elevation = 12f
        }

        var downX = 0f; var downY = 0f; var startX = 0; var startY = 0; var moved = false
        view.setOnTouchListener { v, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY; startX = params.x; startY = params.y; moved = false
                    v.alpha = 1f
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX; val dy = e.rawY - downY
                    if (abs(dx) > 12 || abs(dy) > 12) moved = true
                    params.x = startX + dx.toInt(); params.y = startY + dy.toInt()
                    wm.updateViewLayout(v, params)
                    // TODO(M5): show the "বন্ধ" dismiss target near the bottom centre while dragging.
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!moved) {
                        v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        openScanner()
                    } else {
                        // TODO(M5): if released over the dismiss target → stopSelf().
                        val screenW = resources.displayMetrics.widthPixels
                        params.x = if (params.x + sizePx / 2 < screenW / 2) marginPx else screenW - sizePx - marginPx
                        wm.updateViewLayout(v, params)
                    }
                    // TODO(M5): fade to 0.7 alpha after 4 s idle; long-press → history.
                    true
                }
                else -> false
            }
        }
        wm.addView(view, params)
        bubble = view
    }

    private fun openScanner() {
        val i = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(MainActivity.EXTRA_OPEN_SCANNER, true)
        }
        // The overlay permission lets us start an activity from the background.
        PendingIntent.getActivity(this, 0, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT).send()
    }
}
