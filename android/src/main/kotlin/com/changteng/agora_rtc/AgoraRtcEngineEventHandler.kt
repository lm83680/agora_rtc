package com.changteng.agora_rtc

import io.agora.rtc2.IRtcEngineEventHandler

class AgoraRtcEngineEventHandler(
  private val emitter: AgoraEventEmitter
) : IRtcEngineEventHandler() {
  override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
    emitter.emit(
      "onJoinChannelSuccess",
      mapOf(
        "channel" to (channel ?: ""),
        "uid" to uid,
        "elapsed" to elapsed
      )
    )
  }

  override fun onRejoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
    emitter.emit(
      "onRejoinChannelSuccess",
      mapOf(
        "channel" to (channel ?: ""),
        "uid" to uid,
        "elapsed" to elapsed
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
    emitter.emit("onLeaveChannel", payload)
  }

  override fun onUserJoined(uid: Int, elapsed: Int) {
    emitter.emit(
      "onUserJoined",
      mapOf(
        "uid" to uid,
        "elapsed" to elapsed
      )
    )
  }

  override fun onUserOffline(uid: Int, reason: Int) {
    emitter.emit(
      "onUserOffline",
      mapOf(
        "uid" to uid,
        "reason" to reason
      )
    )
  }

  override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
    emitter.emit(
      "onFirstRemoteVideoFrame",
      mapOf(
        "uid" to uid,
        "channelId" to "",
        "width" to width,
        "height" to height
      )
    )
  }

  override fun onClientRoleChangeFailed(reason: Int, currentRole: Int) {
    emitter.emit(
      "onClientRoleChangeFailed",
      mapOf("reason" to reason)
    )
  }

  override fun onConnectionStateChanged(state: Int, reason: Int) {
    emitter.emit(
      "onConnectionStateChanged",
      mapOf(
        "state" to state,
        "reason" to reason
      )
    )
  }

  override fun onRequestToken() {
    emitter.emit("onRequestToken", emptyMap())
  }

  override fun onTokenPrivilegeWillExpire(token: String?) {
    emitter.emit(
      "onTokenPrivilegeWillExpire",
      mapOf("token" to (token ?: ""))
    )
  }

  override fun onError(err: Int) {
    emitter.emit(
      "onError",
      mapOf(
        "error" to err,
        "message" to ""
      )
    )
  }

  override fun onAudioPublishStateChanged(
    channel: String?,
    oldState: Int,
    newState: Int,
    elapseSinceLastState: Int
  ) {
    emitter.emit(
      "onAudioPublishStateChanged",
      mapOf(
        "channel" to (channel ?: ""),
        "oldState" to oldState,
        "newState" to newState,
        "elapseSinceLastState" to elapseSinceLastState
      )
    )
  }

  override fun onUserMuteVideo(uid: Int, muted: Boolean) {
    emitter.emit(
      "onUserMuteVideo",
      mapOf(
        "channelId" to "",
        "uid" to uid,
        "muted" to muted
      )
    )
  }

  override fun onSnapshotTaken(uid: Int, filePath: String?, width: Int, height: Int, errCode: Int) {
    emitter.emit(
      "onSnapshotTaken",
      mapOf(
        "connection" to mapOf<String, Any?>(),
        "uid" to uid,
        "filePath" to (filePath ?: ""),
        "width" to width,
        "height" to height,
        "errCode" to errCode
      )
    )
  }
}
