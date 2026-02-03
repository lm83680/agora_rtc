import {
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import common from '@ohos.app.ability.common';
import { AgoraRtcEngineHolder } from './AgoraRtcEngineHolder';
import { AgoraRtcEngineActions } from './AgoraRtcEngineActions';
import { AgoraLocalVideoViewFactory, AgoraRemoteVideoViewFactory } from './AgoraRtcEngineViews';

// ===============================
// Plugin 实现
// ===============================
export default class AgoraRtcEnginePlugin implements FlutterPlugin, MethodCallHandler, StreamHandler {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private applicationContext: common.Context | null = null;
  private engineHolder: AgoraRtcEngineHolder = new AgoraRtcEngineHolder();
  private actions: AgoraRtcEngineActions = new AgoraRtcEngineActions(this.engineHolder);

  constructor() {
  }

  getUniqueClassName(): string {
    return "AgoraRtcEnginePlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "plugins.flutter.io/agora_rtc");
    this.channel.setMethodCallHandler(this)
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), "plugins.flutter.io/agora_rtc/events");
    this.eventChannel.setStreamHandler(this)
    const platformViewRegistry = binding.getPlatformViewRegistry();
    platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/local_view",
      new AgoraLocalVideoViewFactory(this.engineHolder, StandardMessageCodec.INSTANCE),
    );
    platformViewRegistry.registerViewFactory(
      "plugins.flutter.io/agora_rtc/remote_view",
      new AgoraRemoteVideoViewFactory(this.engineHolder, StandardMessageCodec.INSTANCE),
    );
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    if (this.eventChannel != null) {
      // ArkTS 不允许传入 null，这里只清理引用。
    }
    this.applicationContext = null;
    this.engineHolder.clear();
    this.actions.setEventSink(null);
    this.actions.clearRuntimeState();
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "createEngine") {
      this.actions.handleCreateEngine(call, result, this.applicationContext)
    } else if(call.method == "destroyEngine") {
      this.actions.handleDestroyEngine(result)
    } else if (call.method == "joinChannel") {
      this.actions.handleJoinChannel(call, result)
    } else if (call.method == "leaveChannel") {
      this.actions.handleLeaveChannel(result)
    } else if (call.method == "updateChannelMediaOptions") {
      this.actions.handleUpdateChannelMediaOptions(call, result)
    } else if (call.method == "setClientRole") {
      this.actions.handleSetClientRole(call, result)
    } else if (call.method == "muteAllRemoteAudioStreams") {
      this.actions.handleMuteAllRemoteAudioStreams(call, result)
    } else if (call.method == "setChannelProfile") {
      this.actions.handleSetChannelProfile(call, result)
    } else if (call.method == "renewToken") {
      this.actions.handleRenewToken(call, result)
    } else if (call.method == "muteAllRemoteVideoStreams") {
      this.actions.handleMuteAllRemoteVideoStreams(call, result)
    } else if (call.method == "muteRemoteAudioStream") {
      this.actions.handleMuteRemoteAudioStream(call, result)
    } else if (call.method == "muteRemoteVideoStream") {
      this.actions.handleMuteRemoteVideoStream(call, result)
    } else if (call.method == "muteLocalAudioStream") {
      this.actions.handleMuteLocalAudioStream(call, result)
    } else if (call.method == "muteLocalVideoStream") {
      this.actions.handleMuteLocalVideoStream(call, result)
    } else if (call.method == "setRemoteVideoStreamType") {
      this.actions.handleSetRemoteVideoStreamType(call, result)
    } else if (call.method == "enableVideo") {
      this.actions.handleEnableVideo(call, result)
    } else if (call.method == "enableLocalVideo") {
      this.actions.handleEnableLocalVideo(call, result)
    } else if (call.method == "startPreview") {
      this.actions.handleStartPreview(call, result)
    } else if (call.method == "stopPreview") {
      this.actions.handleStopPreview(call, result)
    } else if (call.method == "takeSnapshot") {
      this.actions.handleTakeSnapshot(call, result)
    } else if (call.method == "startRecording") {
      this.actions.handleStartRecording(call, result)
    } else if (call.method == "stopRecording") {
      this.actions.handleStopRecording(result)
    } else {
      result.notImplemented()
    }
  }

  onListen(args: Object, events: EventSink): void {
    this.actions.setEventSink(events);
  }

  onCancel(args: Object): void {
    this.actions.setEventSink(null);
  }
}
