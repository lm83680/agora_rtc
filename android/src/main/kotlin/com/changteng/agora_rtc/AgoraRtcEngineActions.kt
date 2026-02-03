package com.changteng.agora_rtc

import android.content.Context
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.ClientRoleOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.RtcEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class AgoraRtcEngineActions(
  private val engineHolder: AgoraRtcEngineHolder,
  private val emitter: AgoraEventEmitter
) {
  private val eventHandler = AgoraRtcEngineEventHandler(emitter)
  private val mediaActions = AgoraRtcEngineMediaActions(engineHolder)
  private val recordingActions = AgoraRtcEngineRecordingActions(engineHolder, emitter)

  fun clearRuntimeState() {
    recordingActions.clear()
  }

  fun handleCreateEngine(call: MethodCall, result: Result, applicationContext: Context?) {
    if (engineHolder.rtcEngine != null) {
      result.error("ENGINE_EXISTS", "RtcEngine 已初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val appId = args["appId"] as? String
    if (appId.isNullOrBlank()) {
      result.error("INVALID_ARGS", "appId 为空", null)
      return
    }
    val context = applicationContext
    if (context == null) {
      result.error("NO_CONTEXT", "applicationContext 为空", null)
      return
    }
    try {
      engineHolder.rtcEngine = RtcEngine.create(context, appId, eventHandler)
      engineHolder.bindAllVideoIfReady()
      recordingActions.clear()
      result.success(0)
    } catch (ex: Exception) {
      result.error("ENGINE_CREATE_FAILED", ex.message, null)
    }
  }

  fun handleDestroyEngine(result: Result) {
    if (engineHolder.rtcEngine != null) {
      RtcEngine.destroy()
      engineHolder.clear()
    }
    recordingActions.clear()
    result.success(0)
  }

  fun handleJoinChannel(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val token = args["token"] as? String ?: ""
    val channelId = args["channelId"] as? String
    if (channelId.isNullOrBlank()) {
      result.error("INVALID_ARGS", "channelId 为空", null)
      return
    }
    val uid = (args["uid"] as? Number)?.toInt() ?: 0
    val optionsMap = args["options"] as? Map<*, *>
    val options = buildChannelMediaOptions(optionsMap)
    val code = engine.joinChannel(token, channelId, uid, options)
    result.success(code)
  }

  fun handleLeaveChannel(result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val code = engine.leaveChannel()
    result.success(code)
  }

  fun handleUpdateChannelMediaOptions(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val optionsMap = args["options"] as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "options 为空", null)
      return
    }
    val options = buildChannelMediaOptions(optionsMap)
    val code = engine.updateChannelMediaOptions(options)
    result.success(code)
  }

  fun handleSetChannelProfile(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val profile = (args["profile"] as? Number)?.toInt()
    if (profile == null) {
      result.error("INVALID_ARGS", "profile 为空", null)
      return
    }
    val code = engine.setChannelProfile(profile)
    result.success(code)
  }

  fun handleRenewToken(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val token = args["token"] as? String
    if (token.isNullOrEmpty()) {
      result.error("INVALID_ARGS", "token 为空", null)
      return
    }
    val code = engine.renewToken(token)
    result.success(code)
  }

  fun handleSetClientRole(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val role = (args["role"] as? Number)?.toInt()
    if (role == null) {
      result.error("INVALID_ARGS", "role 为空", null)
      return
    }
    val latencyLevel = (args["latencyLevel"] as? Number)?.toInt()
    if (latencyLevel == null) {
      val code = engine.setClientRole(role)
      result.success(code)
      return
    }
    val options = ClientRoleOptions()
    options.audienceLatencyLevel = when (latencyLevel) {
      1 -> Constants.AUDIENCE_LATENCY_LEVEL_LOW_LATENCY
      2 -> Constants.AUDIENCE_LATENCY_LEVEL_ULTRA_LOW_LATENCY
      else -> Constants.AUDIENCE_LATENCY_LEVEL_LOW_LATENCY
    }
    val code = engine.setClientRole(role, options)
    result.success(code)
  }

  fun handleMuteAllRemoteAudioStreams(call: MethodCall, result: Result) {
    mediaActions.handleMuteAllRemoteAudioStreams(call, result)
  }

  fun handleMuteAllRemoteVideoStreams(call: MethodCall, result: Result) {
    mediaActions.handleMuteAllRemoteVideoStreams(call, result)
  }

  fun handleMuteRemoteAudioStream(call: MethodCall, result: Result) {
    mediaActions.handleMuteRemoteAudioStream(call, result)
  }

  fun handleMuteRemoteVideoStream(call: MethodCall, result: Result) {
    mediaActions.handleMuteRemoteVideoStream(call, result)
  }

  fun handleMuteLocalAudioStream(call: MethodCall, result: Result) {
    mediaActions.handleMuteLocalAudioStream(call, result)
  }

  fun handleMuteLocalVideoStream(call: MethodCall, result: Result) {
    mediaActions.handleMuteLocalVideoStream(call, result)
  }

  fun handleSetRemoteVideoStreamType(call: MethodCall, result: Result) {
    mediaActions.handleSetRemoteVideoStreamType(call, result)
  }

  fun handleEnableVideo(call: MethodCall, result: Result) {
    mediaActions.handleEnableVideo(call, result)
  }

  fun handleEnableLocalVideo(call: MethodCall, result: Result) {
    mediaActions.handleEnableLocalVideo(call, result)
  }

  fun handleStartPreview(call: MethodCall, result: Result) {
    mediaActions.handleStartPreview(call, result)
  }

  fun handleStopPreview(call: MethodCall, result: Result) {
    mediaActions.handleStopPreview(call, result)
  }

  fun handleTakeSnapshot(call: MethodCall, result: Result) {
    mediaActions.handleTakeSnapshot(call, result)
  }

  fun handleStartRecording(call: MethodCall, result: Result) {
    recordingActions.handleStartRecording(call, result)
  }

  fun handleStopRecording(result: Result) {
    recordingActions.handleStopRecording(result)
  }

  private fun buildChannelMediaOptions(optionsMap: Map<*, *>?): ChannelMediaOptions {
    val options = ChannelMediaOptions()
    if (optionsMap == null) {
      return options
    }
    (optionsMap["publishCameraTrack"] as? Boolean)?.let { options.publishCameraTrack = it }
    (optionsMap["publishMicrophoneTrack"] as? Boolean)?.let { options.publishMicrophoneTrack = it }
    (optionsMap["autoSubscribeAudio"] as? Boolean)?.let { options.autoSubscribeAudio = it }
    (optionsMap["autoSubscribeVideo"] as? Boolean)?.let { options.autoSubscribeVideo = it }
    (optionsMap["audienceLatencyLevel"] as? Number)?.toInt()?.let { options.audienceLatencyLevel = it }
    (optionsMap["channelProfile"] as? Number)?.toInt()?.let { options.channelProfile = it }
    (optionsMap["clientRoleType"] as? Number)?.toInt()?.let { options.clientRoleType = it }
    return options
  }
}
