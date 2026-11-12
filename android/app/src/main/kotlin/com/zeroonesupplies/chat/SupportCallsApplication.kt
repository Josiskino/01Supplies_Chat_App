package com.zeroonesupplies.chat
import android.app.Application
import android.os.Bundle
import com.hiennv.flutter_callkit_incoming.CallkitEventCallback
import com.hiennv.flutter_callkit_incoming.FlutterCallkitIncomingPlugin
class SupportCallsApplication : Application(), CallkitEventCallback {
    override fun onCreate() { super.onCreate(); FlutterCallkitIncomingPlugin.registerEventCallback(this) }
    override fun onCallEvent(event: CallkitEventCallback.CallEvent, callData: Bundle) {
        if (event == CallkitEventCallback.CallEvent.ACCEPT) MainActivity.obtainEngine(this)
    }
}
