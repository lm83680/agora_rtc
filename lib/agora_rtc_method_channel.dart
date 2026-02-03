import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'agora_rtc_events.dart';
import 'agora_rtc_platform_interface.dart';

class MethodChannelAgoraRtc extends AgoraRtcPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('plugins.flutter.io/agora_rtc');

  final EventChannel _eventChannel = const EventChannel('plugins.flutter.io/agora_rtc/events');
  late final Stream<dynamic> _rawEventStream = _eventChannel.receiveBroadcastStream();
  Stream<AgoraEvent>? _eventStream;

  @override
  Future<int> createEngine({
    required String appId,
  }) async {
    return _invokeInt('createEngine', <String, Object?>{
      'appId': appId,
    });
  }

  @override
  Future<int> destroyEngine() async => _invokeInt('destroyEngine');

  @override
  Future<int> setChannelProfile({
    required int profile,
  }) async {
    return _invokeInt(
      'setChannelProfile',
      <String, Object?>{
        'profile': profile,
      },
    );
  }

  @override
  Future<int> joinChannel({
    required String token,
    required String channelId,

    /// 0 表示由 SDK 分配。
    int uid = 0,

    /// 加入频道选项（由原生侧映射）。
    Map<String, Object?>? options,
  }) async {
    return _invokeInt(
      'joinChannel',
      <String, Object?>{
        'token': token,
        'channelId': channelId,
        'uid': uid,
        'options': options,
      },
    );
  }

  @override
  Future<int> leaveChannel() async => _invokeInt('leaveChannel');

  @override
  Future<int> updateChannelMediaOptions({
    required Map<String, Object?> options,
  }) async {
    return _invokeInt(
      'updateChannelMediaOptions',
      <String, Object?>{
        'options': options,
      },
    );
  }

  @override
  Future<int> renewToken({
    required String token,
  }) async {
    return _invokeInt(
      'renewToken',
      <String, Object?>{
        'token': token,
      },
    );
  }

  @override
  Future<int> setClientRole({
    required int role,

    /// 1-低延迟 2-超低延迟。
    int? latencyLevel,
  }) async {
    return _invokeInt(
      'setClientRole',
      <String, Object?>{
        'role': role,
        'latencyLevel': latencyLevel,
      },
    );
  }

  @override
  Future<int> muteAllRemoteAudioStreams({
    required bool muted,
  }) async {
    return _invokeInt(
      'muteAllRemoteAudioStreams',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<int> muteAllRemoteVideoStreams({
    required bool muted,
  }) async {
    return _invokeInt(
      'muteAllRemoteVideoStreams',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<int> muteRemoteAudioStream({
    required int uid,
    required bool muted,
  }) async {
    return _invokeInt(
      'muteRemoteAudioStream',
      <String, Object?>{
        'uid': uid,
        'muted': muted,
      },
    );
  }

  @override
  Future<int> muteRemoteVideoStream({
    required int uid,
    required bool muted,
  }) async {
    return _invokeInt(
      'muteRemoteVideoStream',
      <String, Object?>{
        'uid': uid,
        'muted': muted,
      },
    );
  }

  @override
  Future<int> muteLocalAudioStream({
    required bool muted,
  }) async {
    return _invokeInt(
      'muteLocalAudioStream',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<int> muteLocalVideoStream({
    required bool muted,
  }) async {
    return _invokeInt(
      'muteLocalVideoStream',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<int> setRemoteVideoStreamType({
    required int uid,
    required int streamType,
  }) async {
    return _invokeInt(
      'setRemoteVideoStreamType',
      <String, Object?>{
        'uid': uid,
        'streamType': streamType,
      },
    );
  }

  @override
  Future<int> enableVideo({
    required bool enabled,
  }) async {
    return _invokeInt(
      'enableVideo',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<int> enableLocalVideo({
    required bool enabled,
  }) async {
    return _invokeInt(
      'enableLocalVideo',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<int> startPreview({
    int? sourceType,
  }) async {
    return _invokeInt(
      'startPreview',
      <String, Object?>{
        'sourceType': sourceType,
      },
    );
  }

  @override
  Future<int> stopPreview({
    int? sourceType,
  }) async {
    return _invokeInt(
      'stopPreview',
      <String, Object?>{
        'sourceType': sourceType,
      },
    );
  }

  @override
  Future<int> takeSnapshot({
    required int uid,
    required String filePath,
  }) async {
    return _invokeInt(
      'takeSnapshot',
      <String, Object?>{
        'uid': uid,
        'filePath': filePath,
      },
    );
  }

  @override
  Future<int> startRecording({
    required Map<String, Object?> config,
  }) async {
    return _invokeInt(
      'startRecording',
      <String, Object?>{
        'config': config,
      },
    );
  }

  @override
  Future<int> stopRecording() async => _invokeInt('stopRecording');

  /// 原生返回值为 int：0 成功，<0 失败。
  Future<int> _invokeInt(String method, [Map<String, Object?>? arguments]) async {
    final int? code = await methodChannel.invokeMethod<int>(method, arguments);
    return code ?? -1;
  }

  @override
  Stream<AgoraEvent> get events {
    _eventStream ??= _rawEventStream.map((dynamic event) => _mapEvent(event)).where((AgoraEvent? event) => event != null).cast<AgoraEvent>();
    return _eventStream!;
  }

  AgoraEvent? _mapEvent(dynamic event) {
    if (event is! Map<dynamic, dynamic>) {
      return null;
    }
    return AgoraEventParser.fromMap(event);
  }
}
