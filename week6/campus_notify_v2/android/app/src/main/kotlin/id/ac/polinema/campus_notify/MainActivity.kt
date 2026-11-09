package id.ac.polinema.campus_notify

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "campus_notify/badge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setBadge" -> {
                        setBadge(call.argument<Int>("count") ?: 0)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Best-effort untuk launcher bermerek (Samsung/Xiaomi/Oppo/Vivo).
    // Launcher Google standar (termasuk emulator) tidak menampilkan badge
    // aplikasi — ini batasan launcher, bukan bug.
    private fun setBadge(count: Int) {
        val manager = AppWidgetManager.getInstance(this)
        val widgetId = manager
            .getAppWidgetIds(ComponentName(this, MainActivity::class.java))
            .firstOrNull() ?: 1
        sendBroadcast(
            Intent("android.appwidget.action.APPWIDGET_UPDATE").apply {
                setPackage(packageName)
                putExtra("appWidgetId", widgetId)
            }
        )
        sendBroadcast(
            Intent("$packageName.BADGE_COUNT").apply {
                putExtra("badge_count", count)
                putExtra("app_badge_count", count)
            }
        )
    }
}
