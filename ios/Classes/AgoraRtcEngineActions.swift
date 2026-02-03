import Flutter
import AgoraRtcKit

final class AgoraRtcEngineActions {
  private let engineHolder: AgoraRtcEngineViewHolder
  private let eventHandler: AgoraRtcEngineEventHandler
  private let mediaActions: AgoraRtcEngineMediaActions
  private let recordingActions: AgoraRtcEngineRecordingActions

  init(engineHolder: AgoraRtcEngineViewHolder, emitter: AgoraEventEmitter) {
    self.engineHolder = engineHolder
    self.eventHandler = AgoraRtcEngineEventHandler(emitter: emitter)
    self.mediaActions = AgoraRtcEngineMediaActions(engineHolder: engineHolder)
    self.recordingActions = AgoraRtcEngineRecordingActions(engineHolder: engineHolder, emitter: emitter)
  }

  func handleCreateEngine(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if engineHolder.rtcEngine != nil {
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
    let config = AgoraRtcEngineConfig()
    config.appId = appId
    let engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: eventHandler)
    engineHolder.rtcEngine = engine
    engineHolder.bindCachedVideoViews()
    recordingActions.clear()
    result(0)
  }

  func handleDestroyEngine(result: @escaping FlutterResult) {
    if engineHolder.rtcEngine != nil {
      AgoraRtcEngineKit.destroy()
      engineHolder.clear()
    }
    recordingActions.clear()
    result(0)
  }

  func handleJoinChannel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.joinChannel(byToken: token, channelId: channelId, uid: uid, mediaOptions: options)
    result(code)
  }

  func handleLeaveChannel(result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    let code = engine.leaveChannel(nil)
    result(code)
  }

  func handleUpdateChannelMediaOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.updateChannel(with: options)
    result(code)
  }

  func handleSetChannelProfile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let profile = (args["profile"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "profile 为空", details: nil))
      return
    }
    guard let profileType = AgoraChannelProfile(rawValue: profile) else {
      result(FlutterError(code: "INVALID_ARGS", message: "profile 不合法", details: nil))
      return
    }
    let code = engine.setChannelProfile(profileType)
    result(code)
  }

  func handleRenewToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.renewToken(token)
    result(code)
  }

  func handleSetClientRole(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let roleValue = (args["role"] as? NSNumber)?.intValue,
          let role = AgoraClientRole(rawValue: roleValue) else {
      result(FlutterError(code: "INVALID_ARGS", message: "role 为空", details: nil))
      return
    }
    let latencyLevel = (args["latencyLevel"] as? NSNumber)?.intValue
    if latencyLevel == nil {
      let code = engine.setClientRole(role)
      result(code)
      return
    }
    let options = AgoraClientRoleOptions()
    options.audienceLatencyLevel = latencyLevel == 2 ? .ultraLowLatency : .lowLatency
    let code = engine.setClientRole(role, options: options)
    result(code)
  }

  func handleMuteAllRemoteAudioStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteAllRemoteAudioStreams(call, result: result)
  }

  func handleMuteAllRemoteVideoStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteAllRemoteVideoStreams(call, result: result)
  }

  func handleMuteRemoteAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteRemoteAudioStream(call, result: result)
  }

  func handleMuteRemoteVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteRemoteVideoStream(call, result: result)
  }

  func handleMuteLocalAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteLocalAudioStream(call, result: result)
  }

  func handleMuteLocalVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleMuteLocalVideoStream(call, result: result)
  }

  func handleSetRemoteVideoStreamType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleSetRemoteVideoStreamType(call, result: result)
  }

  func handleEnableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleEnableVideo(call, result: result)
  }

  func handleEnableLocalVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleEnableLocalVideo(call, result: result)
  }

  func handleStartPreview(result: @escaping FlutterResult) {
    mediaActions.handleStartPreview(result: result)
  }

  func handleStopPreview(result: @escaping FlutterResult) {
    mediaActions.handleStopPreview(result: result)
  }

  func handleTakeSnapshot(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    mediaActions.handleTakeSnapshot(call, result: result)
  }

  func handleStartRecording(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    recordingActions.handleStartRecording(call, result: result)
  }

  func handleStopRecording(result: @escaping FlutterResult) {
    recordingActions.handleStopRecording(result: result)
  }

  private func buildChannelMediaOptions(_ optionsMap: [String: Any]?) -> AgoraRtcChannelMediaOptions {
    let options = AgoraRtcChannelMediaOptions()
    guard let map = optionsMap else {
      return options
    }
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
    if let roleValue = (map["clientRoleType"] as? NSNumber)?.intValue,
       let role = AgoraClientRole(rawValue: roleValue) {
      options.clientRoleType = role
    }
    if let latencyLevel = (map["audienceLatencyLevel"] as? NSNumber)?.intValue {
      options.audienceLatencyLevel = latencyLevel == 2 ? .ultraLowLatency : .lowLatency
    }
    if let profileValue = (map["channelProfile"] as? NSNumber)?.intValue,
       let profile = AgoraChannelProfile(rawValue: profileValue) {
      options.channelProfile = profile
    }
    return options
  }

}
