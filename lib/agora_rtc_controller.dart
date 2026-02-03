import 'agora_rtc_events.dart';
import 'agora_rtc_platform_interface.dart';

/// Flutter 侧 AgoraRtc 控制器
class AgoraRtcController {
  AgoraRtcController({
    required this.appId,
  });

  /// AppId。
  final String appId;

  /// 创建并初始化 RtcEngine。
  Future<int> createEngine() {
    return AgoraRtcPlatform.instance.createEngine(appId: appId);
  }

  /// 销毁 RtcEngine。
  Future<int> destroyEngine() {
    return AgoraRtcPlatform.instance.destroyEngine();
  }

  /// 设置频道场景。
  Future<int> setChannelProfile({
    required int profile,
  }) {
    return AgoraRtcPlatform.instance.setChannelProfile(
      profile: profile,
    );
  }

  /// 加入频道。
  Future<int> joinChannel({
    required String token,
    required String channelId,

    /// 0 表示由 SDK 分配。
    int uid = 0,

    /// 加入频道选项（由原生侧映射）。
    Map<String, Object?>? options,
  }) {
    return AgoraRtcPlatform.instance.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: options,
    );
  }

  /// 离开频道。
  Future<int> leaveChannel() {
    return AgoraRtcPlatform.instance.leaveChannel();
  }

  /// 更新频道媒体选项（加入频道后调用）。
  Future<int> updateChannelMediaOptions({
    required Map<String, Object?> options,
  }) {
    return AgoraRtcPlatform.instance.updateChannelMediaOptions(
      options: options,
    );
  }

  /// 更新 Token。
  Future<int> renewToken({
    required String token,
  }) {
    return AgoraRtcPlatform.instance.renewToken(
      token: token,
    );
  }

  /// 设置用户角色与延时级别。
  Future<int> setClientRole({
    required int role,

    /// 1-低延迟 2-超低延迟。
    int? latencyLevel,
  }) {
    return AgoraRtcPlatform.instance.setClientRole(
      role: role,
      latencyLevel: latencyLevel,
    );
  }

  /// 取消或恢复订阅所有远端音频流。
  Future<int> muteAllRemoteAudioStreams({
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteAllRemoteAudioStreams(
      muted: muted,
    );
  }

  /// 取消或恢复订阅所有远端视频流。
  Future<int> muteAllRemoteVideoStreams({
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteAllRemoteVideoStreams(
      muted: muted,
    );
  }

  /// 取消或恢复订阅指定远端用户音频流。
  Future<int> muteRemoteAudioStream({
    required int uid,
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteRemoteAudioStream(
      uid: uid,
      muted: muted,
    );
  }

  /// 取消或恢复订阅指定远端用户视频流。
  Future<int> muteRemoteVideoStream({
    required int uid,
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteRemoteVideoStream(
      uid: uid,
      muted: muted,
    );
  }

  /// 取消或恢复发布本地音频流。
  Future<int> muteLocalAudioStream({
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteLocalAudioStream(
      muted: muted,
    );
  }

  /// 取消或恢复发布本地视频流。
  Future<int> muteLocalVideoStream({
    required bool muted,
  }) {
    return AgoraRtcPlatform.instance.muteLocalVideoStream(
      muted: muted,
    );
  }

  /// 设置订阅的视频流类型。
  Future<int> setRemoteVideoStreamType({
    required int uid,
    required int streamType,
  }) {
    return AgoraRtcPlatform.instance.setRemoteVideoStreamType(
      uid: uid,
      streamType: streamType,
    );
  }

  /// 启用或关闭视频模块。
  Future<int> enableVideo({
    /// true-启用 false-关闭。
    required bool enabled,
  }) {
    return AgoraRtcPlatform.instance.enableVideo(
      enabled: enabled,
    );
  }

  /// 开关本地视频采集。
  Future<int> enableLocalVideo({
    /// true-开启 false-关闭。
    required bool enabled,
  }) {
    return AgoraRtcPlatform.instance.enableLocalVideo(
      enabled: enabled,
    );
  }

  /// 启动本地视频预览。
  Future<int> startPreview({
    /// 视频源类型（由原生侧映射）。
    int? sourceType,
  }) {
    return AgoraRtcPlatform.instance.startPreview(
      sourceType: sourceType,
    );
  }

  /// 停止本地视频预览。
  Future<int> stopPreview({
    /// 视频源类型（由原生侧映射）。
    int? sourceType,
  }) {
    return AgoraRtcPlatform.instance.stopPreview(
      sourceType: sourceType,
    );
  }

  /// 对视频截图。
  Future<int> takeSnapshot({
    /// 用户 UID，0 表示本地用户。
    required int uid,

    /// 截图保存路径，需包含文件名与扩展名。
    required String filePath,
  }) {
    return AgoraRtcPlatform.instance.takeSnapshot(
      uid: uid,
      filePath: filePath,
    );
  }

  /// 创建录制实例并开始录制。
  Future<int> startRecording({
    /// 录制配置（由原生侧映射）。
    required Map<String, Object?> config,
  }) {
    return AgoraRtcPlatform.instance.startRecording(
      config: config,
    );
  }

  /// 停止录制并销毁录制实例。
  Future<int> stopRecording() {
    return AgoraRtcPlatform.instance.stopRecording();
  }

  /// 统一事件流。
  Stream<AgoraEvent> get events {
    return AgoraRtcPlatform.instance.events;
  }
}
