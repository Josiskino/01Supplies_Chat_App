package com.zeroonesupplies.chat

import io.flutter.embedding.android.FlutterActivity
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = obtainEngine(context)
    override fun shouldDestroyEngineWithHost(): Boolean = false
    companion object {
        private const val ENGINE_ID = "01support-main"
        @Synchronized fun obtainEngine(context: Context): FlutterEngine {
            val cache = FlutterEngineCache.getInstance()
            cache.get(ENGINE_ID)?.let { return it }
            val engine = FlutterEngine(context.applicationContext)
            cache.put(ENGINE_ID, engine)
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            return engine
        }
    }

}
