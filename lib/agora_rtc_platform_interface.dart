import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'agora_rtc_events.dart';
import 'agora_rtc_method_channel.dart';

abstract class AgoraRtcPlatform extends PlatformInterface {
  AgoraRtcPlatform() : super(token: _token);

  static final Object _token = Object();

  static AgoraRtcPlatform _instance = MethodChannelAgoraRtc();

  static AgoraRtcPlatform get instance => _instance;

  static set instance(AgoraRtcPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 创建并初始化 RtcEngine。
  Future<int> createEngine({
    required String appId,
  }) {
    throw UnimplementedError('createEngine() has not been implemented.');
  }

  /// 销毁 RtcEngine。
  Future<int> destroyEngine() {
    throw UnimplementedError('destroyEngine() has not been implemented.');
  }

  /// 设置频道场景。
  Future<int> setChannelProfile({
    required int profile,
  }) {
    throw UnimplementedError('setChannelProfile() has not been implemented.');
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
    throw UnimplementedError('joinChannel() has not been implemented.');
  }

  /// 离开频道。
  Future<int> leaveChannel() {
    throw UnimplementedError('leaveChannel() has not been implemented.');
  }

  /// 更新频道媒体选项（加入频道后调用）。
  Future<int> updateChannelMediaOptions({
    required Map<String, Object?> options,
  }) {
    throw UnimplementedError('updateChannelMediaOptions() has not been implemented.');
  }

  /// 更新 Token。
  Future<int> renewToken({
    required String token,
  }) {
    throw UnimplementedError('renewToken() has not been implemented.');
  }

  /// 设置用户角色与延时级别。
  Future<int> setClientRole({
    required int role,

    /// 1-低延迟 2-超低延迟。
    int? latencyLevel,
  }) {
    throw UnimplementedError('setClientRole() has not been implemented.');
  }

  /// 取消或恢复订阅所有远端音频流。
  Future<int> muteAllRemoteAudioStreams({
    required bool muted,
  }) {
    throw UnimplementedError('muteAllRemoteAudioStreams() has not been implemented.');
  }

  /// 取消或恢复订阅所有远端视频流。
  Future<int> muteAllRemoteVideoStreams({
    required bool muted,
  }) {
    throw UnimplementedError('muteAllRemoteVideoStreams() has not been implemented.');
  }

  /// 取消或恢复订阅指定远端用户音频流。
  Future<int> muteRemoteAudioStream({
    required int uid,
    required bool muted,
  }) {
    throw UnimplementedError('muteRemoteAudioStream() has not been implemented.');
  }

  /// 取消或恢复订阅指定远端用户视频流。
  Future<int> muteRemoteVideoStream({
    required int uid,
    required bool muted,
  }) {
    throw UnimplementedError('muteRemoteVideoStream() has not been implemented.');
  }

  /// 取消或恢复发布本地音频流。
  Future<int> muteLocalAudioStream({
    required bool muted,
  }) {
    throw UnimplementedError('muteLocalAudioStream() has not been implemented.');
  }

  /// 取消或恢复发布本地视频流。
  Future<int> muteLocalVideoStream({
    required bool muted,
  }) {
    throw UnimplementedError('muteLocalVideoStream() has not been implemented.');
  }

  /// 设置订阅的视频流类型。
  Future<int> setRemoteVideoStreamType({
    required int uid,
    required int streamType,
  }) {
    throw UnimplementedError('setRemoteVideoStreamType() has not been implemented.');
  }

  /// 启用或关闭视频模块。
  Future<int> enableVideo({
    /// true-启用 false-关闭。
    required bool enabled,
  }) {
    throw UnimplementedError('enableVideo() has not been implemented.');
  }

  /// 开关本地视频采集。
  Future<int> enableLocalVideo({
    /// true-开启 false-关闭。
    required bool enabled,
  }) {
    throw UnimplementedError('enableLocalVideo() has not been implemented.');
  }

  /// 启动本地视频预览。
  Future<int> startPreview({
    /// 视频源类型（由原生侧映射）。
    int? sourceType,
  }) {
    throw UnimplementedError('startPreview() has not been implemented.');
  }

  /// 停止本地视频预览。
  Future<int> stopPreview({
    /// 视频源类型（由原生侧映射）。
    int? sourceType,
  }) {
    throw UnimplementedError('stopPreview() has not been implemented.');
  }

  /// 对视频截图。
  Future<int> takeSnapshot({
    /// 用户 UID，0 表示本地用户。
    required int uid,

    /// 截图保存路径，需包含文件名与扩展名。
    required String filePath,
  }) {
    throw UnimplementedError('takeSnapshot() has not been implemented.');
  }

  /// 创建录制实例并开始录制。
  Future<int> startRecording({
    /// 录制配置（由原生侧映射）。
    required Map<String, Object?> config,
  }) {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  /// 停止录制并销毁录制实例。
  Future<int> stopRecording() {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }

  /// 统一事件流。
  Stream<AgoraEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }
}
