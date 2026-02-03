import Flutter
import UIKit

final class AgoraRtcVideoViewFactory: NSObject, FlutterPlatformViewFactory {
  private let engineHolder: AgoraRtcEngineViewHolder
  private let isLocal: Bool

  init(engineHolder: AgoraRtcEngineViewHolder, isLocal: Bool) {
    self.engineHolder = engineHolder
    self.isLocal = isLocal
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return AgoraRtcVideoPlatformView(engineHolder: engineHolder, isLocal: isLocal, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AgoraRtcVideoPlatformView: NSObject, FlutterPlatformView {
  private let rootView: UIView

  init(engineHolder: AgoraRtcEngineViewHolder, isLocal: Bool, args: Any?) {
    if isLocal {
      rootView = engineHolder.makeLocalVideoView()
    } else {
      let params = args as? [String: Any]
      let uid = (params?["uid"] as? NSNumber)?.uintValue ?? 0
      rootView = engineHolder.makeRemoteVideoView(uid: uid)
    }
    super.init()
  }

  func view() -> UIView {
    return rootView
  }
}
