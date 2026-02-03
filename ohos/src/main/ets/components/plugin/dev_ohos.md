# OHOS 原生扩展教程（新增方法/回调）

面向初级开发者：本教程说明如何在 **OHOS 端**新增 Agora RTC 的“方法调用”和“回调事件”，并正确从 Flutter 侧接收到结果。

## 目录结构概览

当前 OHOS 插件已拆分为多个文件，请按职责修改：

- `AgoraRtcEnginePlugin.ets`
  - Flutter MethodChannel / EventChannel 的入口
  - 只负责**分发**（不写复杂业务）
- `AgoraRtcEngineActions.ets`
  - **核心业务**：引擎创建/销毁、进退频道、角色设置、事件组装
- `AgoraRtcEngineMediaActions.ets`
  - **媒体控制**：静音、开关视频、预览、截图等
- `AgoraRtcEngineRecordingActions.ets`
  - **录制相关**：start/stop recording
- `AgoraRtcEngineViews.ets`
  - **本地/远端渲染视图**
- `AgoraRtcEngineHolder.ets`
  - 引擎与视图绑定状态
- `AgoraRtcEngineTypes.ets`
  - 事件/参数类型与通用工具函数

> 提示：新增“方法”通常改 `Actions` 或 `MediaActions`；新增“回调”通常改 `Actions` 的事件组装。

---

## 一、新增一个方法（MethodChannel）

### 目标
在 Flutter 调用 `_controller.xxx()` 后，OHOS 能执行 SDK 方法并返回 `int`。

### 步骤

#### 1. 在 `AgoraRtcEnginePlugin.ets` 分发入口添加方法名

```ts
} else if (call.method == "setFooBar") {
  this.actions.handleSetFooBar(call, result)
}
```

> 只负责分发，不在此处写逻辑。

#### 2. 在 `AgoraRtcEngineActions.ets` 或 `AgoraRtcEngineMediaActions.ets` 实现

示例（添加到 `AgoraRtcEngineActions.ets`）：

```ts
handleSetFooBar(call: MethodCall, result: MethodResult): void {
  const engine = this.engineHolder.rtcEngine;
  if (engine == null) {
    result.error("NO_ENGINE", "RtcEngine 未初始化", null)
    return
  }

  const argsMap = call.args as ArgsMap | undefined;
  const foo = getArg(argsMap, "foo") as number | undefined;
  if (foo == null) {
    result.error("INVALID_ARGS", "foo 为空", null)
    return
  }

  const code = engine.setFooBar(foo);
  result.success(code)
}
```

> 统一规则：**返回 SDK 的 int 结果**，0 表示成功，<0 表示失败。 如果 API 的返回值不为int，例如 `handleCreateEngine`, 那么直接使用 `result.success(0)` ，异常时让 Dart 自行捕获

#### 3. Flutter 侧确认方法签名

确保 Dart 侧方法返回 `Future<int>`，并正确传入参数。

---

## 二、新增一个回调事件（EventChannel）

### 目标
SDK 触发回调后，Flutter 能收到事件（包含 type + data）。

### 步骤

#### 1. 在 `AgoraRtcEngineActions.ets` 的 `eventHandler` 添加事件

示例：新增 `onFooBar` 回调

```ts
onFooBar: (uid: number, state: number) => {
  this.emitEventWithData("onFooBar", (data: EventMap) => {
    data.set("uid", uid);
    data.set("state", state);
  });
},
```

#### 2. Flutter 侧监听事件

Flutter 会收到：

```json
{
  "type": "onFooBar",
  "data": { "uid": 123, "state": 1 }
}
```

> 所有事件都由 `emitEventWithData` 统一封装，确保格式一致。

---

## 三、参数读取注意事项（OHOS 特性）

Flutter 传递的 Map **不能用 interface 直接接收**，必须这样写：

```ts
const argsMap = call.args as Map<string, Object>;
const uidValue = argsMap.get("uid");
```

**不要写**：

```ts
const uid = call.args["uid"]; // ❌ OHOS 会报错
```

---

## 四、渲染视图新增/修改

如需修改本地/远端渲染逻辑：

- 视图组件在 `AgoraRtcEngineViews.ets`
- 引擎绑定逻辑在 `AgoraRtcEngineHolder.ets`
