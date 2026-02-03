import type MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec'
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import common from '@ohos.app.ability.common';
import { Constants } from '@shengwang/rtc-full';

import { AgoraRtcEngineHolder } from './AgoraRtcEngineHolder';

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
// PlatformView 工厂与实例
// ===============================
export class AgoraLocalVideoViewFactory extends PlatformViewFactory {
  private engineHolder: AgoraRtcEngineHolder;

  constructor(engineHolder: AgoraRtcEngineHolder, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.engineHolder = engineHolder;
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new AgoraLocalVideoPlatformView(this.engineHolder);
  }
}

export class AgoraRemoteVideoViewFactory extends PlatformViewFactory {
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
