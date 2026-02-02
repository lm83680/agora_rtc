import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora_rtc/agora_rtc_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAgoraRtc platform = MethodChannelAgoraRtc();
  const MethodChannel channel = MethodChannel('plugins.flutter.io/agora_rtc');
  final List<String> calls = <String>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        calls.add(methodCall.method);
        return null;
      },
    );
  });

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('createEngine', () async {
    await platform.createEngine(appId: 'appId');
    expect(calls, contains('createEngine'));
  });

  test('destroyEngine', () async {
    await platform.destroyEngine();
    expect(calls, contains('destroyEngine'));
  });

  test('setChannelProfile', () async {
    await platform.setChannelProfile(profile: 1);
    expect(calls, contains('setChannelProfile'));
  });

  test('joinChannel', () async {
    await platform.joinChannel(
      token: 'token',
      channelId: 'channel',
      uid: 10,
      options: <String, Object?>{'autoSubscribeAudio': true},
    );
    expect(calls, contains('joinChannel'));
  });

  test('leaveChannel', () async {
    await platform.leaveChannel();
    expect(calls, contains('leaveChannel'));
  });

  test('updateChannelMediaOptions', () async {
    await platform.updateChannelMediaOptions(
      options: <String, Object?>{'publishAudio': true},
    );
    expect(calls, contains('updateChannelMediaOptions'));
  });

  test('renewToken', () async {
    await platform.renewToken(token: 'renew');
    expect(calls, contains('renewToken'));
  });

  test('setClientRole', () async {
    await platform.setClientRole(
      role: 2,
      latencyLevel: 1,
    );
    expect(calls, contains('setClientRole'));
  });

  test('muteAllRemoteAudioStreams', () async {
    await platform.muteAllRemoteAudioStreams(muted: true);
    expect(calls, contains('muteAllRemoteAudioStreams'));
  });

  test('muteAllRemoteVideoStreams', () async {
    await platform.muteAllRemoteVideoStreams(muted: false);
    expect(calls, contains('muteAllRemoteVideoStreams'));
  });

  test('muteRemoteAudioStream', () async {
    await platform.muteRemoteAudioStream(uid: 10, muted: true);
    expect(calls, contains('muteRemoteAudioStream'));
  });

  test('muteRemoteVideoStream', () async {
    await platform.muteRemoteVideoStream(uid: 11, muted: false);
    expect(calls, contains('muteRemoteVideoStream'));
  });

  test('muteLocalAudioStream', () async {
    await platform.muteLocalAudioStream(muted: true);
    expect(calls, contains('muteLocalAudioStream'));
  });

  test('muteLocalVideoStream', () async {
    await platform.muteLocalVideoStream(muted: false);
    expect(calls, contains('muteLocalVideoStream'));
  });

  test('setRemoteVideoStreamType', () async {
    await platform.setRemoteVideoStreamType(uid: 12, streamType: 1);
    expect(calls, contains('setRemoteVideoStreamType'));
  });

  test('enableVideo', () async {
    await platform.enableVideo(enabled: true);
    expect(calls, contains('enableVideo'));
  });

  test('enableLocalVideo', () async {
    await platform.enableLocalVideo(enabled: false);
    expect(calls, contains('enableLocalVideo'));
  });

  test('startPreview', () async {
    await platform.startPreview(sourceType: 2);
    expect(calls, contains('startPreview'));
  });

  test('stopPreview', () async {
    await platform.stopPreview(sourceType: 3);
    expect(calls, contains('stopPreview'));
  });

  test('takeSnapshot', () async {
    await platform.takeSnapshot(uid: 100, filePath: '/tmp/snapshot.png');
    expect(calls, contains('takeSnapshot'));
  });

  test('startRecording', () async {
    await platform.startRecording(config: <String, Object?>{'storagePath': '/tmp/rec.mp4'});
    expect(calls, contains('startRecording'));
  });

  test('stopRecording', () async {
    await platform.stopRecording();
    expect(calls, contains('stopRecording'));
  });
}
