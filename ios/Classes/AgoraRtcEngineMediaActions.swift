import Flutter
import AgoraRtcKit

final class AgoraRtcEngineMediaActions {
  private let engineHolder: AgoraRtcEngineViewHolder

  init(engineHolder: AgoraRtcEngineViewHolder) {
    self.engineHolder = engineHolder
  }

  func handleMuteAllRemoteAudioStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.muteAllRemoteAudioStreams(muted)
    result(code)
  }

  func handleMuteAllRemoteVideoStreams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.muteAllRemoteVideoStreams(muted)
    result(code)
  }

  func handleMuteRemoteAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 为空", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    let code = engine.muteRemoteAudioStream(uid, mute: muted)
    result(code)
  }

  func handleMuteRemoteVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 为空", details: nil))
      return
    }
    guard let muted = args["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGS", message: "muted 为空", details: nil))
      return
    }
    let code = engine.muteRemoteVideoStream(uid, mute: muted)
    result(code)
  }

  func handleMuteLocalAudioStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.muteLocalAudioStream(muted)
    result(code)
  }

  func handleMuteLocalVideoStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.muteLocalVideoStream(muted)
    result(code)
  }

  func handleSetRemoteVideoStreamType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 为空", details: nil))
      return
    }
    guard let streamType = (args["streamType"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "streamType 为空", details: nil))
      return
    }
    let code = engine.setRemoteVideoStream(uid, type: AgoraVideoStreamType(rawValue: streamType) ?? .high)
    result(code)
  }

  func handleEnableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = enabled ? engine.enableVideo() : engine.disableVideo()
    result(code)
  }

  func handleEnableLocalVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
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
    let code = engine.enableLocalVideo(enabled)
    result(code)
  }

  func handleStartPreview(result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    let code = engine.startPreview()
    result(code)
  }

  func handleStopPreview(result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    let code = engine.stopPreview()
    result(code)
  }

  func handleTakeSnapshot(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let uid = (args["uid"] as? NSNumber)?.uintValue else {
      result(FlutterError(code: "INVALID_ARGS", message: "uid 为空", details: nil))
      return
    }
    guard let filePath = args["filePath"] as? String, !filePath.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "filePath 为空", details: nil))
      return
    }
    let code = engine.takeSnapshot(Int(uid), filePath: filePath)
    result(code)
  }
}
