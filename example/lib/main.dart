import 'dart:async';
import 'dart:io';

import 'package:agora_rtc/agora_rtc.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

const String appId = 'xxx';
const String token = 'xxx'; // fetch from sever
const int broadcastUid = 1; // fetch from sever
const String channelId = 'xxx'; // fetch from sever

const int channelProfileLive = 1;
const int clientRoleBroadcaster = 1;
const int clientRoleAudience = 2;
const int latencyLow = 1;
const int latencyUltra = 2;

Future<bool> ensureMicrophonePermission() async {
  final PermissionStatus status = await Permission.microphone.status;
  if (status.isGranted) {
    return true;
  }
  final PermissionStatus result = await Permission.microphone.request();
  return result.isGranted;
}

Future<String> _snapshotPath() async {
  final Directory baseDir = Directory('${Directory.systemTemp.path}/agora_rtc_example');
  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
  }
  return '${baseDir.path}/agora_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
}

Future<String> _recordPath() async {
  final Directory baseDir = Directory('${Directory.systemTemp.path}/agora_rtc_example');
  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
  }
  return '${baseDir.path}/agora_record_${DateTime.now().millisecondsSinceEpoch}.mp4';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora RTC Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TestPage()),
              );
            },
            child: const Text('方法/回调测试页'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScenarioPage()),
              );
            },
            child: const Text('场景页'),
          ),
        ],
      ),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final AgoraRtcController _controller = AgoraRtcController(appId: appId);
  final List<String> _logs = [];
  StreamSubscription<AgoraEvent>? _subscription;

  bool _remoteAudioMuted = false;
  bool _remoteVideoMuted = false;
  bool _localAudioMuted = false;
  bool _localVideoMuted = false;
  bool _videoEnabled = true;
  bool _localVideoEnabled = true;
  bool _micPublishing = false;

  @override
  void initState() {
    super.initState();
    _subscription = _controller.events.listen((event) {
      _appendLog('CALLBACK: ${event.data.toString()}');
    }, onError: (Object error) {
      _appendLog('CALLBACK_ERROR: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _appendLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String()}] $message');
      if (_logs.length > 200) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _runAction(String name, Future<int?> Function() action) async {
    _appendLog('ACTION: $name');
    try {
      final int? code = await action();
      _appendLog('ACTION RESULT: $name -> ${code ?? 'null'}');
    } catch (e) {
      _appendLog('ERROR: $name -> $e');
    }
  }

  Map<String, Object?> _defaultOptions() {
    return <String, Object?>{
      'publishCameraTrack': false,
      'publishMicrophoneTrack': _micPublishing,
      'autoSubscribeAudio': true,
      'autoSubscribeVideo': true,
      'audienceLatencyLevel': _micPublishing ? latencyUltra : latencyLow,
      'channelProfile': channelProfileLive,
      'clientRoleType': _micPublishing ? clientRoleBroadcaster : clientRoleAudience,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('方法/回调测试页'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
            child: const Text('清空日志'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildButton('createEngine', () => _controller.createEngine()),
                    _buildButton('destroyEngine', () => _controller.destroyEngine()),
                    _buildButton(
                      'setChannelProfile',
                      () => _controller.setChannelProfile(profile: channelProfileLive),
                    ),
                    _buildButton(
                      'joinChannel',
                      () => _controller.joinChannel(
                        token: token,
                        channelId: channelId,
                        options: _defaultOptions(),
                      ),
                    ),
                    _buildButton('leaveChannel', () => _controller.leaveChannel()),
                    _buildButton(
                      _micPublishing ? 'updateChannelMediaOptions(下麦)' : 'updateChannelMediaOptions(上麦)',
                      () async {
                        final bool granted = await ensureMicrophonePermission();
                        if (!granted) {
                          _appendLog('麦克风权限未授予，无法上麦');
                          return -1;
                        }
                        _micPublishing = !_micPublishing;
                        setState(() {});
                        return await _controller.updateChannelMediaOptions(
                          options: _defaultOptions(),
                        );
                      },
                    ),
                    _buildButton('renewToken', () => _controller.renewToken(token: token)),
                    _buildButton(
                      'setClientRole(观众)',
                      () => _controller.setClientRole(role: clientRoleAudience, latencyLevel: latencyLow),
                    ),
                    _buildButton(
                      'setClientRole(主播)',
                      () => _controller.setClientRole(role: clientRoleBroadcaster, latencyLevel: latencyUltra),
                    ),
                    _buildButton(
                      _remoteAudioMuted ? 'muteAllRemoteAudio(false)' : 'muteAllRemoteAudio(true)',
                      () async {
                        _remoteAudioMuted = !_remoteAudioMuted;
                        setState(() {});
                        return await _controller.muteAllRemoteAudioStreams(muted: _remoteAudioMuted);
                      },
                    ),
                    _buildButton(
                      _remoteVideoMuted ? 'muteAllRemoteVideo(false)' : 'muteAllRemoteVideo(true)',
                      () async {
                        _remoteVideoMuted = !_remoteVideoMuted;
                        setState(() {});
                        return await _controller.muteAllRemoteVideoStreams(muted: _remoteVideoMuted);
                      },
                    ),
                    _buildButton(
                      'muteRemoteAudioStream',
                      () => _controller.muteRemoteAudioStream(uid: broadcastUid, muted: true),
                    ),
                    _buildButton(
                      'muteRemoteVideoStream',
                      () => _controller.muteRemoteVideoStream(uid: broadcastUid, muted: true),
                    ),
                    _buildButton(
                      _localAudioMuted ? 'muteLocalAudio(false)' : 'muteLocalAudio(true)',
                      () async {
                        _localAudioMuted = !_localAudioMuted;
                        setState(() {});
                        return await _controller.muteLocalAudioStream(muted: _localAudioMuted);
                      },
                    ),
                    _buildButton(
                      _localVideoMuted ? 'muteLocalVideo(false)' : 'muteLocalVideo(true)',
                      () async {
                        _localVideoMuted = !_localVideoMuted;
                        setState(() {});
                        return await _controller.muteLocalVideoStream(muted: _localVideoMuted);
                      },
                    ),
                    _buildButton(
                      'setRemoteVideoStreamType',
                      () => _controller.setRemoteVideoStreamType(uid: broadcastUid, streamType: 0),
                    ),
                    _buildButton(
                      _videoEnabled ? 'enableVideo(false)' : 'enableVideo(true)',
                      () async {
                        _videoEnabled = !_videoEnabled;
                        setState(() {});
                        return await _controller.enableVideo(enabled: _videoEnabled);
                      },
                    ),
                    _buildButton(
                      _localVideoEnabled ? 'enableLocalVideo(false)' : 'enableLocalVideo(true)',
                      () async {
                        _localVideoEnabled = !_localVideoEnabled;
                        setState(() {});
                        return await _controller.enableLocalVideo(enabled: _localVideoEnabled);
                      },
                    ),
                    _buildButton('startPreview', () => _controller.startPreview()),
                    _buildButton('stopPreview', () => _controller.stopPreview()),
                    _buildButton(
                      'takeSnapshot',
                      () async {
                        final String path = await _snapshotPath();
                        return await _controller.takeSnapshot(uid: broadcastUid, filePath: path);
                      },
                    ),
                    _buildButton(
                      'startRecording',
                      () async {
                        final String path = await _recordPath();
                        return _controller.startRecording(
                          config: <String, Object?>{
                            'channelId': channelId,
                            'uid': broadcastUid,
                            'storagePath': path,
                          },
                        );
                      },
                    ),
                    _buildButton('stopRecording', () => _controller.stopRecording()),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: ListView.builder(
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Future<int?> Function() action) {
    return ElevatedButton(
      onPressed: () => _runAction(label, action),
      child: Text(label),
    );
  }
}

class ScenarioPage extends StatefulWidget {
  const ScenarioPage({super.key});

  @override
  State<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends State<ScenarioPage> {
  final AgoraRtcController _controller = AgoraRtcController(appId: appId);
  StreamSubscription<AgoraEvent>? _subscription;

  bool _loading = true;
  bool _remoteAudioMuted = false;
  bool _micOn = false;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _subscription = _controller.events.listen((event) {
      debugPrint("RTC events callback:${event.data.toString()}");
      if (event.type == AgoraEventType.firstRemoteVideoFrame) {
        setState(() {
          _loading = false;
        });
      }
    }, onError: (Object error) {
      debugPrint('回调错误 $error');
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _controller.createEngine();
      await _controller.enableVideo(enabled: true);
      await _controller.joinChannel(
        token: token,
        channelId: channelId,
        options: <String, Object?>{
          'publishCameraTrack': false,
          'publishMicrophoneTrack': false,
          'autoSubscribeAudio': true,
          'autoSubscribeVideo': true,
          'audienceLatencyLevel': latencyLow,
          'channelProfile': channelProfileLive,
          'clientRoleType': clientRoleAudience,
        },
      );
    } catch (e) {
      debugPrint('回调错误 $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.leaveChannel();
    _controller.destroyEngine();
    super.dispose();
  }

  Future<void> _toggleRemoteAudio() async {
    try {
      _remoteAudioMuted = !_remoteAudioMuted;
      setState(() {});
      await _controller.muteAllRemoteAudioStreams(muted: _remoteAudioMuted);
    } catch (e) {
      debugPrint('静音失败 $e');
    }
  }

  Future<void> _toggleMic() async {
    try {
      final bool granted = await ensureMicrophonePermission();
      if (!granted) {
        debugPrint('麦克风权限未授予');
        return;
      }
      _micOn = !_micOn;
      setState(() {});
      await _controller.updateChannelMediaOptions(
        options: <String, Object?>{
          'publishCameraTrack': false,
          'publishMicrophoneTrack': _micOn,
          'autoSubscribeAudio': true,
          'autoSubscribeVideo': true,
          'audienceLatencyLevel': _micOn ? latencyUltra : latencyLow,
          'channelProfile': channelProfileLive,
          'clientRoleType': _micOn ? clientRoleBroadcaster : clientRoleAudience,
        },
      );
    } catch (e) {
      debugPrint('麦克风切换失败 $e');
    }
  }

  Future<void> _takeSnapshot() async {
    try {
      final String path = await _snapshotPath();
      await _controller.takeSnapshot(uid: broadcastUid, filePath: path);
    } catch (e) {
      debugPrint('截图失败 $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      try {
        await _controller.stopRecording();
        setState(() {
          _recording = false;
          debugPrint('停止录屏');
        });
      } catch (e) {
        debugPrint('停止失败 $e');
      }
      return;
    }
    try {
      final String path = await _recordPath();
      await _controller.startRecording(
        config: <String, Object?>{
          'channelId': channelId,
          'uid': broadcastUid,
          'storagePath': path,
        },
      );
      setState(() {
        _recording = true;
        debugPrint('开始录屏 $path');
      });
    } catch (e) {
      debugPrint('开始失败 $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程摄像头'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AgoraRemoteVideoView(uid: broadcastUid),
                    ),
                    if (_loading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _loading ? '连接中' : '在线',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '频道：$channelId  UID：$broadcastUid',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleRemoteAudio,
                    child: Text(_remoteAudioMuted ? '解除静音' : '静音'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleMic,
                    child: Text(_micOn ? '关闭麦克风' : '打开麦克风'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _takeSnapshot,
                    child: const Text('截图'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleRecording,
                    child: Text(_recording ? '停止录制' : '开始录制'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
