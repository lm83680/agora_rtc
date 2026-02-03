import { RtcEngine, VideoCanvas } from '@shengwang/rtc-full';

// 引擎与视图绑定状态
export class AgoraRtcEngineHolder {
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
