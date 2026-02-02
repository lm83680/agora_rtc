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
  Future<void> createEngine({
    required String appId,
  }) async {
    await methodChannel.invokeMethod<void>('createEngine', <String, Object?>{
      'appId': appId,
    });
  }

  @override
  Future<void> destroyEngine() async {
    await methodChannel.invokeMethod<void>('destroyEngine');
  }

  @override
  Future<void> setChannelProfile({
    required int profile,
  }) async {
    await methodChannel.invokeMethod<void>(
      'setChannelProfile',
      <String, Object?>{
        'profile': profile,
      },
    );
  }

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,

    /// 0 表示由 SDK 分配。
    int uid = 0,

    /// 加入频道选项（由原生侧映射）。
    Map<String, Object?>? options,
  }) async {
    await methodChannel.invokeMethod<void>(
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
  Future<void> leaveChannel() async {
    await methodChannel.invokeMethod<void>('leaveChannel');
  }

  @override
  Future<void> updateChannelMediaOptions({
    required Map<String, Object?> options,
  }) async {
    await methodChannel.invokeMethod<void>(
      'updateChannelMediaOptions',
      <String, Object?>{
        'options': options,
      },
    );
  }

  @override
  Future<void> renewToken({
    required String token,
  }) async {
    await methodChannel.invokeMethod<void>(
      'renewToken',
      <String, Object?>{
        'token': token,
      },
    );
  }

  @override
  Future<void> setClientRole({
    required int role,

    /// 1-低延迟 2-超低延迟。
    int? latencyLevel,
  }) async {
    await methodChannel.invokeMethod<void>(
      'setClientRole',
      <String, Object?>{
        'role': role,
        'latencyLevel': latencyLevel,
      },
    );
  }

  @override
  Future<void> muteAllRemoteAudioStreams({
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteAllRemoteAudioStreams',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<void> muteAllRemoteVideoStreams({
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteAllRemoteVideoStreams',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<void> muteRemoteAudioStream({
    required int uid,
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteRemoteAudioStream',
      <String, Object?>{
        'uid': uid,
        'muted': muted,
      },
    );
  }

  @override
  Future<void> muteRemoteVideoStream({
    required int uid,
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteRemoteVideoStream',
      <String, Object?>{
        'uid': uid,
        'muted': muted,
      },
    );
  }

  @override
  Future<void> muteLocalAudioStream({
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteLocalAudioStream',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<void> muteLocalVideoStream({
    required bool muted,
  }) async {
    await methodChannel.invokeMethod<void>(
      'muteLocalVideoStream',
      <String, Object?>{
        'muted': muted,
      },
    );
  }

  @override
  Future<void> setRemoteVideoStreamType({
    required int uid,
    required int streamType,
  }) async {
    await methodChannel.invokeMethod<void>(
      'setRemoteVideoStreamType',
      <String, Object?>{
        'uid': uid,
        'streamType': streamType,
      },
    );
  }

  @override
  Future<void> enableVideo({
    required bool enabled,
  }) async {
    await methodChannel.invokeMethod<void>(
      'enableVideo',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<void> enableLocalVideo({
    required bool enabled,
  }) async {
    await methodChannel.invokeMethod<void>(
      'enableLocalVideo',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<void> startPreview({
    int? sourceType,
  }) async {
    await methodChannel.invokeMethod<void>(
      'startPreview',
      <String, Object?>{
        'sourceType': sourceType,
      },
    );
  }

  @override
  Future<void> stopPreview({
    int? sourceType,
  }) async {
    await methodChannel.invokeMethod<void>(
      'stopPreview',
      <String, Object?>{
        'sourceType': sourceType,
      },
    );
  }

  @override
  Future<void> takeSnapshot({
    required int uid,
    required String filePath,
  }) async {
    await methodChannel.invokeMethod<void>(
      'takeSnapshot',
      <String, Object?>{
        'uid': uid,
        'filePath': filePath,
      },
    );
  }

  @override
  Future<void> startRecording({
    required Map<String, Object?> config,
  }) async {
    await methodChannel.invokeMethod<void>(
      'startRecording',
      <String, Object?>{
        'config': config,
      },
    );
  }

  @override
  Future<void> stopRecording() async {
    await methodChannel.invokeMethod<void>('stopRecording');
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
