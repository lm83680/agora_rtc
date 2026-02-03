package com.changteng.agora_rtc

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec

/** AgoraRtcEnginePlugin */
class AgoraRtcEnginePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var applicationContext: Context? = null
  private val engineHolder = AgoraRtcEngineHolder()
  private val eventStreamHandler = AgoraRtcEventStreamHandler()
  private val actions = AgoraRtcEngineActions(engineHolder, eventStreamHandler)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.io/agora_rtc")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.io/agora_rtc/events")
    eventChannel.setStreamHandler(eventStreamHandler)
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/local_view",
      AgoraLocalVideoViewFactory(engineHolder, StandardMessageCodec.INSTANCE)
    )
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/remote_view",
      AgoraRemoteVideoViewFactory(engineHolder, StandardMessageCodec.INSTANCE)
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "createEngine" -> actions.handleCreateEngine(call, result, applicationContext)
      "destroyEngine" -> actions.handleDestroyEngine(result)
      "joinChannel" -> actions.handleJoinChannel(call, result)
      "leaveChannel" -> actions.handleLeaveChannel(result)
      "updateChannelMediaOptions" -> actions.handleUpdateChannelMediaOptions(call, result)
      "setClientRole" -> actions.handleSetClientRole(call, result)
      "muteAllRemoteAudioStreams" -> actions.handleMuteAllRemoteAudioStreams(call, result)
      "setChannelProfile" -> actions.handleSetChannelProfile(call, result)
      "renewToken" -> actions.handleRenewToken(call, result)
      "muteAllRemoteVideoStreams" -> actions.handleMuteAllRemoteVideoStreams(call, result)
      "muteRemoteAudioStream" -> actions.handleMuteRemoteAudioStream(call, result)
      "muteRemoteVideoStream" -> actions.handleMuteRemoteVideoStream(call, result)
      "muteLocalAudioStream" -> actions.handleMuteLocalAudioStream(call, result)
      "muteLocalVideoStream" -> actions.handleMuteLocalVideoStream(call, result)
      "setRemoteVideoStreamType" -> actions.handleSetRemoteVideoStreamType(call, result)
      "enableVideo" -> actions.handleEnableVideo(call, result)
      "enableLocalVideo" -> actions.handleEnableLocalVideo(call, result)
      "startPreview" -> actions.handleStartPreview(call, result)
      "stopPreview" -> actions.handleStopPreview(call, result)
      "takeSnapshot" -> actions.handleTakeSnapshot(call, result)
      "startRecording" -> actions.handleStartRecording(call, result)
      "stopRecording" -> actions.handleStopRecording(result)
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    applicationContext = null
    engineHolder.clear()
    actions.clearRuntimeState()
  }
}
