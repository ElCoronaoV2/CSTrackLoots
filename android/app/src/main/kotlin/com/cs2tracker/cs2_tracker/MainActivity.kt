package com.cs2tracker.cs2_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Además de arrancar Flutter, expone un MethodChannel para que la app pueda
 * saber si se abrió desde uno de los accesos directos del icono (long-press
 * en el launcher) y a qué pantalla debe navegar.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "cs2tracker/shortcuts"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getInitialShortcut") {
                result.success(intent?.getStringExtra("shortcut"))
            } else {
                result.notImplemented()
            }
        }
    }

    // Con singleTop, si la app ya está en primer plano al pulsar el acceso
    // directo, llega aquí en vez de recrear la Activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val shortcut = intent.getStringExtra("shortcut")
        if (shortcut != null) {
            methodChannel?.invokeMethod("onShortcut", shortcut)
        }
    }
}
