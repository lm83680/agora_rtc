import { EventSink, MethodCall, MethodResult } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import {
  Constants,
  ChannelMediaOptions,
  ClientRoleOptions,
  RtcEngine,
  RtcEngineConfig,
  IRtcEngineEventHandler,
} from '@shengwang/rtc-full';

import { AgoraRtcEngineHolder } from './AgoraRtcEngineHolder';
import { AgoraRtcEngineMediaActions } from './AgoraRtcEngineMediaActions';
import { AgoraRtcEngineRecordingActions } from './AgoraRtcEngineRecordingActions';
import {
  ArgsMap,
  EventMap,
  EventPayload,
  eventDataToRecord,
  getArg,
  toRecord,
} from './AgoraRtcEngineTypes';

export class AgoraRtcEngineActions {
  private eventSink: EventSink | null = null;
  private engineHolder: AgoraRtcEngineHolder;
  private remoteVideoFirstFrameUids: Set<number> = new Set<number>();
  private eventHandler: IRtcEngineEventHandler;
  private recordingActions: AgoraRtcEngineRecordingActions;
  private mediaActions: AgoraRtcEngineMediaActions = new AgoraRtcEngineMediaActions();

  constructor(engineHolder: AgoraRtcEngineHolder) {
    this.engineHolder = engineHolder;
    this.eventHandler = {
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
    this.recordingActions = new AgoraRtcEngineRecordingActions(
      this.engineHolder,
      (eventName: string, builder: (data: EventMap) => void) => {
        this.emitEventWithData(eventName, builder);
      },
    );
  }

  setEventSink(eventSink: EventSink | null): void {
    this.eventSink = eventSink;
  }

  getEventHandler(): IRtcEngineEventHandler {
    return this.eventHandler;
  }

  clearRuntimeState(): void {
    this.remoteVideoFirstFrameUids.clear();
    this.recordingActions.clear();
  }

  private emitEventWithData(eventName: string, builder: (data: EventMap) => void): void {
    const data: EventMap = new Map();
    builder(data);
    this.emitEvent(eventName, data);
  }

  private emitEvent(type: string, data: EventMap): void {
    if (this.eventSink == null) {
      return;
    }
    let payload = new EventPayload(type, eventDataToRecord(data));
    this.eventSink.success(payload);
  }

  handleCreateEngine(call: MethodCall, result: MethodResult, applicationContext: common.Context | null): void {
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
    if (applicationContext == null) {
      result.error("NO_CONTEXT", "applicationContext 为空", null)
      return
    }
    let config: RtcEngineConfig = new RtcEngineConfig();
    config.mContext = applicationContext;
    config.mAppId = appId;
    config.mEventHandler = this.eventHandler;
    this.engineHolder.rtcEngine = RtcEngine.create(config);
    this.engineHolder.bindAllVideoIfReady();
    this.remoteVideoFirstFrameUids.clear();
    this.recordingActions.clear();
    result.success(0)
  }

  handleDestroyEngine(result: MethodResult): void {
    if (this.engineHolder.rtcEngine != null) {
      this.recordingActions.forceDestroy();
      RtcEngine.destroy();
      this.engineHolder.clear();
      this.remoteVideoFirstFrameUids.clear();
      this.recordingActions.clear();
    }
    result.success(0)
  }

  handleJoinChannel(call: MethodCall, result: MethodResult): void {
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
    const code = engine.joinChannelWithOptions(token, channelId, uid, options);
    result.success(code)
  }

  handleLeaveChannel(result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    const code = engine.leaveChannel();
    this.remoteVideoFirstFrameUids.clear();
    this.recordingActions.forceDestroy();
    result.success(code)
  }

  handleUpdateChannelMediaOptions(call: MethodCall, result: MethodResult): void {
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
    const code = engine.updateChannelMediaOptions(options);
    result.success(code)
  }

  handleSetChannelProfile(call: MethodCall, result: MethodResult): void {
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
    const code = engine.setChannelProfile(profile);
    result.success(code)
  }

  handleRenewToken(call: MethodCall, result: MethodResult): void {
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
    const code = engine.renewToken(token);
    result.success(code)
  }

  handleSetClientRole(call: MethodCall, result: MethodResult): void {
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
      const code = engine.setClientRole(role);
      result.success(code)
      return
    }
    let options = new ClientRoleOptions();
    options.audienceLatencyLevel =
      latencyLevel == 2
        ? Constants.AudienceLatencyLevel.ULTRA_LOW_LATENCY
        : Constants.AudienceLatencyLevel.LOW_LATENCY;
    const code = engine.setClientRole(role, options);
    result.success(code)
  }

  handleMuteAllRemoteAudioStreams(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteAllRemoteAudioStreams(call, result, engine);
  }

  handleMuteAllRemoteVideoStreams(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteAllRemoteVideoStreams(call, result, engine);
  }

  handleMuteRemoteAudioStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteRemoteAudioStream(call, result, engine);
  }

  handleMuteRemoteVideoStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteRemoteVideoStream(call, result, engine);
  }

  handleMuteLocalAudioStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteLocalAudioStream(call, result, engine);
  }

  handleMuteLocalVideoStream(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleMuteLocalVideoStream(call, result, engine);
  }

  handleSetRemoteVideoStreamType(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleSetRemoteVideoStreamType(call, result, engine);
  }

  handleEnableVideo(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleEnableVideo(call, result, engine);
  }

  handleEnableLocalVideo(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleEnableLocalVideo(call, result, engine);
  }

  handleStartPreview(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleStartPreview(call, result, engine);
  }

  handleStopPreview(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleStopPreview(call, result, engine);
  }

  handleTakeSnapshot(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.mediaActions.handleTakeSnapshot(call, result, engine);
  }

  handleStartRecording(call: MethodCall, result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.recordingActions.handleStartRecording(call, result, engine);
  }

  handleStopRecording(result: MethodResult): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    this.recordingActions.handleStopRecording(result, engine);
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
