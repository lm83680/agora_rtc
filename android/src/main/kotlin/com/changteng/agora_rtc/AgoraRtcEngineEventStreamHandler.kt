package com.changteng.agora_rtc

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

interface AgoraEventEmitter {
  fun emit(type: String, data: Map<String, Any?>)
}

class AgoraRtcEventStreamHandler : EventChannel.StreamHandler, AgoraEventEmitter {
  private val mainHandler = Handler(Looper.getMainLooper())
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun emit(type: String, data: Map<String, Any?>) {
    emitRaw(
      mapOf(
        "type" to type,
        "data" to data
      )
    )
  }

  private fun emitRaw(event: Map<String, Any?>) {
    val sink = eventSink ?: return
    mainHandler.post {
      sink.success(event)
    }
  }
}
