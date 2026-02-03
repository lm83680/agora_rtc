import { MethodCall, MethodResult } from '@ohos/flutter_ohos';
import { RtcEngine } from '@shengwang/rtc-full';

import { ArgsMap, getArg } from './AgoraRtcEngineTypes';

export class AgoraRtcEngineMediaActions {
  handleMuteAllRemoteAudioStreams(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    const code = engine.muteAllRemoteAudioStreams(muted);
    result.success(code)
  }

  handleMuteAllRemoteVideoStreams(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    const code = engine.muteAllRemoteVideoStreams(muted);
    result.success(code)
  }

  handleMuteRemoteAudioStream(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    const code = engine.muteRemoteAudioStream(uid, muted);
    result.success(code)
  }

  handleMuteRemoteVideoStream(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (uid == null || muted == null) {
      result.error("INVALID_ARGS", "uid 或 muted 为空", null)
      return
    }
    const code = engine.muteRemoteVideoStream(uid, muted);
    result.success(code)
  }

  handleMuteLocalAudioStream(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    const code = engine.muteLocalAudioStream(muted);
    result.success(code)
  }

  handleMuteLocalVideoStream(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let muted = getArg(argsMap, "muted") as boolean | undefined;
    if (muted == null) {
      result.error("INVALID_ARGS", "muted 为空", null)
      return
    }
    const code = engine.muteLocalVideoStream(muted);
    result.success(code)
  }

  handleSetRemoteVideoStreamType(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let streamType = getArg(argsMap, "streamType") as number | undefined;
    if (uid == null || streamType == null) {
      result.error("INVALID_ARGS", "uid 或 streamType 为空", null)
      return
    }
    const code = engine.setRemoteVideoStreamType(uid, streamType);
    result.success(code)
  }

  handleEnableVideo(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let enabled = getArg(argsMap, "enabled") as boolean | undefined;
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    const code = enabled ? engine.enableVideo() : engine.disableVideo();
    result.success(code)
  }

  handleEnableLocalVideo(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let enabled = getArg(argsMap, "enabled") as boolean | undefined;
    if (enabled == null) {
      result.error("INVALID_ARGS", "enabled 为空", null)
      return
    }
    const code = engine.enableLocalVideo(enabled);
    result.success(code)
  }

  handleStartPreview(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let sourceType = getArg(argsMap, "sourceType") as number | undefined;
    if (sourceType == null) {
      const code = engine.startPreview();
      result.success(code)
    } else {
      const code = engine.startPreview(sourceType);
      result.success(code)
    }
  }

  handleStopPreview(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let sourceType = getArg(argsMap, "sourceType") as number | undefined;
    if (sourceType == null) {
      const code = engine.stopPreview();
      result.success(code)
    } else {
      const code = engine.stopPreview(sourceType);
      result.success(code)
    }
  }

  handleTakeSnapshot(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
    let argsMap = call.args as ArgsMap | undefined;
    let uid = getArg(argsMap, "uid") as number | undefined;
    let filePath = getArg(argsMap, "filePath") as string | undefined;
    if (uid == null || !filePath) {
      result.error("INVALID_ARGS", "uid 或 filePath 为空", null)
      return
    }
    const code = engine.takeSnapshot(uid, filePath);
    result.success(code)
  }
}
