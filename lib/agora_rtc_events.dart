/// 事件类型枚举（仅声明，具体触发由原生端决定）。
enum AgoraEventType {
  /// 自身加入频道成功。
  joinChannelSuccess,

  /// 自身重连成功。
  rejoinChannelSuccess,

  /// 自身离开频道。
  leaveChannel,

  /// 远端用户加入频道。
  userJoined,

  /// 远端用户离开频道。
  userOffline,

  /// 用户角色切换失败。
  clientRoleChangeFailed,

  /// 网络连接状态改变。
  connectionStateChanged,

  /// Token 已过期。
  requestToken,

  /// Token 即将过期。
  tokenPrivilegeWillExpire,

  /// 发生错误。
  error,

  /// 自身音频发布状态改变。
  audioPublishStateChanged,

  /// 远端用户取消或恢复发布视频流。
  userMuteVideo,

  /// 远端视频首帧回调。
  firstRemoteVideoFrame,

  /// 视频截图结果回调。
  snapshotTaken,

  /// 录制状态发生变化回调。
  recorderStateChanged,
}

/// 通用事件载体。
class AgoraEvent {
  const AgoraEvent({
    required this.type,
    required this.data,
  });

  final AgoraEventType type;
  final Object data;
}

/// 加入频道成功回调数据。
class AgoraJoinChannelSuccessEvent {
  const AgoraJoinChannelSuccessEvent({
    required this.channel,
    required this.uid,
    required this.elapsed,
  });

  final String channel;
  final int uid;
  final int elapsed;

  @override
  String toString() {
    return 'AgoraJoinChannelSuccessEvent(channel: $channel, uid: $uid, elapsed: $elapsed)';
  }
}

/// 重新加入频道成功回调数据。
class AgoraRejoinChannelSuccessEvent {
  const AgoraRejoinChannelSuccessEvent({
    required this.channel,
    required this.uid,
    required this.elapsed,
  });

  final String channel;
  final int uid;
  final int elapsed;

  @override
  String toString() {
    return 'AgoraRejoinChannelSuccessEvent(channel: $channel, uid: $uid, elapsed: $elapsed)';
  }
}

/// 离开频道回调数据。
class AgoraLeaveChannelEvent {
  const AgoraLeaveChannelEvent({
    required this.stats,
  });

  /// 原生回调的统计数据原样透传。
  final Map<String, Object?> stats;

  @override
  String toString() {
    return 'AgoraLeaveChannelEvent(stats: $stats)';
  }
}

/// 远端用户加入回调数据。
class AgoraUserJoinedEvent {
  const AgoraUserJoinedEvent({
    required this.uid,
    required this.elapsed,
  });

  final int uid;
  final int elapsed;

  @override
  String toString() {
    return 'AgoraUserJoinedEvent(uid: $uid, elapsed: $elapsed)';
  }
}

/// 远端用户离开回调数据。
class AgoraUserOfflineEvent {
  const AgoraUserOfflineEvent({
    required this.uid,
    required this.reason,
  });

  final int uid;
  final int reason;

  @override
  String toString() {
    return 'AgoraUserOfflineEvent(uid: $uid, reason: $reason)';
  }
}

/// 用户角色切换失败回调数据。
class AgoraClientRoleChangeFailedEvent {
  const AgoraClientRoleChangeFailedEvent({
    required this.reason,
  });

  final int reason;

  @override
  String toString() {
    return 'AgoraClientRoleChangeFailedEvent(reason: $reason)';
  }
}

/// 网络连接状态改变回调数据。
class AgoraConnectionStateChangedEvent {
  const AgoraConnectionStateChangedEvent({
    required this.state,
    required this.reason,
  });

  final int state;
  final int reason;

  @override
  String toString() {
    return 'AgoraConnectionStateChangedEvent(state: $state, reason: $reason)';
  }
}

/// Token 过期回调数据。
class AgoraRequestTokenEvent {
  const AgoraRequestTokenEvent();

  @override
  String toString() {
    return 'AgoraRequestTokenEvent()';
  }
}

/// Token 即将过期回调数据。
class AgoraTokenPrivilegeWillExpireEvent {
  const AgoraTokenPrivilegeWillExpireEvent({
    required this.token,
  });

  final String token;

  @override
  String toString() {
    return 'AgoraTokenPrivilegeWillExpireEvent(token: $token)';
  }
}

/// 错误回调数据。
class AgoraErrorEvent {
  const AgoraErrorEvent({
    required this.error,
    required this.message,
  });

  final int error;
  final String message;

  @override
  String toString() {
    return 'AgoraErrorEvent(error: $error, message: $message)';
  }
}

/// 自身音频发布状态改变回调数据。
class AgoraAudioPublishStateChangedEvent {
  const AgoraAudioPublishStateChangedEvent({
    required this.channel,
    required this.oldState,
    required this.newState,
    required this.elapseSinceLastState,
  });

  final String channel;
  final int oldState;
  final int newState;
  final int elapseSinceLastState;

  @override
  String toString() {
    return 'AgoraAudioPublishStateChangedEvent(channel: $channel, oldState: $oldState, newState: $newState, elapseSinceLastState: $elapseSinceLastState)';
  }
}

/// 远端用户视频流启停回调数据。
class AgoraUserMuteVideoEvent {
  const AgoraUserMuteVideoEvent({
    required this.channelId,
    required this.uid,
    required this.muted,
  });

  /// 频道 ID。
  final String channelId;

  /// 用户 UID。
  final int uid;

  /// 是否停止发送视频流。
  final bool muted;

  @override
  String toString() {
    return 'AgoraUserMuteVideoEvent(channelId: $channelId, uid: $uid, muted: $muted)';
  }
}

/// 远端视频首帧回调数据。
class AgoraFirstRemoteVideoFrameEvent {
  const AgoraFirstRemoteVideoFrameEvent({
    required this.channelId,
    required this.uid,
    required this.width,
    required this.height,
  });

  /// 频道 ID。
  final String channelId;

  /// 用户 UID。
  final int uid;
  final int width;
  final int height;

  @override
  String toString() {
    return 'AgoraFirstRemoteVideoFrameEvent(channelId: $channelId, uid: $uid, width: $width, height: $height)';
  }
}

/// 视频截图结果回调数据。
class AgoraSnapshotTakenEvent {
  const AgoraSnapshotTakenEvent({
    required this.connection,
    required this.uid,
    required this.filePath,
    required this.width,
    required this.height,
    required this.errCode,
  });

  /// 连接信息原样透传。
  final Map<String, Object?> connection;

  /// 用户 UID。
  final int uid;

  /// 截图文件路径。
  final String filePath;
  final int width;
  final int height;
  final int errCode;

  @override
  String toString() {
    return 'AgoraSnapshotTakenEvent(connection: $connection, uid: $uid, filePath: $filePath, width: $width, height: $height, errCode: $errCode)';
  }
}

/// 录制状态发生变化回调数据。
class AgoraRecorderStateChangedEvent {
  const AgoraRecorderStateChangedEvent({
    required this.channelId,
    required this.uid,
    required this.state,
    required this.reason,
  });

  /// 频道名。
  final String channelId;

  /// 用户 ID。
  final int uid;
  final int state;
  final int reason;

  @override
  String toString() {
    return 'AgoraRecorderStateChangedEvent(channelId: $channelId, uid: $uid, state: $state, reason: $reason)';
  }

  /// 提供了一个便捷的方式判断录屏是否完成
  bool get isSuccess => (state == 3 && reason == 0);
}

/// 内部事件解析器。
class AgoraEventParser {
  /// 从原生事件 Map 解析为强类型事件。
  static AgoraEvent? fromMap(Map<dynamic, dynamic> raw) {
    final Object? typeValue = raw['type'];
    if (typeValue is! String) {
      return null;
    }

    switch (typeValue) {
      case 'onJoinChannelSuccess':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.joinChannelSuccess,
          data: AgoraJoinChannelSuccessEvent(
            channel: (dataValue['channel'] as String?) ?? '',
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            elapsed: (dataValue['elapsed'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onRejoinChannelSuccess':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.rejoinChannelSuccess,
          data: AgoraRejoinChannelSuccessEvent(
            channel: (dataValue['channel'] as String?) ?? '',
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            elapsed: (dataValue['elapsed'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onLeaveChannel':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.leaveChannel,
          data: AgoraLeaveChannelEvent(
            stats: Map<String, Object?>.from(dataValue),
          ),
        );
      case 'onUserJoined':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.userJoined,
          data: AgoraUserJoinedEvent(
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            elapsed: (dataValue['elapsed'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onUserOffline':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.userOffline,
          data: AgoraUserOfflineEvent(
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            reason: (dataValue['reason'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onClientRoleChangeFailed':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.clientRoleChangeFailed,
          data: AgoraClientRoleChangeFailedEvent(
            reason: (dataValue['reason'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onConnectionStateChanged':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.connectionStateChanged,
          data: AgoraConnectionStateChangedEvent(
            state: (dataValue['state'] as num?)?.toInt() ?? 0,
            reason: (dataValue['reason'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onRequestToken':
        return const AgoraEvent(
          type: AgoraEventType.requestToken,
          data: AgoraRequestTokenEvent(),
        );
      case 'onTokenPrivilegeWillExpire':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.tokenPrivilegeWillExpire,
          data: AgoraTokenPrivilegeWillExpireEvent(
            token: (dataValue['token'] as String?) ?? '',
          ),
        );
      case 'onError':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.error,
          data: AgoraErrorEvent(
            error: (dataValue['error'] as num?)?.toInt() ?? 0,
            message: (dataValue['message'] as String?) ?? '',
          ),
        );
      case 'onAudioPublishStateChanged':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.audioPublishStateChanged,
          data: AgoraAudioPublishStateChangedEvent(
            channel: (dataValue['channel'] as String?) ?? '',
            oldState: (dataValue['oldState'] as num?)?.toInt() ?? 0,
            newState: (dataValue['newState'] as num?)?.toInt() ?? 0,
            elapseSinceLastState: (dataValue['elapseSinceLastState'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onUserMuteVideo':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.userMuteVideo,
          data: AgoraUserMuteVideoEvent(
            channelId: (dataValue['channelId'] as String?) ?? '',
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            muted: (dataValue['muted'] as bool?) ?? false,
          ),
        );
      case 'onFirstRemoteVideoFrame':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.firstRemoteVideoFrame,
          data: AgoraFirstRemoteVideoFrameEvent(
            channelId: (dataValue['channelId'] as String?) ?? '',
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            width: (dataValue['width'] as num?)?.toInt() ?? 0,
            height: (dataValue['height'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onSnapshotTaken':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.snapshotTaken,
          data: AgoraSnapshotTakenEvent(
            connection: Map<String, Object?>.from(
              (dataValue['connection'] as Map<dynamic, dynamic>?) ?? const <String, Object?>{},
            ),
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            filePath: (dataValue['filePath'] as String?) ?? '',
            width: (dataValue['width'] as num?)?.toInt() ?? 0,
            height: (dataValue['height'] as num?)?.toInt() ?? 0,
            errCode: (dataValue['errCode'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'onRecorderStateChanged':
        final Object? dataValue = raw['data'];
        if (dataValue is! Map<dynamic, dynamic>) {
          return null;
        }
        return AgoraEvent(
          type: AgoraEventType.recorderStateChanged,
          data: AgoraRecorderStateChangedEvent(
            channelId: (dataValue['channelId'] as String?) ?? '',
            uid: (dataValue['uid'] as num?)?.toInt() ?? 0,
            state: (dataValue['state'] as num?)?.toInt() ?? 0,
            reason: (dataValue['reason'] as num?)?.toInt() ?? 0,
          ),
        );
      default:
        return null;
    }
  }
}
