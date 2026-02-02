package com.changteng.agora_rtc

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import io.agora.rtc2.AgoraMediaRecorder
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.ClientRoleOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.IMediaRecorderCallback
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RecorderInfo
import io.agora.rtc2.RecorderStreamInfo
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.video.VideoCanvas
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** AgoraRtcEnginePlugin */
class AgoraRtcEnginePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private var applicationContext: Context? = null
  private val engineHolder = AgoraRtcEngineHolder()
  private val eventHandler: IRtcEngineEventHandler = object : IRtcEngineEventHandler() {
    override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onJoinChannelSuccess",
          "data" to mapOf(
            "channel" to (channel ?: ""),
            "uid" to uid,
            "elapsed" to elapsed
          )
        )
      )
    }

    override fun onRejoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onRejoinChannelSuccess",
          "data" to mapOf(
            "channel" to (channel ?: ""),
            "uid" to uid,
            "elapsed" to elapsed
          )
        )
      )
    }

    override fun onLeaveChannel(stats: IRtcEngineEventHandler.RtcStats?) {
      val payload = mutableMapOf<String, Any?>()
      if (stats != null) {
        payload["duration"] = stats.totalDuration
        payload["txBytes"] = stats.txBytes
        payload["rxBytes"] = stats.rxBytes
        payload["txKBitRate"] = stats.txKBitRate
        payload["rxKBitRate"] = stats.rxKBitRate
        payload["txAudioBytes"] = stats.txAudioBytes
        payload["rxAudioBytes"] = stats.rxAudioBytes
        payload["txVideoBytes"] = stats.txVideoBytes
        payload["rxVideoBytes"] = stats.rxVideoBytes
      }
      eventStreamHandler.emit(
        mapOf(
          "type" to "onLeaveChannel",
          "data" to payload
        )
      )
    }

    override fun onUserJoined(uid: Int, elapsed: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onUserJoined",
          "data" to mapOf(
            "uid" to uid,
            "elapsed" to elapsed
          )
        )
      )
    }

    override fun onUserOffline(uid: Int, reason: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onUserOffline",
          "data" to mapOf(
            "uid" to uid,
            "reason" to reason
          )
        )
      )
    }

    override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onFirstRemoteVideoFrame",
          "data" to mapOf(
            "uid" to uid,
            "channelId" to "",
            "width" to width,
            "height" to height
          )
        )
      )
    }

    override fun onClientRoleChangeFailed(reason: Int, currentRole: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onClientRoleChangeFailed",
          "data" to mapOf(
            "reason" to reason
          )
        )
      )
    }

    override fun onConnectionStateChanged(state: Int, reason: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onConnectionStateChanged",
          "data" to mapOf(
            "state" to state,
            "reason" to reason
          )
        )
      )
    }

    override fun onRequestToken() {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onRequestToken",
          "data" to mapOf<String, Any?>()
        )
      )
    }

    override fun onTokenPrivilegeWillExpire(token: String?) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onTokenPrivilegeWillExpire",
          "data" to mapOf(
            "token" to (token ?: "")
          )
        )
      )
    }

    override fun onError(err: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onError",
          "data" to mapOf(
            "error" to err,
            "message" to ""
          )
        )
      )
    }

    override fun onAudioPublishStateChanged(
      channel: String?,
      oldState: Int,
      newState: Int,
      elapseSinceLastState: Int
    ) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onAudioPublishStateChanged",
          "data" to mapOf(
            "channel" to (channel ?: ""),
            "oldState" to oldState,
            "newState" to newState,
            "elapseSinceLastState" to elapseSinceLastState
          )
        )
      )
    }

    override fun onUserMuteVideo(uid: Int, muted: Boolean) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onUserMuteVideo",
          "data" to mapOf(
            "channelId" to "",
            "uid" to uid,
            "muted" to muted
          )
        )
      )
    }

    override fun onSnapshotTaken(uid: Int, filePath: String?, width: Int, height: Int, errCode: Int) {
      eventStreamHandler.emit(
        mapOf(
          "type" to "onSnapshotTaken",
          "data" to mapOf(
            "connection" to mapOf<String, Any?>(),
            "uid" to uid,
            "filePath" to (filePath ?: ""),
            "width" to width,
            "height" to height,
            "errCode" to errCode
          )
        )
      )
    }
  }
  private val eventStreamHandler = AgoraRtcEventStreamHandler()
  private var mediaRecorder: AgoraMediaRecorder? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.io/agora_rtc")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.io/agora_rtc/events")
    eventChannel.setStreamHandler(eventStreamHandler)
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/local_view",
      AgoraLocalVideoViewFactory(engineHolder)
    )
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/remote_view",
      AgoraRemoteVideoViewFactory(engineHolder)
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "createEngine" -> handleCreateEngine(call, result)
      "destroyEngine" -> handleDestroyEngine(result)
      "joinChannel" -> handleJoinChannel(call, result)
      "leaveChannel" -> handleLeaveChannel(result)
      "updateChannelMediaOptions" -> handleUpdateChannelMediaOptions(call, result)
      "setClientRole" -> handleSetClientRole(call, result)
      "muteAllRemoteAudioStreams" -> handleMuteAllRemoteAudioStreams(call, result)
      "setChannelProfile" -> handleSetChannelProfile(call, result)
      "renewToken" -> handleRenewToken(call, result)
      "muteAllRemoteVideoStreams" -> handleMuteAllRemoteVideoStreams(call, result)
      "muteRemoteAudioStream" -> handleMuteRemoteAudioStream(call, result)
      "muteRemoteVideoStream" -> handleMuteRemoteVideoStream(call, result)
      "muteLocalAudioStream" -> handleMuteLocalAudioStream(call, result)
      "muteLocalVideoStream" -> handleMuteLocalVideoStream(call, result)
      "setRemoteVideoStreamType" -> handleSetRemoteVideoStreamType(call, result)
      "enableVideo" -> handleEnableVideo(call, result)
      "enableLocalVideo" -> handleEnableLocalVideo(call, result)
      "startPreview" -> handleStartPreview(call, result)
      "stopPreview" -> handleStopPreview(call, result)
      "takeSnapshot" -> handleTakeSnapshot(call, result)
      "startRecording" -> handleStartRecording(call, result)
      "stopRecording" -> handleStopRecording(result)
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    applicationContext = null
    engineHolder.clear()
  }

  private fun handleCreateEngine(call: MethodCall, result: Result) {
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
      result.success(null)
    } catch (ex: Exception) {
      result.error("ENGINE_CREATE_FAILED", ex.message, null)
    }
  }

  private fun handleDestroyEngine(result: Result) {
    if (engineHolder.rtcEngine != null) {
      RtcEngine.destroy()
      engineHolder.clear()
    }
    mediaRecorder = null
    result.success(null)
  }

  private fun handleJoinChannel(call: MethodCall, result: Result) {
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
    engine.joinChannel(token, channelId, uid, options)
    result.success(null)
  }

  private fun handleLeaveChannel(result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    engine.leaveChannel()
    result.success(null)
  }

  private fun handleSetChannelProfile(call: MethodCall, result: Result) {
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
    engine.setChannelProfile(profile)
    result.success(null)
  }

  private fun handleRenewToken(call: MethodCall, result: Result) {
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
    engine.renewToken(token)
    result.success(null)
  }

  private fun handleUpdateChannelMediaOptions(call: MethodCall, result: Result) {
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
    engine.updateChannelMediaOptions(options)
    result.success(null)
  }

  private fun handleSetClientRole(call: MethodCall, result: Result) {
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
      engine.setClientRole(role)
      result.success(null)
      return
    }
    val options = ClientRoleOptions()
    options.audienceLatencyLevel = when (latencyLevel) {
      1 -> Constants.AUDIENCE_LATENCY_LEVEL_LOW_LATENCY
      2 -> Constants.AUDIENCE_LATENCY_LEVEL_ULTRA_LOW_LATENCY
      else -> Constants.AUDIENCE_LATENCY_LEVEL_LOW_LATENCY
    }
    engine.setClientRole(role, options)
    result.success(null)
  }

  private fun handleMuteAllRemoteAudioStreams(call: MethodCall, result: Result) {
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
    engine.muteAllRemoteAudioStreams(muted)
    result.success(null)
  }

  private fun handleMuteAllRemoteVideoStreams(call: MethodCall, result: Result) {
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
    engine.muteAllRemoteVideoStreams(muted)
    result.success(null)
  }

  private fun handleMuteRemoteAudioStream(call: MethodCall, result: Result) {
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
    engine.muteRemoteAudioStream(uid, muted)
    result.success(null)
  }

  private fun handleMuteRemoteVideoStream(call: MethodCall, result: Result) {
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
    engine.muteRemoteVideoStream(uid, muted)
    result.success(null)
  }

  private fun handleMuteLocalAudioStream(call: MethodCall, result: Result) {
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
    engine.muteLocalAudioStream(muted)
    result.success(null)
  }

  private fun handleMuteLocalVideoStream(call: MethodCall, result: Result) {
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
    engine.muteLocalVideoStream(muted)
    result.success(null)
  }

  private fun handleSetRemoteVideoStreamType(call: MethodCall, result: Result) {
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
    engine.setRemoteVideoStreamType(uid, streamType)
    result.success(null)
  }

  private fun handleEnableVideo(call: MethodCall, result: Result) {
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
    if (enabled) {
      engine.enableVideo()
    } else {
      engine.disableVideo()
    }
    result.success(null)
  }

  private fun handleEnableLocalVideo(call: MethodCall, result: Result) {
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
    engine.enableLocalVideo(enabled)
    result.success(null)
  }

  private fun handleStartPreview(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    engine.startPreview()
    result.success(null)
  }

  private fun handleStopPreview(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    engine.stopPreview()
    result.success(null)
  }

  private fun handleTakeSnapshot(call: MethodCall, result: Result) {
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
    engine.takeSnapshot(uid, filePath)
    result.success(null)
  }

  private fun handleStartRecording(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val configMap = args["config"] as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "config 为空", null)
      return
    }
    val channelId = configMap["channelId"] as? String ?: ""
    val uid = (configMap["uid"] as? Number)?.toInt() ?: 0
    val storagePath = configMap["storagePath"] as? String
    val containerFormat = (configMap["containerFormat"] as? Number)?.toInt() ?: AgoraMediaRecorder.CONTAINER_MP4
    val streamType = (configMap["streamType"] as? Number)?.toInt() ?: AgoraMediaRecorder.STREAM_TYPE_BOTH
    val maxDurationMs = (configMap["maxDurationMs"] as? Number)?.toInt() ?: 120000
    val recorderInfoUpdateInterval = (configMap["recorderInfoUpdateInterval"] as? Number)?.toInt() ?: 0
    if (storagePath.isNullOrBlank()) {
      result.error("INVALID_ARGS", "storagePath 为空", null)
      return
    }
    try {
      if (mediaRecorder == null) {
        val streamInfo = RecorderStreamInfo(
          channelId,
          uid,
        )
        mediaRecorder = engine.createMediaRecorder(streamInfo)
        mediaRecorder?.setMediaRecorderObserver(object : IMediaRecorderCallback {
          override fun onRecorderStateChanged(channelId: String?, uid: Int, state: Int, error: Int) {
            eventStreamHandler.emit(
              mapOf(
                "type" to "onRecorderStateChanged",
                "data" to mapOf(
                  "channelId" to (channelId ?: ""),
                  "uid" to uid,
                  "state" to state,
                  "reason" to error
                )
              )
            )
          }

          override fun onRecorderInfoUpdated(channelId: String?, uid: Int, info: RecorderInfo?) {
          }
        })
      }
      val config = AgoraMediaRecorder.MediaRecorderConfiguration(
        storagePath,
        containerFormat,
        streamType,
        maxDurationMs,
        recorderInfoUpdateInterval
      )
      mediaRecorder?.startRecording(config)
      result.success(null)
    } catch (ex: Exception) {
      result.error("RECORDER_UNSUPPORTED", ex.message, null)
    }
  }

  private fun handleStopRecording(result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val recorder = mediaRecorder ?: run {
      result.success(null)
      return
    }
    recorder.stopRecording()
    recorder.setMediaRecorderObserver(null)
    engine.destroyMediaRecorder(recorder)
    mediaRecorder = null
    result.success(null)
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

private class AgoraRtcEventStreamHandler : EventChannel.StreamHandler {
  private val mainHandler = Handler(Looper.getMainLooper())
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun emit(event: Map<String, Any?>) {
    val sink = eventSink ?: return
    mainHandler.post {
      sink.success(event)
    }
  }
}

private class AgoraRtcEngineHolder {
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

private class AgoraLocalVideoViewFactory(
  private val engineHolder: AgoraRtcEngineHolder,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return AgoraLocalVideoPlatformView(context, engineHolder)
  }
}

private class AgoraLocalVideoPlatformView(
  context: Context,
  private val engineHolder: AgoraRtcEngineHolder,
) : PlatformView {
  private val view: FrameLayout = engineHolder.getOrCreateLocalView(context)

  override fun getView(): View = view

  override fun dispose() = Unit
}

private class AgoraRemoteVideoViewFactory(
  private val engineHolder: AgoraRtcEngineHolder,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val params = args as? Map<*, *>
    val uid = (params?.get("uid") as? Number)?.toInt() ?: 0
    return AgoraRemoteVideoPlatformView(context, engineHolder, uid)
  }
}

private class AgoraRemoteVideoPlatformView(
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
