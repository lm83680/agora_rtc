import Flutter
import UIKit
import AgoraRtcKit

public class AgoraRtcEnginePlugin: NSObject, FlutterPlugin {
  private let engineHolder = AgoraRtcEngineViewHolder()
  private let eventStreamHandler = AgoraRtcEventStreamHandler()
  private lazy var actions = AgoraRtcEngineActions(
    engineHolder: engineHolder,
    emitter: eventStreamHandler
  )

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/agora_rtc",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "plugins.flutter.io/agora_rtc/events",
      binaryMessenger: registrar.messenger()
    )
    let instance = AgoraRtcEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance.eventStreamHandler)
    registrar.register(
      AgoraRtcVideoViewFactory(engineHolder: instance.engineHolder, isLocal: true),
      withId: "plugins.flutter.io/agora_rtc/local_view"
    )
    registrar.register(
      AgoraRtcVideoViewFactory(engineHolder: instance.engineHolder, isLocal: false),
      withId: "plugins.flutter.io/agora_rtc/remote_view"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createEngine":
      actions.handleCreateEngine(call, result: result)
    case "destroyEngine":
      actions.handleDestroyEngine(result: result)
    case "joinChannel":
      actions.handleJoinChannel(call, result: result)
    case "leaveChannel":
      actions.handleLeaveChannel(result: result)
    case "updateChannelMediaOptions":
      actions.handleUpdateChannelMediaOptions(call, result: result)
    case "setClientRole":
      actions.handleSetClientRole(call, result: result)
    case "muteAllRemoteAudioStreams":
      actions.handleMuteAllRemoteAudioStreams(call, result: result)
    case "setChannelProfile":
      actions.handleSetChannelProfile(call, result: result)
    case "renewToken":
      actions.handleRenewToken(call, result: result)
    case "muteAllRemoteVideoStreams":
      actions.handleMuteAllRemoteVideoStreams(call, result: result)
    case "muteRemoteAudioStream":
      actions.handleMuteRemoteAudioStream(call, result: result)
    case "muteRemoteVideoStream":
      actions.handleMuteRemoteVideoStream(call, result: result)
    case "muteLocalAudioStream":
      actions.handleMuteLocalAudioStream(call, result: result)
    case "muteLocalVideoStream":
      actions.handleMuteLocalVideoStream(call, result: result)
    case "setRemoteVideoStreamType":
      actions.handleSetRemoteVideoStreamType(call, result: result)
    case "enableVideo":
      actions.handleEnableVideo(call, result: result)
    case "enableLocalVideo":
      actions.handleEnableLocalVideo(call, result: result)
    case "startPreview":
      actions.handleStartPreview(result: result)
    case "stopPreview":
      actions.handleStopPreview(result: result)
    case "takeSnapshot":
      actions.handleTakeSnapshot(call, result: result)
    case "startRecording":
      actions.handleStartRecording(call, result: result)
    case "stopRecording":
      actions.handleStopRecording(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
