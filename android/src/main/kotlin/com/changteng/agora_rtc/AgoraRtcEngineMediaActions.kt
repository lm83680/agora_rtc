package com.changteng.agora_rtc

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class AgoraRtcEngineMediaActions(
  private val engineHolder: AgoraRtcEngineHolder
) {
  fun handleMuteAllRemoteAudioStreams(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val muted = args["muted"] as? Boolean
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    val code = engine.muteAllRemoteAudioStreams(muted)
    result.success(code)
  }

  fun handleMuteAllRemoteVideoStreams(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val muted = args["muted"] as? Boolean
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    val code = engine.muteAllRemoteVideoStreams(muted)
    result.success(code)
  }

  fun handleMuteRemoteAudioStream(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val uid = (args["uid"] as? Number)?.toInt()
    val muted = args["muted"] as? Boolean
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    val code = engine.muteRemoteAudioStream(uid, muted)
    result.success(code)
  }

  fun handleMuteRemoteVideoStream(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val uid = (args["uid"] as? Number)?.toInt()
    val muted = args["muted"] as? Boolean
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    val code = engine.muteRemoteVideoStream(uid, muted)
    result.success(code)
  }

  fun handleMuteLocalAudioStream(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val muted = args["muted"] as? Boolean
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    val code = engine.muteLocalAudioStream(muted)
    result.success(code)
  }

  fun handleMuteLocalVideoStream(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val muted = args["muted"] as? Boolean
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    val code = engine.muteLocalVideoStream(muted)
    result.success(code)
  }

  fun handleSetRemoteVideoStreamType(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val uid = (args["uid"] as? Number)?.toInt()
    val streamType = (args["streamType"] as? Number)?.toInt()
    if (uid == null || streamType == null) {
      result.error("INVALID_ARGS", "uid 或 streamType 为空", null)
      return
    }
    val code = engine.setRemoteVideoStreamType(uid, streamType)
    result.success(code)
  }

  fun handleEnableVideo(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val enabled = args["enabled"] as? Boolean
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    val code = if (enabled) engine.enableVideo() else engine.disableVideo()
    result.success(code)
  }

  fun handleEnableLocalVideo(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val enabled = args["enabled"] as? Boolean
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    val code = engine.enableLocalVideo(enabled)
    result.success(code)
  }

  fun handleStartPreview(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val code = engine.startPreview()
    result.success(code)
  }

  fun handleStopPreview(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val code = engine.stopPreview()
    result.success(code)
  }

  fun handleTakeSnapshot(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val uid = (args["uid"] as? Number)?.toInt()
    val filePath = args["filePath"] as? String
    if (uid == null || filePath.isNullOrBlank()) {
      result.error("INVALID_ARGS", "uid 或 filePath 为空", null)
      return
    }
    val code = engine.takeSnapshot(uid, filePath)
    result.success(code)
  }
}
