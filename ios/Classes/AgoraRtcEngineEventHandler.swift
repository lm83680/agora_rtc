import AgoraRtcKit

final class AgoraRtcEngineEventHandler: NSObject, AgoraRtcEngineDelegate {
  private let emitter: AgoraEventEmitter

  init(emitter: AgoraEventEmitter) {
    self.emitter = emitter
    super.init()
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    emitter.emit(
      type: "onJoinChannelSuccess",
      data: [
        "channel": channel,
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didRejoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    emitter.emit(
      type: "onRejoinChannelSuccess",
      data: [
        "channel": channel,
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    emitter.emit(
      type: "onLeaveChannel",
      data: [
        "duration": stats.duration,
        "txBytes": stats.txBytes,
        "rxBytes": stats.rxBytes,
        "txAudioBytes": stats.txAudioBytes,
        "rxAudioBytes": stats.rxAudioBytes,
        "txVideoBytes": stats.txVideoBytes,
        "rxVideoBytes": stats.rxVideoBytes,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    emitter.emit(
      type: "onUserJoined",
      data: [
        "uid": Int(uid),
        "elapsed": elapsed,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    emitter.emit(
      type: "onUserOffline",
      data: [
        "uid": Int(uid),
        "reason": reason.rawValue,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
    emitter.emit(
      type: "onFirstRemoteVideoFrame",
      data: [
        "uid": Int(uid),
        "channelId": "",
        "width": Int(size.width),
        "height": Int(size.height),
      ]
    )
  }

  func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    didClientRoleChangeFailed reason: AgoraClientRoleChangeFailedReason,
    currentRole: AgoraClientRole
  ) {
    emitter.emit(
      type: "onClientRoleChangeFailed",
      data: [
        "reason": reason.rawValue,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
    emitter.emit(
      type: "onConnectionStateChanged",
      data: [
        "state": state.rawValue,
        "reason": reason.rawValue,
      ]
    )
  }

  func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
    emitter.emit(type: "onRequestToken", data: [:])
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
    emitter.emit(
      type: "onTokenPrivilegeWillExpire",
      data: ["token": token]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
    emitter.emit(
      type: "onError",
      data: [
        "error": errorCode.rawValue,
        "message": "",
      ]
    )
  }

  func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    didAudioPublishStateChange channel: String,
    oldState: AgoraStreamPublishState,
    newState: AgoraStreamPublishState,
    elapseSinceLastState: Int
  ) {
    emitter.emit(
      type: "onAudioPublishStateChanged",
      data: [
        "channel": channel,
        "oldState": oldState.rawValue,
        "newState": newState.rawValue,
        "elapseSinceLastState": elapseSinceLastState,
      ]
    )
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
    emitter.emit(
      type: "onUserMuteVideo",
      data: [
        "channelId": "",
        "uid": Int(uid),
        "muted": muted,
      ]
    )
  }

  func rtcEngine(
    _ engine: AgoraRtcEngineKit,
    snapshotTaken uid: UInt,
    filePath: String,
    width: Int,
    height: Int,
    errCode: Int
  ) {
    emitter.emit(
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
}
