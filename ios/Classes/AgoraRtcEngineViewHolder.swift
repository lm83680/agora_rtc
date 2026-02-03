import UIKit
import AgoraRtcKit

final class AgoraRtcEngineViewHolder {
  var rtcEngine: AgoraRtcEngineKit?
  private var localVideoView: UIView?
  private var remoteVideoViews: [UInt: UIView] = [:]

  func makeLocalVideoView() -> UIView {
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

  func makeRemoteVideoView(uid: UInt) -> UIView {
    let view = remoteVideoViews[uid] ?? UIView()
    remoteVideoViews[uid] = view
    if view.superview != nil {
      view.removeFromSuperview()
    }
    bindRemoteVideoView(uid: uid)
    return view
  }

  func bindCachedVideoViews() {
    if localVideoView != nil {
      _ = makeLocalVideoView()
    }
    for uid in remoteVideoViews.keys {
      bindRemoteVideoView(uid: uid)
    }
  }

  func removeRemoteVideoView(uid: UInt) {
    remoteVideoViews.removeValue(forKey: uid)
    guard let engine = rtcEngine else { return }
    let canvas = AgoraRtcVideoCanvas()
    canvas.uid = uid
    canvas.view = nil
    engine.setupRemoteVideo(canvas)
  }

  func clear() {
    rtcEngine = nil
    localVideoView = nil
    remoteVideoViews.removeAll()
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
