package com.changteng.agora_rtc

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class AgoraLocalVideoViewFactory(
  private val engineHolder: AgoraRtcEngineHolder,
  createArgsCodec: MessageCodec<Any> = StandardMessageCodec.INSTANCE
) : PlatformViewFactory(createArgsCodec) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return AgoraLocalVideoPlatformView(context, engineHolder)
  }
}

class AgoraLocalVideoPlatformView(
  context: Context,
  private val engineHolder: AgoraRtcEngineHolder,
) : PlatformView {
  private val view: FrameLayout = engineHolder.getOrCreateLocalView(context)

  override fun getView(): View = view

  override fun dispose() = Unit
}

class AgoraRemoteVideoViewFactory(
  private val engineHolder: AgoraRtcEngineHolder,
  createArgsCodec: MessageCodec<Any> = StandardMessageCodec.INSTANCE
) : PlatformViewFactory(createArgsCodec) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val params = args as? Map<*, *>
    val uid = (params?.get("uid") as? Number)?.toInt() ?: 0
    return AgoraRemoteVideoPlatformView(context, engineHolder, uid)
  }
}

class AgoraRemoteVideoPlatformView(
  context: Context,
  private val engineHolder: AgoraRtcEngineHolder,
  private val uid: Int,
) : PlatformView {
  private val view: FrameLayout = engineHolder.createRemoteView(context, uid)

  override fun getView(): View = view

  override fun dispose() {
    engineHolder.removeRemoteView(uid)
  }
}
