import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 远端视频视图（Android/iOS/OHOS）。
class AgoraRemoteVideoView extends StatelessWidget {
  const AgoraRemoteVideoView({
    super.key,
    required this.uid,
  });

  /// 远端用户 UID。
  final int uid;

  static const String _viewType = 'plugins.flutter.io/agora_rtc/remote_view';

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _viewType,
        creationParams: <String, Object>{
          'uid': uid,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: <String, Object>{
          'uid': uid,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.ohos) {
      return OhosView(
        viewType: _viewType,
        creationParams: <String, Object>{
          'uid': uid,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (kIsWeb) {
      throw Exception('Unsupported platform');
    }
    throw Exception('Unsupported platform');
  }
}

/// 本地视频视图（Android/iOS/OHOS）。
class AgoraLocalVideoView extends StatelessWidget {
  const AgoraLocalVideoView({
    super.key,
  });

  static const String _viewType = 'plugins.flutter.io/agora_rtc/local_view';

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _viewType,
        creationParams: const <String, Object>{},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: const <String, Object>{},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.ohos) {
      return OhosView(
        viewType: _viewType,
        creationParams: const <String, Object>{},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (kIsWeb) {
      throw Exception('Unsupported platform');
    }
    throw Exception('Unsupported platform');
  }
}
