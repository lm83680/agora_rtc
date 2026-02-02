import Flutter
import UIKit
import AgoraRtcKit

public class AgoraRtcEnginePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, AgoraRtcEngineDelegate {
  private var rtcEngine: AgoraRtcEngineKit?
  private var eventSink: FlutterEventSink?
  private var localVideoView: UIView?
  private var remoteVideoViews: [UInt: UIView] = [:]
  private var mediaRecorder: AgoraMediaRecorder?
  private var recorderChannelId: String = ""
  private var recorderUid: UInt = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plugins.flutter.io/agora_rtc", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "plugins.flutter.io/agora_rtc/events", binaryMessenger: registrar.messenger())
    let instance = AgoraRtcEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    registrar.register(
      AgoraRtcVideoViewFactory(plugin: instance, isLocal: true),
      withId: "plugins.flutter.io/agora_rtc/local_view"
    )
    registrar.register(
      AgoraRtcVideoViewFactory(plugin: instance, isLocal: false),
      withId: "plugins.flutter.io/agora_rtc/remote_view"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createEngine":
      handleCreateEngine(call, result: result)
    case "destroyEngine":
      handleDestroyEngine(result: result)
    case "joinChannel":
      handleJoinChannel(call, result: result)
    case "leaveChannel":
      handleLeaveChannel(result: result)
    case "updateChannelMediaOptions":
      handleUpdateChannelMediaOptions(call, result: result)
    case "setClientRole":
      handleSetClientRole(call, result: result)
    case "muteAllRemoteAudioStreams":
      handleMuteAllRemoteAudioStreams(call, result: result)
    case "setChannelProfile":
      handleSetChannelProfile(call, result: result)
    case "renewToken":
      handleRenewToken(call, result: result)
    case "muteAllRemoteVideoStreams":
      handleMuteAllRemoteVideoStreams(call, result: result)
    case "muteRemoteAudioStream":
      handleMuteRemoteAudioStream(call, result: result)
    case "muteRemoteVideoStream":
      handleMuteRemoteVideoStream(call, result: result)
    case "muteLocalAudioStream":
      handleMuteLocalAudioStream(call, result: result)
    case "muteLocalVideoStream":
      handleMuteLocalVideoStream(call, result: result)
    case "setRemoteVideoStreamType":
      handleSetRemoteVideoStreamType(call, result: result)
    case "enableVideo":
      handleEnableVideo(call, result: result)
    case "enableLocalVideo":
      handleEnableLocalVideo(call, result: result)
    case "startPreview":
      handleStartPreview(result: result)
    case "stopPreview":
      handleStopPreview(result: result)
    case "takeSnapshot":
      handleTakeSnapshot(call, result: result)
    case "startRecording":
      handleStartRecording(call, result: result)
    case "stopRecording":
      handleStopRecording(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleCreateEngine(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if rtcEngine != nil {
      result(FlutterError(code: "ENGINE_EXISTS", message: "RtcEngine 已初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let appId = args["appId"] as? String, !appId.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "appId 为空", details: nil))
      return
    }
    rtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
    bindCachedVideoViews()
    result(nil)
  }

  private func handleDestroyEngine(result: @escaping FlutterResult) {
    if rtcEngine != nil {
      AgoraRtcEngineKit.destroy()
      rtcEngine = nil
    }
    mediaRecorder = nil
    localVideoView = nil
    remoteVideoViews.removeAll()
    result(nil)
  }

  private func handleJoinChannel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    let token = (args["token"] as? String) ?? ""
    guard let channelId = args["channelId"] as? String, !channelId.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "channelId 为空", details: nil))
      return
    }
    let uid = (args["uid"] as? NSNumber)?.uintValue ?? 0
    let optionsMap = args["options"] as? [String: Any]
    let options = buildChannelMediaOptions(optionsMap)
    engine.joinChannel(byToken: token, channelId: channelId, uid: uid, mediaOptions: options)
    result(nil)
  }

  private func handleLeaveChannel(result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    engine.leaveChannel(nil)
    result(nil)
  }

  private func handleUpdateChannelMediaOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let optionsMap = args["options"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "options 为空", details: nil))
      return
    }
    let options = buildChannelMediaOptions(optionsMap)
    engine.updateChannel(with: options)
    result(nil)
  }

  private func handleSetClientRole(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let roleValue = (args["role"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "role 为空", details: nil))
      return
    }
    let role = AgoraClientRole(rawValue: roleValue) ?? .audience
    if let latencyLevel = (args["latencyLevel"] as? NSNumber)?.intValue {
      let options = AgoraClientRoleOptions()
      options.audienceLatencyLevel = latencyLevel == 2 ? .ultraLowLatency : .lowLatency
      engine.setClientRole(role, options: options)
    } else {
      engine.setClientRole(role)
    }
    result(nil)
  }

  private func handleMuteAllRemoteAudioStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    engine.muteAllRemoteAudioStreams(muted)
    result(nil)
  }

  private func handleSetChannelProfile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let profileValue = (args["profile"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "profile 为空", details: nil))
      return
    }
    let profile = AgoraChannelProfile(rawValue: profileValue) ?? .communication
    engine.setChannelProfile(profile)
    result(nil)
  }

  private func handleRenewToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let token = args["token"] as? String, !token.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "token 为空", details: nil))
      return
    }
    engine.renewToken(token)
    result(nil)
  }

  private func handleMuteAllRemoteVideoStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    engine.muteAllRemoteVideoStreams(muted)
    result(nil)
  }

  private func handleMuteRemoteAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue,
          let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 或 muted 为空", details: nil))
      return
    }
    engine.muteRemoteAudioStream(uid, mute: muted)
    result(nil)
  }

  private func handleMuteRemoteVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue,
          let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 或 muted 为空", details: nil))
      return
    }
    engine.muteRemoteVideoStream(uid, mute: muted)
    result(nil)
  }

  private func handleMuteLocalAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    engine.muteLocalAudioStream(muted)
    result(nil)
  }

  private func handleMuteLocalVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    engine.muteLocalVideoStream(muted)
    result(nil)
  }

  private func handleSetRemoteVideoStreamType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue,
          let streamTypeValue = (args["streamType"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 或 streamType 为空", details: nil))
      return
    }
    let streamType = AgoraVideoStreamType(rawValue: streamTypeValue) ?? .high
    engine.setRemoteVideoStream(uid, type: streamType)
    result(nil)
  }

  private func handleEnableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let enabled = args["enabled"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "enabled 为空", details: nil))
      return
    }
    if enabled {
      engine.enableVideo()
    } else {
      engine.disableVideo()
    }
    result(nil)
  }

  private func handleEnableLocalVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let enabled = args["enabled"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "enabled 为空", details: nil))
      return
    }
    engine.enableLocalVideo(enabled)
    result(nil)
  }

  private func handleStartPreview(result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    engine.startPreview()
    result(nil)
  }

  private func handleStopPreview(result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    engine.stopPreview()
    result(nil)
  }

  private func handleTakeSnapshot(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.intValue,
          let filePath = args["filePath"] as? String,
          !filePath.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 或 filePath 为空", details: nil))
      return
    }
    engine.takeSnapshot(uid, filePath: filePath)
    result(nil)
  }

  private func handleStartRecording(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let config = args["config"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "config 为空", details: nil))
      return
    }
    let channelId = (config["channelId"] as? String) ?? ""
    let uid = (config["uid"] as? NSNumber)?.uintValue ?? 0
    guard let storagePath = config["storagePath"] as? String, !storagePath.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "storagePath 为空", details: nil))
      return
    }
    let containerFormatValue = (config["containerFormat"] as? NSNumber)?.intValue ?? AgoraMediaRecorderContainerFormat.MP4.rawValue
    let streamTypeValue = (config["streamType"] as? NSNumber)?.intValue ?? AgoraMediaRecorderStreamType.both.rawValue
    let maxDurationMsValue = (config["maxDurationMs"] as? NSNumber)?.intValue ?? 120000
    let recorderInfoUpdateIntervalValue = (config["recorderInfoUpdateInterval"] as? NSNumber)?.intValue ?? 0
    let width = (config["width"] as? NSNumber)?.intValue
    let height = (config["height"] as? NSNumber)?.intValue
    let fps = (config["fps"] as? NSNumber)?.intValue
    let sampleRate = (config["sampleRate"] as? NSNumber)?.intValue
    let channelNum = (config["channelNum"] as? NSNumber)?.intValue
    let videoSourceType = (config["videoSourceType"] as? NSNumber)?.intValue
    recorderChannelId = channelId
    recorderUid = uid
    if mediaRecorder == nil {
      let streamInfo = AgoraRecorderStreamInfo()
      streamInfo.channelId = channelId
      streamInfo.uid = uid
      mediaRecorder = engine.createMediaRecorder(withInfo: streamInfo)
      mediaRecorder?.setMediaRecorderDelegate(self)
    }
    let recorderConfig = AgoraMediaRecorderConfiguration()
    recorderConfig.storagePath = storagePath
    recorderConfig.containerFormat = AgoraMediaRecorderContainerFormat(rawValue: containerFormatValue) ?? .MP4
    recorderConfig.streamType = AgoraMediaRecorderStreamType(rawValue: streamTypeValue) ?? .both
    recorderConfig.maxDurationMs = UInt(maxDurationMsValue)
    recorderConfig.recorderInfoUpdateInterval = UInt(recorderInfoUpdateIntervalValue)
    if let widthValue = width {
      recorderConfig.width = UInt(widthValue)
    }
    if let heightValue = height {
      recorderConfig.height = UInt(heightValue)
    }
    if let fpsValue = fps {
      recorderConfig.fps = UInt(fpsValue)
    }
    if let sampleRateValue = sampleRate {
      recorderConfig.sample_rate = UInt(sampleRateValue)
    }
    if let channelNumValue = channelNum {
      recorderConfig.channel_num = UInt(channelNumValue)
    }
    if let videoSourceTypeValue = videoSourceType {
      recorderConfig.videoSourceType = AgoraVideoSourceType(rawValue: videoSourceTypeValue) ?? .camera
    }
    mediaRecorder?.startRecording(recorderConfig)
    result(nil)
  }

  private func handleStopRecording(result: @escaping FlutterResult) {
    guard let engine = rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    if let recorder = mediaRecorder {
      recorder.stopRecording()
      engine.destroy(recorder)
      mediaRecorder = nil
    }
    result(nil)
  }

  private func buildChannelMediaOptions(_ optionsMap: [String: Any]?) -> AgoraRtcChannelMediaOptions {
    let options = AgoraRtcChannelMediaOptions()
    guard let map = optionsMap else { return options }
    if let publishCameraTrack = map["publishCameraTrack"] as? Bool {
      options.publishCameraTrack = publishCameraTrack
    }
    if let publishMicrophoneTrack = map["publishMicrophoneTrack"] as? Bool {
      options.publishMicrophoneTrack = publishMicrophoneTrack
    }
    if let autoSubscribeAudio = map["autoSubscribeAudio"] as? Bool {
      options.autoSubscribeAudio = autoSubscribeAudio
    }
    if let autoSubscribeVideo = map["autoSubscribeVideo"] as? Bool {
      options.autoSubscribeVideo = autoSubscribeVideo
    }
    if let clientRoleType = (map["clientRoleType"] as? NSNumber)?.intValue {
      options.clientRoleType = AgoraClientRole(rawValue: clientRoleType) ?? .audience
    }
    if let audienceLatencyLevel = (map["audienceLatencyLevel"] as? NSNumber)?.intValue {
      options.audienceLatencyLevel = audienceLatencyLevel == 2 ? .ultraLowLatency : .lowLatency
    }
    if let channelProfile = (map["channelProfile"] as? NSNumber)?.intValue {
      options.channelProfile = AgoraChannelProfile(rawValue: channelProfile) ?? .communication
    }
    return options
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    emitEvent(
      type: "onJoinChannelSuccess",
      data: [
        "channel": channel,
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didRejoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    emitEvent(
      type: "onRejoinChannelSuccess",
      data: [
        "channel": channel,
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    let txKBitRate = Int(stats.txAudioKBitrate + stats.txVideoKBitrate)
    let rxKBitRate = Int(stats.rxAudioKBitrate + stats.rxVideoKBitrate)
    emitEvent(
      type: "onLeaveChannel",
      data: [
        "duration": stats.duration,
        "txBytes": stats.txBytes,
        "rxBytes": stats.rxBytes,
        "txKBitRate": txKBitRate,
        "rxKBitRate": rxKBitRate,
        "txAudioBytes": stats.txAudioBytes,
        "rxAudioBytes": stats.rxAudioBytes,
        "txVideoBytes": stats.txVideoBytes,
        "rxVideoBytes": stats.rxVideoBytes,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    emitEvent(
      type: "onUserJoined",
      data: [
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    emitEvent(
      type: "onUserOffline",
      data: [
        "uid": Int(uid),
        "reason": reason.rawValue,
      ]
    )
  }

  public func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    firstRemoteVideoFrameOfUid uid: UInt,
    size: CGSize,
    elapsed: Int
  ) {
    emitEvent(
      type: "onFirstRemoteVideoFrame",
      data: [
        "uid": Int(uid),
        "channelId": "",
        "width": Int(size.width),
        "height": Int(size.height),
      ]
    )
  }

  public func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    didClientRoleChangeFailed reason: AgoraClientRoleChangeFailedReason,
    currentRole: AgoraClientRole
  ) {
    emitEvent(
      type: "onClientRoleChangeFailed",
      data: [
        "reason": reason.rawValue,
      ]
    )
  }

  public func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    connectionChangedTo state: AgoraConnectionState,
    reason: AgoraConnectionChangedReason
  ) {
    emitEvent(
      type: "onConnectionStateChanged",
      data: [
        "state": state.rawValue,
        "reason": reason.rawValue,
      ]
    )
  }

  public func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
    emitEvent(
      type: "onRequestToken",
      data: [:]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
    emitEvent(
      type: "onTokenPrivilegeWillExpire",
      data: [
        "token": token,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
    emitEvent(
      type: "onError",
      data: [
        "error": errorCode.rawValue,
        "message": "",
      ]
    )
  }

  public func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    didAudioPublishStateChange channel: String,
    oldState: AgoraStreamPublishState,
    newState: AgoraStreamPublishState,
    elapseSinceLastState: Int
  ) {
    emitEvent(
      type: "onAudioPublishStateChanged",
      data: [
        "channel": channel,
        "oldState": oldState.rawValue,
        "newState": newState.rawValue,
        "elapseSinceLastState": elapseSinceLastState,
      ]
    )
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
    emitEvent(
      type: "onUserMuteVideo",
      data: [
        "channelId": "",
        "uid": Int(uid),
        "muted": muted,
      ]
    )
  }

  public func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    snapshotTaken uid: UInt,
    filePath: String,
    width: Int,
    height: Int,
    errCode: Int
  ) {
    emitEvent(
      type: "onSnapshotTaken",
      data: [
        "connection": [:],
        "uid": Int(uid),
        "filePath": filePath,
        "width": width,
        "height": height,
        "errCode": errCode,
      ]
    )
  }

  private func emitEvent(type: String, data: [String: Any]) {
    guard let sink = eventSink else { return }
    DispatchQueue.main.async {
      sink([
        "type": type,
        "data": data,
      ])
    }
  }

  fileprivate func makeLocalVideoView() -> UIView {
    let view = localVideoView ?? UIView()
    localVideoView = view
    if view.superview != nil {
      view.removeFromSuperview()
    }
    if let engine = rtcEngine {
      let canvas = AgoraRtcVideoCanvas()
      canvas.view = view
      canvas.renderMode = .hidden
      engine.setupLocalVideo(canvas)
      engine.startPreview()
    }
    return view
  }

  fileprivate func makeRemoteVideoView(uid: UInt) -> UIView {
    let view = remoteVideoViews[uid] ?? UIView()
    remoteVideoViews[uid] = view
    if view.superview != nil {
      view.removeFromSuperview()
    }
    bindRemoteVideoView(uid: uid)
    return view
  }

  private func bindCachedVideoViews() {
    if localVideoView != nil {
      _ = makeLocalVideoView()
    }
    for uid in remoteVideoViews.keys {
      bindRemoteVideoView(uid: uid)
    }
  }

  private func bindRemoteVideoView(uid: UInt) {
    guard let engine = rtcEngine, let view = remoteVideoViews[uid] else { return }
    let canvas = AgoraRtcVideoCanvas()
    canvas.view = view
    canvas.renderMode = .hidden
    canvas.uid = uid
    engine.setupRemoteVideo(canvas)
  }
}

private class AgoraRtcVideoViewFactory: NSObject, FlutterPlatformViewFactory {
  private weak var plugin: AgoraRtcEnginePlugin?
  private let isLocal: Bool

  init(plugin: AgoraRtcEnginePlugin, isLocal: Bool) {
    self.plugin = plugin
    self.isLocal = isLocal
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return AgoraRtcVideoPlatformView(plugin: plugin, isLocal: isLocal, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

private class AgoraRtcVideoPlatformView: NSObject, FlutterPlatformView {
  private let rootView: UIView

  init(plugin: AgoraRtcEnginePlugin?, isLocal: Bool, args: Any?) {
    if let plugin = plugin {
      if isLocal {
        rootView = plugin.makeLocalVideoView()
      } else {
        let params = args as? [String: Any]
        let uid = (params?["uid"] as? NSNumber)?.uintValue ?? 0
        rootView = plugin.makeRemoteVideoView(uid: uid)
      }
    } else {
      rootView = UIView()
    }
    super.init()
  }

  func view() -> UIView {
    return rootView
  }
}

extension AgoraRtcEnginePlugin: AgoraMediaRecorderDelegate {
  public func mediaRecorder(
    _ recorder: AgoraMediaRecorder,
    stateDidChanged channelId: String,
    uid: UInt,
    state: AgoraMediaRecorderState,
    reason: AgoraMediaRecorderReasonCode
  ) {
    emitEvent(
      type: "onRecorderStateChanged",
      data: [
        "channelId": channelId,
        "uid": Int(uid),
        "state": state.rawValue,
        "reason": reason.rawValue,
      ]
    )
  }

  public func mediaRecorder(
    _ recorder: AgoraMediaRecorder,
    informationDidUpdated channelId: String,
    uid: UInt,
    info: AgoraMediaRecorderInfo
  ) {
    emitEvent(
      type: "onRecorderInfoUpdated",
      data: [
        "channelId": channelId,
        "uid": Int(uid),
        "filePath": info.recorderFileName ?? "",
        "durationMs": info.durationMs,
        "fileSize": info.fileSize,
      ]
    )
  }
}
