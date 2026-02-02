import 'package:flutter_test/flutter_test.dart';
import 'package:agora_rtc/agora_rtc.dart';
import 'package:agora_rtc/agora_rtc_platform_interface.dart';
import 'package:agora_rtc/agora_rtc_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAgoraRtcPlatform with MockPlatformInterfaceMixin implements AgoraRtcPlatform {
  String? lastAppId;
  int? lastChannelProfile;
  String? lastJoinToken;
  String? lastJoinChannelId;
  int? lastJoinUid;
  Map<String, Object?>? lastJoinOptions;
  int leaveChannelCount = 0;
  Map<String, Object?>? lastMediaOptions;
  String? lastRenewToken;
  int? lastClientRole;
  Map<String, Object?>? lastClientRoleOptions;
  bool? lastMuteAllRemoteAudio;
  bool? lastMuteAllRemoteVideo;
  int? lastMuteRemoteAudioUid;
  bool? lastMuteRemoteAudioMuted;
  int? lastMuteRemoteVideoUid;
  bool? lastMuteRemoteVideoMuted;
  bool? lastMuteLocalAudio;
  bool? lastMuteLocalVideo;
  int? lastRemoteVideoStreamTypeUid;
  int? lastRemoteVideoStreamType;
  bool? lastEnableVideo;
  bool? lastEnableLocalVideo;
  int? lastStartPreviewSourceType;
  int? lastStopPreviewSourceType;
  int? lastSnapshotUid;
  String? lastSnapshotFilePath;
  Map<String, Object?>? lastRecordingConfig;
  int stopRecordingCount = 0;
  int destroyCount = 0;

  @override
  Future<void> createEngine({required String appId}) async {
    lastAppId = appId;
  }

  @override
  Future<void> destroyEngine() async {
    destroyCount += 1;
  }

  @override
  Future<void> setChannelProfile({required int profile}) async {
    lastChannelProfile = profile;
  }

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    int uid = 0,
    Map<String, Object?>? options,
  }) async {
    lastJoinToken = token;
    lastJoinChannelId = channelId;
    lastJoinUid = uid;
    lastJoinOptions = options;
  }

  @override
  Future<void> leaveChannel() async {
    leaveChannelCount += 1;
  }

  @override
  Future<void> updateChannelMediaOptions({required Map<String, Object?> options}) async {
    lastMediaOptions = options;
  }

  @override
  Future<void> renewToken({required String token}) async {
    lastRenewToken = token;
  }

  @override
  Future<void> setClientRole({
    required int role,
    int? latencyLevel,
  }) async {
    lastClientRole = role;
    lastClientRoleOptions = latencyLevel == null ? null : <String, Object?>{'latencyLevel': latencyLevel};
  }

  @override
  Future<void> muteAllRemoteAudioStreams({required bool muted}) async {
    lastMuteAllRemoteAudio = muted;
  }

  @override
  Future<void> muteAllRemoteVideoStreams({required bool muted}) async {
    lastMuteAllRemoteVideo = muted;
  }

  @override
  Future<void> muteRemoteAudioStream({
    required int uid,
    required bool muted,
  }) async {
    lastMuteRemoteAudioUid = uid;
    lastMuteRemoteAudioMuted = muted;
  }

  @override
  Future<void> muteRemoteVideoStream({
    required int uid,
    required bool muted,
  }) async {
    lastMuteRemoteVideoUid = uid;
    lastMuteRemoteVideoMuted = muted;
  }

  @override
  Future<void> muteLocalAudioStream({required bool muted}) async {
    lastMuteLocalAudio = muted;
  }

  @override
  Future<void> muteLocalVideoStream({required bool muted}) async {
    lastMuteLocalVideo = muted;
  }

  @override
  Future<void> setRemoteVideoStreamType({
    required int uid,
    required int streamType,
  }) async {
    lastRemoteVideoStreamTypeUid = uid;
    lastRemoteVideoStreamType = streamType;
  }

  @override
  Future<void> enableVideo({required bool enabled}) async {
    lastEnableVideo = enabled;
  }

  @override
  Future<void> enableLocalVideo({required bool enabled}) async {
    lastEnableLocalVideo = enabled;
  }

  @override
  Future<void> startPreview({int? sourceType}) async {
    lastStartPreviewSourceType = sourceType;
  }

  @override
  Future<void> stopPreview({int? sourceType}) async {
    lastStopPreviewSourceType = sourceType;
  }

  @override
  Future<void> takeSnapshot({
    required int uid,
    required String filePath,
  }) async {
    lastSnapshotUid = uid;
    lastSnapshotFilePath = filePath;
  }

  @override
  Future<void> startRecording({required Map<String, Object?> config}) async {
    lastRecordingConfig = config;
  }

  @override
  Future<void> stopRecording() async {
    stopRecordingCount += 1;
  }

  @override
  Stream<AgoraEvent> get events => const Stream<AgoraEvent>.empty();
}

void main() {
  final AgoraRtcPlatform initialPlatform = AgoraRtcPlatform.instance;

  test('$MethodChannelAgoraRtc is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAgoraRtc>());
  });

  test('controller APIs', () async {
    final AgoraRtcController controller = AgoraRtcController(appId: 'appId');
    MockAgoraRtcPlatform fakePlatform = MockAgoraRtcPlatform();
    AgoraRtcPlatform.instance = fakePlatform;

    await controller.createEngine();
    await controller.setChannelProfile(profile: 1);
    await controller.joinChannel(
      token: 'token',
      channelId: 'channel',
      uid: 10,
      options: <String, Object?>{'autoSubscribeAudio': true},
    );
    await controller.leaveChannel();
    await controller.updateChannelMediaOptions(
      options: <String, Object?>{'publishAudio': true},
    );
    await controller.renewToken(token: 'renew');
    await controller.setClientRole(
      role: 2,
      latencyLevel: 1,
    );
    await controller.muteAllRemoteAudioStreams(muted: true);
    await controller.muteAllRemoteVideoStreams(muted: false);
    await controller.muteRemoteAudioStream(uid: 11, muted: true);
    await controller.muteRemoteVideoStream(uid: 12, muted: false);
    await controller.muteLocalAudioStream(muted: true);
    await controller.muteLocalVideoStream(muted: false);
    await controller.setRemoteVideoStreamType(
      uid: 13,
      streamType: 1,
    );
    await controller.enableVideo(enabled: true);
    await controller.enableLocalVideo(enabled: false);
    await controller.startPreview(sourceType: 2);
    await controller.stopPreview(sourceType: 3);
    await controller.takeSnapshot(uid: 100, filePath: '/tmp/snapshot.png');
    await controller.startRecording(config: <String, Object?>{'storagePath': '/tmp/rec.mp4'});
    await controller.stopRecording();
    await controller.destroyEngine();

    expect(fakePlatform.lastAppId, 'appId');
    expect(fakePlatform.lastChannelProfile, 1);
    expect(fakePlatform.lastJoinToken, 'token');
    expect(fakePlatform.lastJoinChannelId, 'channel');
    expect(fakePlatform.lastJoinUid, 10);
    expect(fakePlatform.lastJoinOptions, <String, Object?>{'autoSubscribeAudio': true});
    expect(fakePlatform.leaveChannelCount, 1);
    expect(fakePlatform.lastMediaOptions, <String, Object?>{'publishAudio': true});
    expect(fakePlatform.lastRenewToken, 'renew');
    expect(fakePlatform.lastClientRole, 2);
    expect(fakePlatform.lastClientRoleOptions, <String, Object?>{'latencyLevel': 1});
    expect(fakePlatform.lastMuteAllRemoteAudio, true);
    expect(fakePlatform.lastMuteAllRemoteVideo, false);
    expect(fakePlatform.lastMuteRemoteAudioUid, 11);
    expect(fakePlatform.lastMuteRemoteAudioMuted, true);
    expect(fakePlatform.lastMuteRemoteVideoUid, 12);
    expect(fakePlatform.lastMuteRemoteVideoMuted, false);
    expect(fakePlatform.lastMuteLocalAudio, true);
    expect(fakePlatform.lastMuteLocalVideo, false);
    expect(fakePlatform.lastRemoteVideoStreamTypeUid, 13);
    expect(fakePlatform.lastRemoteVideoStreamType, 1);
    expect(fakePlatform.lastEnableVideo, true);
    expect(fakePlatform.lastEnableLocalVideo, false);
    expect(fakePlatform.lastStartPreviewSourceType, 2);
    expect(fakePlatform.lastStopPreviewSourceType, 3);
    expect(fakePlatform.lastSnapshotUid, 100);
    expect(fakePlatform.lastSnapshotFilePath, '/tmp/snapshot.png');
    expect(fakePlatform.lastRecordingConfig, <String, Object?>{'storagePath': '/tmp/rec.mp4'});
    expect(fakePlatform.stopRecordingCount, 1);
    expect(fakePlatform.destroyCount, 1);
  });
}
