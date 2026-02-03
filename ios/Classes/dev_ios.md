# iOS 端新增 API/回调开发指南

日期：2026-02-03  
执行者：Codex

面向对象：初级开发者  
目标：指导你在 iOS 端新增 Agora RTC 原生方法或回调，并正确联动 Flutter。

## 1. 文件结构说明

以下文件均位于 `agora_rtc/ios/Classes/`：

- `AgoraRtcEnginePlugin.swift`  
  Flutter 插件入口，负责 MethodChannel/EventChannel 注册与路由分发。
- `AgoraRtcEngineActions.swift`  
  处理引擎与频道级别的 API（如 createEngine/joinChannel/setClientRole 等）。
- `AgoraRtcEngineMediaActions.swift`  
  处理发布/订阅、预览、截图等 API。
- `AgoraRtcEngineRecordingActions.swift`  
  处理录制 API，并通过回调发出事件。
- `AgoraRtcEngineEventHandler.swift`  
  SDK 回调的统一入口，负责把回调转换为 Flutter 事件。
- `AgoraRtcEngineEventStreamHandler.swift`  
  Flutter EventChannel 的实现，负责发送事件 Map 到 Dart。
- `AgoraRtcEngineViewHolder.swift`  
  管理本地/远端视图与引擎绑定。
- `AgoraRtcEngineViews.swift`  
  Flutter PlatformView 的 iOS 实现。

## 2. 新增一个原生方法（API）

以新增 `enableAudio` 为例。

### 2.1 在 Flutter 端声明（已有模板时可略过）
在 Dart 端新增方法声明，并在 MethodChannel 中添加对应调用。

### 2.2 在 `AgoraRtcEnginePlugin.swift` 中注册路由

在 `handle(_ call: FlutterMethodCall, result: FlutterResult)` 的 switch 中新增：

```
case "enableAudio":
  actions.handleEnableAudio(result: result)
```

### 2.3 在对应 Actions 文件实现

建议放在 `AgoraRtcEngineMediaActions.swift` 或 `AgoraRtcEngineActions.swift`：

```
func handleEnableAudio(result: @escaping FlutterResult) {
  guard let engine = engineHolder.rtcEngine else {
    result(FlutterError(code: "NO_ENGINE", message: "RtcEngine 未初始化", details: nil))
    return
  }
  let code = engine.enableAudio()
  result(code)
}
```

### 2.4 返回值规则（必须）

所有 SDK 返回值为 `Int`：  
- `0` 成功  
- `< 0` 失败  

无需在 iOS 端做错误码映射，直接返回给 Flutter。

## 3. 新增一个 SDK 回调（事件）

以新增 `onUserMuteVideo` 为例。

### 3.1 在 `AgoraRtcEngineEventHandler.swift` 中新增回调

```
func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
  emitter.emit(
    type: "onUserMuteVideo",
    data: [
      "channelId": "",
      "uid": Int(uid),
      "muted": muted,
    ]
  )
}
```

### 3.2 Flutter 侧事件解析

在 `agora_rtc/lib/agora_rtc_events.dart` 里添加解析逻辑：

- 新增事件数据结构（如 `AgoraUserMuteVideoEvent`）
- 在 `AgoraEventParser.fromMap` 中新增 `case 'onUserMuteVideo'`

### 3.3 事件命名规范

事件名必须与 Flutter 端解析的字符串一致，例如：

- iOS 端 `emit(type: "onUserMuteVideo", ...)`
- Dart 端 `case 'onUserMuteVideo':`

## 4. 新增参数解析规范

MethodChannel 参数统一使用 `[String: Any]`，并严格校验：

- 缺参 → `INVALID_ARGS`
- 引擎未初始化 → `NO_ENGINE`

示例：

```
guard let args = call.arguments as? [String: Any] else {
  result(FlutterError(code: "INVALID_ARGS", message: "参数缺失", details: nil))
  return
}
```

## 5. 视图相关注意事项

本地视图与远端视图通过 `AgoraRtcEngineViewHolder` 绑定：

- 本地视图：`makeLocalVideoView()`
- 远端视图：`makeRemoteVideoView(uid:)`

引擎创建后会自动 `bindCachedVideoViews()`，因此：

- 视图可先创建，再创建引擎
- 引擎创建后会自动绑定已有视图

## 6. 录制相关注意事项

录制回调必须在 `onRecorderStateChanged` 中发出。  
停止录制时不要立即销毁 recorder，应等回调触发后再销毁，避免回调丢失。

## 7. 常见问题

- 编译找不到新增 Swift 类  
  检查 `agora_rtc/ios/agora_rtc.podspec` 是否包含 `.swift`：
  ```
  s.source_files = 'Classes/**/*.{h,m,swift}'
  ```

- 事件没有回调  
  检查 `AgoraRtcEventStreamHandler` 是否已注册：
  ```
  eventChannel.setStreamHandler(instance.eventStreamHandler)
  ```
