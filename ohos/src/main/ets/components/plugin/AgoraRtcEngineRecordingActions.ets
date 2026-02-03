import { MethodCall, MethodResult } from '@ohos/flutter_ohos';
import {
  AgoraMediaRecorder,
  IMediaRecorderCallback,
  MediaRecorderConfiguration,
  RecorderStreamInfo,
  RtcEngine,
} from '@shengwang/rtc-full';

import { AgoraRtcEngineHolder } from './AgoraRtcEngineHolder';
import { ArgsMap, EventMap, getArg, toRecord } from './AgoraRtcEngineTypes';

export class AgoraRtcEngineRecordingActions {
  private mediaRecorder: AgoraMediaRecorder | null = null;
  private recorderChannelId: string = "";
  private recorderUid: number = 0;
  private mediaRecorderCallback: IMediaRecorderCallback;
  private shouldDestroyOnStop: boolean = false;
  private engineHolder: AgoraRtcEngineHolder;

  constructor(
    engineHolder: AgoraRtcEngineHolder,
    emitEventWithData: (eventName: string, builder: (data: EventMap) => void) => void
  ) {
    this.engineHolder = engineHolder;
    this.mediaRecorderCallback = {
      onRecorderStateChanged: (channelId: string, uid: number, state: number, reason: number) => {
        emitEventWithData("onRecorderStateChanged", (data: EventMap) => {
          data.set("channelId", channelId);
          data.set("uid", uid);
          data.set("state", state);
          data.set("reason", reason);
        });
        if (this.shouldDestroyOnStop && this.mediaRecorder != null) {
          this.mediaRecorder.release();
          const engine = this.engineHolder.rtcEngine;
          if (engine != null) {
            engine.destroyMediaRecorder(this.mediaRecorder);
          }
          this.mediaRecorder = null;
          this.shouldDestroyOnStop = false;
        }
      },
      onRecorderInfoUpdated: (channelId: string, uid: number, info) => {
      },
    };
  }

  clear(): void {
    this.mediaRecorder = null;
    this.recorderChannelId = "";
    this.recorderUid = 0;
    this.shouldDestroyOnStop = false;
  }

  forceDestroy(): void {
    const engine = this.engineHolder.rtcEngine;
    if (engine == null) {
      this.mediaRecorder = null;
      this.shouldDestroyOnStop = false;
      return;
    }
    if (this.mediaRecorder == null) {
      this.shouldDestroyOnStop = false;
      return;
    }
    this.mediaRecorder.release();
    engine.destroyMediaRecorder(this.mediaRecorder);
    this.mediaRecorder = null;
    this.shouldDestroyOnStop = false;
  }

  handleStartRecording(call: MethodCall, result: MethodResult, engine: RtcEngine): void {
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
    const code = this.mediaRecorder?.startRecording(recorderConfig) ?? -1;
    result.success(code)
  }

  handleStopRecording(result: MethodResult, engine: RtcEngine): void {
    if (this.mediaRecorder != null) {
      this.shouldDestroyOnStop = true;
      const stopCode = this.mediaRecorder.stopRecording();
      if (stopCode < 0) {
        this.mediaRecorder.release();
        engine.destroyMediaRecorder(this.mediaRecorder);
        this.mediaRecorder = null;
        this.shouldDestroyOnStop = false;
      }
      result.success(stopCode);
      return
    }
    result.success(-1)
  }
}
