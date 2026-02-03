import Flutter

protocol AgoraEventEmitter {
  func emit(type: String, data: [String: Any])
}

final class AgoraRtcEventStreamHandler: NSObject, FlutterStreamHandler, AgoraEventEmitter {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func emit(type: String, data: [String: Any]) {
    guard let sink = eventSink else { return }
    DispatchQueue.main.async {
      sink([
        "type": type,
        "data": data,
      ])
    }
  }
}
