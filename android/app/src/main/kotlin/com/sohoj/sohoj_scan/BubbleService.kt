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
import android.os.Handler
import android.os.Looper
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
        dismiss?.let { wm.removeView(it) }
        dismiss = null
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

        val dismissSizePx = (88 * resources.displayMetrics.density).toInt()
        val dismissZone = addDismissZone(dismissSizePx)

        val idleHandler = Handler(Looper.getMainLooper())
        val idleRunnable = Runnable { view.animate().alpha(0.7f).setDuration(200).start() }
        fun resetIdle() {
            idleHandler.removeCallbacks(idleRunnable)
            idleHandler.postDelayed(idleRunnable, 4000)
        }

        var downX = 0f; var downY = 0f; var startX = 0; var startY = 0; var moved = false
        var longPressed = false
        val longPress = Runnable {
            longPressed = true
            v@ view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
            openHistory()
        }
        view.setOnTouchListener { v, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY; startX = params.x; startY = params.y
                    moved = false; longPressed = false
                    v.alpha = 1f
                    idleHandler.removeCallbacks(idleRunnable)
                    idleHandler.postDelayed(longPress, 500)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX; val dy = e.rawY - downY
                    if (abs(dx) > 12 || abs(dy) > 12) {
                        if (!moved) idleHandler.removeCallbacks(longPress)
                        moved = true
                    }
                    if (moved) {
                        params.x = startX + dx.toInt(); params.y = startY + dy.toInt()
                        wm.updateViewLayout(v, params)
                        dismissZone.visibility = android.view.View.VISIBLE
                        dismissZone.isSelected = isOverDismiss(params, sizePx, dismissZone, dismissSizePx)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    idleHandler.removeCallbacks(longPress)
                    dismissZone.visibility = android.view.View.GONE
                    if (!moved && !longPressed) {
                        v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        openScanner()
                    } else if (moved && isOverDismiss(params, sizePx, dismissZone, dismissSizePx)) {
                        stopSelf()
                        return@setOnTouchListener true
                    } else if (moved) {
                        val screenW = resources.displayMetrics.widthPixels
                        params.x = if (params.x + sizePx / 2 < screenW / 2) marginPx else screenW - sizePx - marginPx
                        wm.updateViewLayout(v, params)
                    }
                    resetIdle()
                    true
                }
                else -> false
            }
        }
        resetIdle()
        wm.addView(view, params)
        bubble = view
    }

    private var dismiss: android.widget.TextView? = null

    private fun addDismissZone(sizePx: Int): android.widget.TextView {
        val view = android.widget.TextView(this).apply {
            text = "বন্ধ"
            setTextColor(android.graphics.Color.WHITE)
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(android.graphics.Color.argb(200, 20, 20, 16))
            visibility = android.view.View.GONE
        }
        val params = WindowManager.LayoutParams(
            sizePx, sizePx,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = (24 * resources.displayMetrics.density).toInt()
        }
        wm.addView(view, params)
        dismiss = view
        return view
    }

    private fun isOverDismiss(
        bubbleParams: WindowManager.LayoutParams,
        bubbleSizePx: Int,
        dismissView: android.widget.TextView,
        dismissSizePx: Int,
    ): Boolean {
        val screenW = resources.displayMetrics.widthPixels
        val screenH = resources.displayMetrics.heightPixels
        val bubbleCx = bubbleParams.x + bubbleSizePx / 2
        val bubbleCy = bubbleParams.y + bubbleSizePx / 2
        val dismissCx = screenW / 2
        val dismissCy = screenH - dismissSizePx / 2 - (24 * resources.displayMetrics.density).toInt()
        val dx = (bubbleCx - dismissCx).toDouble()
        val dy = (bubbleCy - dismissCy).toDouble()
        return dx * dx + dy * dy < (dismissSizePx / 1.5) * (dismissSizePx / 1.5)
    }

    private fun openHistory() {
        val i = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(MainActivity.EXTRA_OPEN_HISTORY, true)
        }
        PendingIntent.getActivity(this, 2, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT).send()
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
