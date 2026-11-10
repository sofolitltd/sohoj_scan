package com.sohoj.sohoj_scan

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Keeps one warm FlutterEngine so a tap on the bubble or tile shows the
 * scanner in ~0.5 s instead of a cold start.
 *
 * Channel "scanner":
 *   native → Flutter: "openScanner" / "openHistory" (bubble tap / long-press, tile)
 *   Flutter → native: "startBubble", "stopBubble", "canDrawOverlays",
 *                      "requestOverlayPermission", "isIgnoringBatteryOptimizations",
 *                      "requestIgnoreBatteryOptimizations", "openAutostartSettings"
 *   Flutter → native: "pasteToFocused" {number}  (Phase 2 only)
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val ENGINE_ID = "sohoj_engine"
        const val CHANNEL = "scanner"
        const val EXTRA_OPEN_SCANNER = "open_scanner"
        const val EXTRA_OPEN_HISTORY = "open_history"
    }

    private var channel: MethodChannel? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }
        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this@MainActivity))
                    "requestOverlayPermission" -> {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "openAutostartSettings" -> {
                        openAutostartSettings()
                        result.success(null)
                    }
                    "startBubble" -> { BubbleService.start(this@MainActivity); result.success(true) }
                    "stopBubble" -> { BubbleService.stop(this@MainActivity); result.success(true) }
                    else -> result.notImplemented()
                }
            }
        }
        dispatchLaunchExtras(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        dispatchLaunchExtras(intent)
    }

    private fun dispatchLaunchExtras(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_OPEN_HISTORY, false) == true) {
            channel?.invokeMethod("openHistory", null)
        } else if (intent?.getBooleanExtra(EXTRA_OPEN_SCANNER, false) == true) {
            channel?.invokeMethod("openScanner", null)
        }
    }

    /** Brand autostart screens are not a public API; this is best-effort. */
    private fun openAutostartSettings() {
        val candidates = when (Build.MANUFACTURER.lowercase()) {
            "xiaomi" -> listOf(
                Intent().setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            )
            "oppo" -> listOf(
                Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                Intent().setClassName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")
            )
            "vivo" -> listOf(
                Intent().setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")
            )
            "realme" -> listOf(
                Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
            )
            "infinix", "transsion", "tecno", "itel" -> listOf(
                Intent().setClassName("com.transsion.phonemanager", "com.itel.autobootmanager.ui.AutoBootMgrActivity"),
                Intent().setClassName("com.transsion.phonemanager", "com.transsion.phonemanager.module.security.autobot.AutoBootMgrActivity")
            )
            else -> emptyList()
        }
        for (i in candidates) {
            if (packageManager.resolveActivity(i, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            }
        }
        // No known brand screen (or a brand we don't recognise): fall back to this app's settings page.
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }
}
