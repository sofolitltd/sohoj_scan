package com.sohoj.sohoj_scan

import android.content.Intent
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
 *   native → Flutter: "openScanner"              (bubble / tile tapped)
 *   Flutter → native: "startBubble", "stopBubble", "canDrawOverlays"
 *   Flutter → native: "pasteToFocused" {number}  (Phase 2 only)
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val ENGINE_ID = "sohoj_engine"
        const val CHANNEL = "scanner"
        const val EXTRA_OPEN_SCANNER = "open_scanner"
    }

    private var channel: MethodChannel? = null

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine {
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
                    "canDrawOverlays" -> result.success(android.provider.Settings.canDrawOverlays(this@MainActivity))
                    "startBubble" -> { BubbleService.start(this@MainActivity); result.success(true) }
                    "stopBubble" -> { BubbleService.stop(this@MainActivity); result.success(true) }
                    else -> result.notImplemented()
                }
            }
        }
        if (intent?.getBooleanExtra(EXTRA_OPEN_SCANNER, false) == true) channel?.invokeMethod("openScanner", null)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_SCANNER, false)) channel?.invokeMethod("openScanner", null)
    }
}
