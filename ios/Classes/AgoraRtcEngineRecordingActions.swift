import Flutter
import AgoraRtcKit

final class AgoraRtcEngineRecordingActions: NSObject {
  private let engineHolder: AgoraRtcEngineViewHolder
  private let emitter: AgoraEventEmitter
  private var mediaRecorder: AgoraMediaRecorder?
  private var shouldDestroyOnStop: Bool = false

  init(engineHolder: AgoraRtcEngineViewHolder, emitter: AgoraEventEmitter) {
    self.engineHolder = engineHolder
    self.emitter = emitter
    super.init()
  }

  func clear() {
    mediaRecorder = nil
    shouldDestroyOnStop = false
  }

  func handleStartRecording(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
      return
    }
    guard let configMap = args["config"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "config 为空", details: nil))
      return
    }
    let channelId = (configMap["channelId"] as? String) ?? ""
    let uid = (configMap["uid"] as? NSNumber)?.uintValue ?? 0
    guard let storagePath = configMap["storagePath"] as? String, !storagePath.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "storagePath 为空", details: nil))
      return
    }
    let containerFormat = (configMap["containerFormat"] as? NSNumber)?.intValue
    let maxDurationMs = (configMap["maxDurationMs"] as? NSNumber)?.intValue ?? 120000
    if mediaRecorder == nil {
      let streamInfo = AgoraRecorderStreamInfo()
      streamInfo.channelId = channelId
      streamInfo.uid = uid
      mediaRecorder = engine.createMediaRecorder(withInfo: streamInfo)
      mediaRecorder?.setMediaRecorderDelegate(self)
    }
    guard let recorder = mediaRecorder else {
      result(FlutterError(code: "RECORDER_UNSUPPORTED", message: "创建录制实例失败", details: nil))
      return
    }
    let config = AgoraMediaRecorderConfiguration()
    config.storagePath = storagePath
    if let rawValue = containerFormat,
       let format = AgoraMediaRecorderContainerFormat(rawValue: rawValue) {
      config.containerFormat = format
    } else {
      config.containerFormat = .MP4
    }
    config.maxDurationMs = UInt(maxDurationMs)
    let code = recorder.startRecording(config)
    result(code)
  }

  func handleStopRecording(result: @escaping FlutterResult) {
    guard let engine = engineHolder.rtcEngine else {
      result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
      return
    }
    guard let recorder = mediaRecorder else {
      result(-1)
      return
    }
    shouldDestroyOnStop = true
    let stopCode = recorder.stopRecording()
    if stopCode < 0 {
      recorder.setMediaRecorderDelegate(nil)
      engine.destroy(recorder)
      mediaRecorder = nil
      shouldDestroyOnStop = false
    }
    result(stopCode)
  }
}

extension AgoraRtcEngineRecordingActions: AgoraMediaRecorderDelegate {
  func mediaRecorder(
    _ recorder: AgoraMediaRecorder,
    stateDidChanged channelId: String,
    uid: UInt,
    state: AgoraMediaRecorderState,
    reason: AgoraMediaRecorderReasonCode
  ) {
    emitter.emit(
      type: "onRecorderStateChanged",
      data: [
        "channelId": channelId,
        "uid": Int(uid),
        "state": state.rawValue,
        "reason": reason.rawValue,
      ]
    )
    if shouldDestroyOnStop {
      recorder.setMediaRecorderDelegate(nil)
      engineHolder.rtcEngine?.destroy(recorder)
      mediaRecorder = nil
      shouldDestroyOnStop = false
    }
  }

  func mediaRecorder(
    _ recorder: AgoraMediaRecorder,
    informationDidUpdated channelId: String,
    uid: UInt,
    info: AgoraMediaRecorderInfo
  ) {
  }
}
