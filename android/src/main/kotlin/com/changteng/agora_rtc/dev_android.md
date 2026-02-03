# Android 原生扩展教程（新增方法/回调）

面向初级开发者：本教程说明如何在 **Android 端**新增 Agora RTC 的“方法调用”和“回调事件”，并正确从 Flutter 侧接收到结果。

## 目录结构概览

Android 插件已拆分为多个文件，请按职责修改：

- `AgoraRtcEnginePlugin.kt`
  - Flutter MethodChannel / EventChannel 入口
  - 只负责**分发**（不写复杂业务）
- `AgoraRtcEngineActions.kt`
  - **核心业务**：引擎创建/销毁、进退频道、角色设置
- `AgoraRtcEngineMediaActions.kt`
  - **媒体控制**：静音、开关视频、预览、截图等
- `AgoraRtcEngineRecordingActions.kt`
  - **录制相关**：start/stop recording
- `AgoraRtcEngineEventHandler.kt`
  - **SDK 回调转事件**
- `AgoraRtcEngineEventStreamHandler.kt`
  - **EventChannel 输出**
- `AgoraRtcEngineHolder.kt`
  - 引擎与视图绑定状态
- `AgoraRtcEngineViews.kt`
  - 本地/远端渲染视图

> 提示：新增“方法”通常改 `Actions` 或 `MediaActions`；新增“回调”通常改 `EventHandler`。

---

## 一、新增一个方法（MethodChannel）

### 目标
在 Flutter 调用 `_controller.xxx()` 后，Android 能执行 SDK 方法并返回 `int`。

### 步骤

#### 1. 在 `AgoraRtcEnginePlugin.kt` 分发入口添加方法名

```kotlin
when (call.method) {
  "setFooBar" -> actions.handleSetFooBar(call, result)
}
```

> 只负责分发，不在此处写逻辑。

#### 2. 在 `AgoraRtcEngineActions.kt` 或 `AgoraRtcEngineMediaActions.kt` 实现

示例（添加到 `AgoraRtcEngineActions.kt`）：

```kotlin
fun handleSetFooBar(call: MethodCall, result: Result) {
  val engine = engineHolder.rtcEngine
  if (engine == null) {
    result.error("NO_ENGINE", "RtcEngine 未初始化", null)
    return
  }
  val args = call.arguments as? Map<*, *> ?: run {
    result.error("INVALID_ARGS", "参数缺失", null)
    return
  }
  val foo = (args["foo"] as? Number)?.toInt()
  if (foo == null) {
    result.error("INVALID_ARGS", "foo 为空", null)
    return
  }
  val code = engine.setFooBar(foo)
  result.success(code)
}
```

> 统一规则：**返回 SDK 的 int 结果**，0 表示成功，<0 表示失败。

---

## 二、新增一个回调事件（EventChannel）

### 目标
SDK 触发回调后，Flutter 能收到事件（包含 type + data）。

### 步骤

#### 1. 在 `AgoraRtcEngineEventHandler.kt` 添加事件

示例：新增 `onFooBar` 回调

```kotlin
override fun onFooBar(uid: Int, state: Int) {
  emitter.emit(
    "onFooBar",
    mapOf(
      "uid" to uid,
      "state" to state
    )
  )
}
```

#### 2. Flutter 侧监听事件

Flutter 会收到：

```json
{
  "type": "onFooBar",
  "data": { "uid": 123, "state": 1 }
}
```

---

## 三、渲染视图新增/修改

如需修改本地/远端渲染逻辑：

- 视图组件在 `AgoraRtcEngineViews.kt`
- 引擎绑定逻辑在 `AgoraRtcEngineHolder.kt`
