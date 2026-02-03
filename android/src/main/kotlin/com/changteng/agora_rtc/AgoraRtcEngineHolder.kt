package com.changteng.agora_rtc

import android.content.Context
import android.widget.FrameLayout
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.video.VideoCanvas

class AgoraRtcEngineHolder {
  var rtcEngine: RtcEngine? = null
  private var localView: FrameLayout? = null
  private var localSurfaceView: android.view.SurfaceView? = null
  private val remoteSurfaceViews = mutableMapOf<Int, android.view.SurfaceView>()

  fun getOrCreateLocalView(context: Context): FrameLayout {
    val container = localView ?: FrameLayout(context).also { localView = it }
    val surfaceView = localSurfaceView ?: android.view.SurfaceView(context).also { localSurfaceView = it }
    if (surfaceView.parent != container) {
      (surfaceView.parent as? FrameLayout)?.removeView(surfaceView)
      if (surfaceView.parent == null) {
        container.addView(
          surfaceView,
          FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
          )
        )
      }
    }
    bindLocalVideoIfReady()
    return container
  }

  fun createRemoteView(context: Context, uid: Int): FrameLayout {
    val container = FrameLayout(context)
    val surfaceView = android.view.SurfaceView(context)
    surfaceView.setZOrderMediaOverlay(true)
    container.addView(
      surfaceView,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
    )
    remoteSurfaceViews[uid] = surfaceView
    bindRemoteVideoIfReady(uid)
    return container
  }

  fun bindAllVideoIfReady() {
    bindLocalVideoIfReady()
    remoteSurfaceViews.keys.forEach { uid ->
      bindRemoteVideoIfReady(uid)
    }
  }

  private fun bindLocalVideoIfReady() {
    val engine = rtcEngine ?: return
    val surfaceView = localSurfaceView ?: return
    engine.setupLocalVideo(VideoCanvas(surfaceView, VideoCanvas.RENDER_MODE_FIT, 0))
    engine.startPreview()
  }

  private fun bindRemoteVideoIfReady(uid: Int) {
    val engine = rtcEngine ?: return
    val surfaceView = remoteSurfaceViews[uid] ?: return
    engine.setupRemoteVideo(VideoCanvas(surfaceView, VideoCanvas.RENDER_MODE_FIT, uid))
  }

  fun removeRemoteView(uid: Int) {
    val surfaceView = remoteSurfaceViews.remove(uid) ?: return
    (surfaceView.parent as? FrameLayout)?.removeView(surfaceView)
    rtcEngine?.setupRemoteVideo(VideoCanvas(null, VideoCanvas.RENDER_MODE_FIT, uid))
  }

  fun clear() {
    rtcEngine = null
    localView = null
    localSurfaceView = null
    remoteSurfaceViews.clear()
  }
}
