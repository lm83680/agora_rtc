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
import type MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec'
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import common from '@ohos.app.ability.common';
import {
  Constants,
  ChannelMediaOptions,
  ClientRoleOptions,
  RtcEngine,
  RtcEngineConfig,
  IRtcEngineEventHandler,
  AgoraMediaRecorder,
  IMediaRecorderCallback,
  MediaRecorderConfiguration,
  RecorderStreamInfo,
  VideoCanvas,
} from '@shengwang/rtc-full';

// ===============================
// 类型与工具方法
// ===============================
type EventValue = Object | number | string | boolean | null;
type EventMap = Map<string, EventValue>;
type ArgsMap = Map<string, Object>;

class EventPayload {
  type: string;
  data: Record<string, Object>;

  constructor(type: string, data: Record<string, Object>) {
    this.type = type;
    this.data = data;
  }
}

function getArg(argsMap: ArgsMap | undefined, key: string): Object | undefined {
  return argsMap?.get(key) as Object;
}

function mapValueToObject(value: Object): Object {
  if (value instanceof Map) {
    return mapToRecord(value as Map<string, Object>);
  }
  return value;
}

function mapToRecord(map: Map<string, Object>): Record<string, Object> {
  let record: Record<string, Object> = {};
  for (let entry of map.entries()) {
    record[entry[0]] = mapValueToObject(entry[1]);
  }
  return record;
}

function eventDataToRecord(data: EventMap): Record<string, Object> {
  let record: Record<string, Object> = {};
  for (let entry of data.entries()) {
    record[entry[0]] = mapValueToObject(entry[1] as Object);
  }
  return record;
}

function toRecord(value: Object | undefined): Record<string, Object> | undefined {
  if (value == null) {
    return undefined;
  }
  if (value instanceof Map) {
    return mapToRecord(value as Map<string, Object>);
  }
  return value as Record<string, Object>;
}

// ===============================
// Plugin 实现
// ===============================
export default class AgoraRtcEnginePlugin implements FlutterPlugin, MethodCallHandler, StreamHandler {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private applicationContext: common.Context | null = null;
  private engineHolder: AgoraRtcEngineHolder = new AgoraRtcEngineHolder();
  private remoteVideoFirstFrameUids: Set<number> = new Set<number>();
  private mediaRecorder: AgoraMediaRecorder | null = null;
  private recorderChannelId: string = "";
  private recorderUid: number = 0;
  private mediaRecorderCallback: IMediaRecorderCallback = {
    onRecorderStateChanged: (channelId: string, uid: number, state: number, reason: number) => {
      this.emitEventWithData("onRecorderStateChanged", (data: EventMap) => {
        data.set("channelId", channelId);
        data.set("uid", uid);
        data.set("state", state);
        data.set("reason", reason);
      });
    },
    onRecorderInfoUpdated: (channelId: string, uid: number, info) => {
    },
  };
  private eventHandler: IRtcEngineEventHandler = {
    onJoinChannelSuccess: (channel: string, uid: number, elapsed: number) => {
      this.emitEventWithData("onJoinChannelSuccess", (data: EventMap) => {
        data.set("channel", channel);
        data.set("uid", uid);
        data.set("elapsed", elapsed);
      });
    },
    onRejoinChannelSuccess: (channel: string, uid: number, elapsed: number) => {
      this.emitEventWithData("onRejoinChannelSuccess", (data: EventMap) => {
        data.set("channel", channel);
        data.set("uid", uid);
        data.set("elapsed", elapsed);
      });
    },
    onLeaveChannel: () => {
      this.emitEvent("onLeaveChannel", new Map());
    },
    onUserJoined: (uid: number, elapse: number) => {
      this.emitEventWithData("onUserJoined", (data: EventMap) => {
        data.set("uid", uid);
        data.set("elapsed", elapse);
      });
    },
    onUserOffline: (uid: number, reason: number) => {
      this.emitEventWithData("onUserOffline", (data: EventMap) => {
        data.set("uid", uid);
        data.set("reason", reason);
      });
    },
    onRemoteVideoStats: (stats) => {
      const uid = stats?.uid ?? 0;
      if (uid == 0) {
        return;
      }
      if (this.remoteVideoFirstFrameUids.has(uid)) {
        return;
      }
      this.remoteVideoFirstFrameUids.add(uid);
      this.emitEventWithData("onFirstRemoteVideoFrame", (data: EventMap) => {
        data.set("uid", uid);
        data.set("channelId", "self");
        data.set("width", stats?.width ?? 0);
        data.set("height", stats?.height ?? 0);
      });
    },
    onClientRoleChangeFailed: (reason: number, currentRole) => {
      this.emitEventWithData("onClientRoleChangeFailed", (data: EventMap) => {
        data.set("reason", reason);
      });
    },
    onConnectionStateChanged: (state, reason) => {
      this.emitEventWithData("onConnectionStateChanged", (data: EventMap) => {
        data.set("state", state);
        data.set("reason", reason);
      });
    },
    onRequestToken: () => {
      this.emitEvent("onRequestToken", new Map());
    },
    onTokenPrivilegeWillExpire: (token: string) => {
      this.emitEventWithData("onTokenPrivilegeWillExpire", (data: EventMap) => {
        data.set("token", token);
      });
    },
    onError: (err, message) => {
      this.emitEventWithData("onError", (data: EventMap) => {
        data.set("error", err);
        data.set("message", message);
      });
    },
    onAudioPublishStateChanged: (channel, oldState, newState, elapseSinceLastState) => {
      this.emitEventWithData("onAudioPublishStateChanged", (data: EventMap) => {
        data.set("channel", channel);
        data.set("oldState", oldState);
        data.set("newState", newState);
        data.set("elapseSinceLastState", elapseSinceLastState);
      });
    },
    onUserMuteVideo: (uid: number, muted: boolean) => {
      this.emitEventWithData("onUserMuteVideo", (data: EventMap) => {
        data.set("channelId", "self");
        data.set("uid", uid);
        data.set("muted", muted);
      });
    },
    onSnapshotTaken: (uid: number, filePath: string, width: number, height: number, errCode: number) => {
      this.emitEventWithData("onSnapshotTaken", (data: EventMap) => {
        data.set("connection", new Map());
        data.set("uid", uid);
        data.set("filePath", filePath);
        data.set("width", width);
        data.set("height", height);
        data.set("errCode", errCode);
      });
    },
  };

  constructor() {
  }

  private emitEventWithData(eventName: string, builder: (data: EventMap) => void): void {
    const data: EventMap = new Map();
    builder(data);
    this.emitEvent(eventName, data);
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
    this.eventSink = null;
    this.applicationContext = null;
    this.engineHolder.clear();
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "createEngine") {
      this.handleCreateEngine(call, result)
    } else if(call.method == "destroyEngine") {
      this.handleDestroyEngine(result)
    } else if (call.method == "joinChannel") {
      this.handleJoinChannel(call, result)
    } else if (call.method == "leaveChannel") {
      this.handleLeaveChannel(result)
    } else if (call.method == "updateChannelMediaOptions") {
      this.handleUpdateChannelMediaOptions(call, result)
    } else if (call.method == "setClientRole") {
      this.handleSetClientRole(call, result)
    } else if (call.method == "muteAllRemoteAudioStreams") {
      this.handleMuteAllRemoteAudioStreams(call, result)
    } else if (call.method == "setChannelProfile") {
      this.handleSetChannelProfile(call, result)
    } else if (call.method == "renewToken") {
      this.handleRenewToken(call, result)
    } else if (call.method == "muteAllRemoteVideoStreams") {
      this.handleMuteAllRemoteVideoStreams(call, result)
    } else if (call.method == "muteRemoteAudioStream") {
      this.handleMuteRemoteAudioStream(call, result)
    } else if (call.method == "muteRemoteVideoStream") {
      this.handleMuteRemoteVideoStream(call, result)
    } else if (call.method == "muteLocalAudioStream") {
      this.handleMuteLocalAudioStream(call, result)
    } else if (call.method == "muteLocalVideoStream") {
      this.handleMuteLocalVideoStream(call, result)
    } else if (call.method == "setRemoteVideoStreamType") {
      this.handleSetRemoteVideoStreamType(call, result)
    } else if (call.method == "enableVideo") {
      this.handleEnableVideo(call, result)
    } else if (call.method == "enableLocalVideo") {
      this.handleEnableLocalVideo(call, result)
    } else if (call.method == "startPreview") {
      this.handleStartPreview(call, result)
    } else if (call.method == "stopPreview") {
      this.handleStopPreview(call, result)
    } else if (call.method == "takeSnapshot") {
      this.handleTakeSnapshot(call, result)
    } else if (call.method == "startRecording") {
      this.handleStartRecording(call, result)
    } else if (call.method == "stopRecording") {
      this.handleStopRecording(result)
    } else {
      result.notImplemented()
    }
  }

  onListen(args: Object, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: Object): void {
    this.eventSink = null;
  }

  private handleCreateEngine(call: MethodCall, result: MethodResult): void {
    console.log("handleCreateEngine called");
    if (this.engineHolder.rtcEngine != null) {
      result.error("ENGINE_EXISTS", "RtcEngine 已初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let appId = getArg(argsMap, "appId") as string | undefined;
    if (!appId) {
      result.error("INVALID_ARGS", "appId 为空", null)
      return
    }
    if (this.applicationContext == null) {
      result.error("NO_CONTEXT", "applicationContext 为空", null)
      return
    }
    let config: RtcEngineConfig = new RtcEngineConfig();
    config.mContext = this.applicationContext;
    config.mAppId = appId;
    config.mEventHandler = this.eventHandler;
    this.engineHolder.rtcEngine = RtcEngine.create(config);
    this.engineHolder.bindAllVideoIfReady();
    this.remoteVideoFirstFrameUids.clear();
    this.mediaRecorder = null;
    result.success(null)
  }

  private handleDestroyEngine(result: MethodResult): void {
    if (this.engineHolder.rtcEngine != null) {
      RtcEngine.destroy();
      this.engineHolder.clear();
      this.remoteVideoFirstFrameUids.clear();
      this.mediaRecorder = null;
    }
    result.success(null)
  }

  private handleJoinChannel(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let token = (getArg(argsMap, "token") as string | undefined) ?? "";
    let channelId = getArg(argsMap, "channelId") as string | undefined;
    if (!channelId) {
      result.error("INVALID_ARGS", "channelId 为空", null)
      return
    }
    let uid = (getArg(argsMap, "uid") as number | undefined) ?? 0;
    let optionsMap = toRecord(getArg(argsMap, "options"));
    let options = this.buildChannelMediaOptions(optionsMap);
    engine.joinChannelWithOptions(token, channelId, uid, options);
    result.success(null)
  }

  private handleLeaveChannel(result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    engine.leaveChannel();
    this.remoteVideoFirstFrameUids.clear();
    result.success(null)
  }

  private handleUpdateChannelMediaOptions(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let optionsMap = toRecord(getArg(argsMap, "options"));
    if (optionsMap == null) {
      result.error("INVALID_ARGS", "options 为空", null)
      return
    }
    let options = this.buildChannelMediaOptions(optionsMap);
    engine.updateChannelMediaOptions(options);
    result.success(null)
  }

  private handleSetChannelProfile(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let profile = getArg(argsMap, "profile") as number | undefined;
    if (profile == null) {
      result.error("INVALID_ARGS", "profile 为空", null)
      return
    }
    engine.setChannelProfile(profile);
    result.success(null)
  }

  private handleRenewToken(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let token = getArg(argsMap, "token") as string | undefined;
    if (!token) {
      result.error("INVALID_ARGS", "token 为空", null)
      return
    }
    engine.renewToken(token);
    result.success(null)
  }

  private handleSetClientRole(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let role = getArg(argsMap, "role") as number | undefined;
    if (role == null) {
      result.error("INVALID_ARGS", "role 为空", null)
      return
    }
    let latencyLevel = getArg(argsMap, "latencyLevel") as number | undefined;
    if (latencyLevel == null) {
      engine.setClientRole(role);
      result.success(null)
      return
    }
    let options = new ClientRoleOptions();
    options.audienceLatencyLevel =
      latencyLevel == 2
        ? Constants.AudienceLatencyLevel.ULTRA_LOW_LATENCY
        : Constants.AudienceLatencyLevel.LOW_LATENCY;
    engine.setClientRole(role, options);
    result.success(null)
  }

  private handleMuteAllRemoteAudioStreams(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    engine.muteAllRemoteAudioStreams(muted);
    result.success(null)
  }

  private handleMuteAllRemoteVideoStreams(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    engine.muteAllRemoteVideoStreams(muted);
    result.success(null)
  }

  private handleMuteRemoteAudioStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    engine.muteRemoteAudioStream(uid, muted);
    result.success(null)
  }

  private handleMuteRemoteVideoStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    engine.muteRemoteVideoStream(uid, muted);
    result.success(null)
  }

  private handleMuteLocalAudioStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    engine.muteLocalAudioStream(muted);
    result.success(null)
  }

  private handleMuteLocalVideoStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    engine.muteLocalVideoStream(muted);
    result.success(null)
  }

  private handleSetRemoteVideoStreamType(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let streamType = getArg(argsMap, "streamType") as number | undefined;
    if (uid == null || streamType == null) {
      result.error("INVALID_ARGS", "uid 或 streamType 为空", null)
      return
    }
    engine.setRemoteVideoStreamType(uid, streamType);
    result.success(null)
  }

  private handleEnableVideo(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let enabled = getArg(argsMap, "enabled") as boolean | undefined;
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    if (enabled) {
      engine.enableVideo();
    } else {
      engine.disableVideo();
    }
    result.success(null)
  }

  private handleEnableLocalVideo(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let enabled = getArg(argsMap, "enabled") as boolean | undefined;
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    engine.enableLocalVideo(enabled);
    result.success(null)
  }

  private handleStartPreview(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let sourceType = getArg(argsMap, "sourceType") as number | undefined;
    if (sourceType == null) {
      engine.startPreview();
    } else {
      engine.startPreview(sourceType);
    }
    result.success(null)
  }

  private handleStopPreview(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let sourceType = getArg(argsMap, "sourceType") as number | undefined;
    if (sourceType == null) {
      engine.stopPreview();
    } else {
      engine.stopPreview(sourceType);
    }
    result.success(null)
  }

  private handleTakeSnapshot(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let filePath = getArg(argsMap, "filePath") as string | undefined;
    if (uid == null || !filePath) {
      result.error("INVALID_ARGS", "uid 或 filePath 为空", null)
      return
    }
    engine.takeSnapshot(uid, filePath);
    result.success(null)
  }

  private handleStartRecording(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    let argsMap = call.args as ArgsMap | undefined;
    let config = toRecord(getArg(argsMap, "config"));
    if (config == null) {
      result.error("INVALID_ARGS", "config 为空", null)
      return
    }
    let channelId = (config["channelId"] as string | undefined) ?? "";
    let uid = (config["uid"] as number | undefined) ?? 0;
    let storagePath = config["storagePath"] as string | undefined;
    if (!storagePath) {
      result.error("INVALID_ARGS", "storagePath 为空", null)
      return
    }
    let containerFormat = (config["containerFormat"] as number | undefined) ?? AgoraMediaRecorder.CONTAINER_MP4;
    let streamType = (config["streamType"] as number | undefined) ?? AgoraMediaRecorder.STREAM_TYPE_BOTH;
    let maxDurationMs = (config["maxDurationMs"] as number | undefined) ?? 120000;
    let recorderInfoUpdateInterval = (config["recorderInfoUpdateInterval"] as number | undefined) ?? 0;
    this.recorderChannelId = channelId;
    this.recorderUid = uid;
    if (this.mediaRecorder == null) {
      let info = new RecorderStreamInfo();
      info.channelId = channelId;
      info.uid = uid;
      this.mediaRecorder = engine.createMediaRecorder(info);
      this.mediaRecorder.setMediaRecorderObserver(this.mediaRecorderCallback);
    }
    let recorderConfig = new MediaRecorderConfiguration(
      storagePath,
      containerFormat,
      streamType,
      maxDurationMs,
      recorderInfoUpdateInterval,
    );
    this.mediaRecorder?.startRecording(recorderConfig);
    result.success(null)
  }

  private handleStopRecording(result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    if (this.mediaRecorder != null) {
      this.mediaRecorder.stopRecording();
      this.mediaRecorder.release();
      engine.destroyMediaRecorder(this.mediaRecorder);
      this.mediaRecorder = null;
    }
    result.success(null)
  }

  private emitEvent(type: string, data: EventMap): void {
    if (this.eventSink == null) {
      return
    }
    let payload = new EventPayload(type, eventDataToRecord(data));
    this.eventSink.success(payload);
  }

  private buildChannelMediaOptions(optionsMap?: Record<string, Object>): ChannelMediaOptions {
    let options = new ChannelMediaOptions();
    if (optionsMap == null) {
      return options;
    }
    let publishCameraTrack = optionsMap["publishCameraTrack"] as boolean | undefined;
    if (publishCameraTrack != null) {
      options.publishCameraTrack = publishCameraTrack;
    }
    let publishMicrophoneTrack = optionsMap["publishMicrophoneTrack"] as boolean | undefined;
    if (publishMicrophoneTrack != null) {
      options.publishMicrophoneTrack = publishMicrophoneTrack;
    }
    let autoSubscribeAudio = optionsMap["autoSubscribeAudio"] as boolean | undefined;
    if (autoSubscribeAudio != null) {
      options.autoSubscribeAudio = autoSubscribeAudio;
    }
    let autoSubscribeVideo = optionsMap["autoSubscribeVideo"] as boolean | undefined;
    if (autoSubscribeVideo != null) {
      options.autoSubscribeVideo = autoSubscribeVideo;
    }
    let audienceLatencyLevel = optionsMap["audienceLatencyLevel"] as number | undefined;
    if (audienceLatencyLevel != null) {
      options.audienceLatencyLevel = audienceLatencyLevel;
    }
    let channelProfile = optionsMap["channelProfile"] as number | undefined;
    if (channelProfile != null) {
      options.channelProfile = channelProfile;
    }
    let clientRoleType = optionsMap["clientRoleType"] as number | undefined;
    if (clientRoleType != null) {
      options.clientRoleType = clientRoleType;
    }
    return options;
  }
}

// ===============================
// PlatformView 组件与 Builder
// ===============================
@Component
struct AgoraLocalVideoViewComponent {
  @Prop params: Params;
  platformView: AgoraLocalVideoPlatformView = this.params.platformView as AgoraLocalVideoPlatformView;
  xComponentController: XComponentController = new XComponentController();

  build() {
    Stack() {
      XComponent({
        id: this.platformView.getViewId(),
        type: XComponentType.SURFACE,
        libraryname: Constants.AGORA_LIB_NAME,
      })
        .onLoad(() => {
          this.platformView.setSurfaceId(this.xComponentController.getXComponentSurfaceId());
          this.platformView.onViewLoaded();
        })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct AgoraRemoteVideoViewComponent {
  @Prop params: Params;
  platformView: AgoraRemoteVideoPlatformView = this.params.platformView as AgoraRemoteVideoPlatformView;
  xComponentController: XComponentController = new XComponentController();

  build() {
    Stack() {
      XComponent({
        id: this.platformView.getViewId(),
        type: XComponentType.SURFACE, controller: this.xComponentController,
        libraryname: Constants.AGORA_LIB_NAME,
      })
        .onLoad(() => {
          this.platformView.setSurfaceId(this.xComponentController.getXComponentSurfaceId());
          this.platformView.onViewLoaded();
        })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

@Builder
function AgoraLocalVideoViewBuilder(params: Params) {
  AgoraLocalVideoViewComponent({ params: params })
}

@Builder
function AgoraRemoteVideoViewBuilder(params: Params) {
  AgoraRemoteVideoViewComponent({ params: params })
}

// ===============================
// 引擎与视图绑定状态
// ===============================
class AgoraRtcEngineHolder {
  public rtcEngine: RtcEngine | null = null;
  private localViewId: string | null = null;
  private remoteViewIds: Map<number, string> = new Map<number, string>();
  private localViewLoaded: boolean = false;
  private remoteViewLoadedUids: Set<number> = new Set<number>();

  getOrCreateLocalViewId(): string {
    if (this.localViewId == null) {
      this.localViewId = "agora_rtc_local_view";
    }
    return this.localViewId;
  }

  getOrCreateRemoteViewId(uid: number): string {
    const cachedId = this.remoteViewIds.get(uid);
    if (cachedId != null) {
      return cachedId;
    }
    const viewId = `agora_rtc_remote_${uid}`;
    this.remoteViewIds.set(uid, viewId);
    return viewId;
  }

  removeRemoteView(uid: number): void {
    this.remoteViewIds.delete(uid);
    this.remoteViewLoadedUids.delete(uid);
  }

  bindAllVideoIfReady(): void {
    this.bindLocalVideoIfReady();
    for (let entry of this.remoteViewIds.entries()) {
      this.bindRemoteVideoIfReady(entry[0]);
    }
  }

  onLocalViewLoaded(): void {
    this.localViewLoaded = true;
    this.bindLocalVideoIfReady();
  }

  onRemoteViewLoaded(uid: number): void {
    this.remoteViewLoadedUids.add(uid);
    this.bindRemoteVideoIfReady(uid);
  }

  bindLocalVideoIfReady(): void {
    const engine = this.rtcEngine;
    if (engine == null || this.localViewId == null || !this.localViewLoaded) {
      return;
    }
    const canvas = new VideoCanvas(this.localViewId);
    canvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
    canvas.mirrorMode = 0;
    engine.setupLocalVideo(canvas);
    engine.startPreview();
  }

  bindRemoteVideoIfReady(uid: number): void {
    const engine = this.rtcEngine;
    const viewId = this.remoteViewIds.get(uid);
    if (engine == null || viewId == null || !this.remoteViewLoadedUids.has(uid)) {
      return;
    }
    const canvas = new VideoCanvas(viewId);
    canvas.uid = uid;
    canvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
    canvas.mirrorMode = 0;
    engine.setupRemoteVideo(canvas);
  }

  clear(): void {
    this.rtcEngine = null;
    this.localViewId = null;
    this.remoteViewIds.clear();
    this.localViewLoaded = false;
    this.remoteViewLoadedUids.clear();
  }
}

// ===============================
// PlatformView 工厂与实例
// ===============================
class AgoraLocalVideoViewFactory extends PlatformViewFactory {
  private engineHolder: AgoraRtcEngineHolder;

  constructor(engineHolder: AgoraRtcEngineHolder, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.engineHolder = engineHolder;
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new AgoraLocalVideoPlatformView(this.engineHolder);
  }
}

class AgoraRemoteVideoViewFactory extends PlatformViewFactory {
  private engineHolder: AgoraRtcEngineHolder;

  constructor(engineHolder: AgoraRtcEngineHolder, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.engineHolder = engineHolder;
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    const params = args as Map<string, Object>;
    const uidValue = params?.get("uid");
    const uid: number = typeof uidValue === "number" ? uidValue : Number(uidValue ?? 0);
    console.info(`remote view uid = ${uid}`);
    return new AgoraRemoteVideoPlatformView(this.engineHolder, uid);
  }
}

class AgoraLocalVideoPlatformView extends PlatformView {
  private engineHolder: AgoraRtcEngineHolder;
  private viewId: string;
  private surfaceId: string = "";

  constructor(engineHolder: AgoraRtcEngineHolder) {
    super();
    this.engineHolder = engineHolder;
    this.viewId = this.engineHolder.getOrCreateLocalViewId();
    this.engineHolder.bindLocalVideoIfReady();
  }

  getViewId(): string {
    return this.viewId;
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(AgoraLocalVideoViewBuilder);
  }

  onViewLoaded(): void {
    this.engineHolder.onLocalViewLoaded();
  }

  setSurfaceId(surfaceId: string): void {
    this.surfaceId = surfaceId;
  }

  dispose(): void {
  }
}

class AgoraRemoteVideoPlatformView extends PlatformView {
  private engineHolder: AgoraRtcEngineHolder;
  private uid: number;
  private viewId: string;
  private surfaceId: string = "";

  constructor(engineHolder: AgoraRtcEngineHolder, uid: number) {
    super();
    this.engineHolder = engineHolder;
    this.uid = uid;
    this.viewId = this.engineHolder.getOrCreateRemoteViewId(uid);
    this.engineHolder.bindRemoteVideoIfReady(uid);
  }

  getViewId(): string {
    return this.viewId;
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(AgoraRemoteVideoViewBuilder);
  }

  onViewLoaded(): void {
    this.engineHolder.onRemoteViewLoaded(this.uid);
  }

  setSurfaceId(surfaceId: string): void {
    this.surfaceId = surfaceId;
  }

  dispose(): void {
    this.engineHolder.removeRemoteView(this.uid);
  }
}
