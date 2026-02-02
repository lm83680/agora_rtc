# Agora RTC SDK (Flutter OHOS 版)

## 版本信息
| 平台       | SDK 版本  | 依赖配置                          | MD5 校验值（仅 OHOS）          |
|------------|-----------|-------------------------------------|--------------------------------|
| Android    | 4.6.2     | `'cn.shengwang.rtc:full-sdk:4.6.2'` | -                              |
| iOS        | 4.6.2     | `'ShengwangRtcEngine_iOS', '4.6.2'` | -                              |
| OpenHarmony | 4.4.2    | -                                   | `f02df2e181a7e25218eb87dbdca0db7d` |

## Getting Started

```
dependencies:
    agora_rtc:
        git: https://github.com/lm83680/agora_rtc.git
```

## 可用的Widget
- `AgoraRemoteVideoView` 远端视频视图 自动进行setupRemoteVideo
- `AgoraLocalVideoView` 本地视频视图 自动进行setupLocalVideo和startPreview

## 方法/回调
| 方法/回调名 | 描述 | 入参 | 出参 | 所属API模块 | 状态 |
| --- | --- | --- | --- | --- | --- |
| createEngine | 创建并初始化 RtcEngine | -（appId 由控制器构造传入） | Future<void> | 初始化相关 | 已实现 |
| destroyEngine | 销毁 RtcEngine | - | Future<void> | 初始化相关 | 已实现 |
| setChannelProfile | 设置频道场景 | profile: int | Future<void> | 频道相关 | 已实现 |
| joinChannel | 加入频道 | token: String, channelId: String, uid: int, options?: Map<String, Object?> | Future<void> | 频道相关 | 已实现 |
| leaveChannel | 离开频道 | - | Future<void> | 频道相关 | 已实现 |
| updateChannelMediaOptions | 加入频道后更新频道媒体选项 | options: Map<String, Object?> | Future<void> | 频道相关 | 已实现 |
| renewToken | 更新 Token | token: String | Future<void> | 频道相关 | 已实现 |
| setClientRole | 设置用户角色与延时级别 | role: int, latencyLevel?: int(1-低延迟 2-超低延迟) | Future<void> | 频道相关 | 已实现 |
| onJoinChannelSuccess | 自身加入频道成功回调 | channel: String, uid: int, elapsed: int | - | 频道相关 | 已实现 |
| onRejoinChannelSuccess | 自身成功重新加入频道回调 | channel: String, uid: int, elapsed: int | - | 频道相关 | 已实现 |
| onLeaveChannel | 自身离开频道回调 | stats: Map<String, Object?> | - | 频道相关 | 已实现 |
| onUserJoined | 远端用户/主播加入回调 | uid: int, elapsed: int | - | 频道相关 | 已实现 |
| onUserOffline | 远端用户/主播离开回调 | uid: int, reason: int | - | 频道相关 | 已实现 |
| onClientRoleChangeFailed | 用户角色切换失败回调 | reason: int | - | 频道相关 | 已实现 |
| onConnectionStateChanged | 网络连接状态改变回调 | state: int, reason: int | - | 频道相关 | 已实现 |
| onRequestToken | Token 已过期回调 | - | - | 频道相关 | 已实现 |
| onTokenPrivilegeWillExpire | Token 即将在 30s 内过期回调 | token: String | - | 频道相关 | 已实现 |
| onError | 发生错误回调 | error: int, message: String | - | 频道相关 | 已实现 |
| muteAllRemoteAudioStreams | 取消/恢复订阅所有远端音频流 | muted: bool | Future<void> | 发布和订阅 | 已实现 |
| muteAllRemoteVideoStreams | 取消/恢复订阅所有远端视频流 | muted: bool | Future<void> | 发布和订阅 | 已实现 |
| muteRemoteAudioStream | 取消/恢复订阅指定远端音频流 | uid: int, muted: bool | Future<void> | 发布和订阅 | 已实现 |
| muteRemoteVideoStream | 取消/恢复订阅指定远端视频流 | uid: int, muted: bool | Future<void> | 发布和订阅 | 已实现 |
| muteLocalAudioStream | 取消/恢复发布本地音频流 | muted: bool | Future<void> | 发布和订阅 | 已实现 |
| muteLocalVideoStream | 取消/恢复发布本地视频流 | muted: bool | Future<void> | 发布和订阅 | 已实现 |
| setRemoteVideoStreamType | 设置订阅的视频流类型 | uid: int, streamType: int | Future<void> | 发布和订阅 | 已实现 |
| enableVideo | 启用或关闭视频模块 | enabled: bool | Future<void> | 视频基础功能 | 已实现 |
| enableLocalVideo | 开关本地视频采集 | enabled: bool | Future<void> | 视频基础功能 | 已实现 |
| startPreview | 启动本地视频预览 | sourceType?: int | Future<void> | 视频基础功能 | 已实现 |
| stopPreview | 停止本地视频预览 | sourceType?: int | Future<void> | 视频基础功能 | 已实现 |
| onAudioPublishStateChanged | 自身音频发布状态改变回调 | channel: String, oldState: int, newState: int, elapseSinceLastState: int | - | 发布和订阅 | 已实现 |
| onUserMuteVideo | 远端用户取消或恢复发布视频流回调 | channelId: String, uid: int, muted: bool | - | 视频基础功能 | 已实现 |
| onFirstRemoteVideoFrame | 远端视频首帧回调 | uid: int, channelId: String, width: int, height: int | - | 视频渲染 | 已实现 |
| takeSnapshot | 对视频截图 | uid: int, filePath: String | Future<void> | 本地截图上传 | 已实现 |
| onSnapshotTaken | 视频截图结果回调 | connection: Map<String, Object?>, uid: int, filePath: String, width: int, height: int, errCode: int | - | 本地截图上传 | 已实现 |
| startRecording | 创建录制实例并开始录制 | config: Map<String, Object?> | Future<void> | 音视频录制 | 已实现 |
| stopRecording | 停止录制并销毁录制实例 | - | Future<void> | 音视频录制 | 已实现 |
| onRecorderStateChanged | 录制状态发生变化回调 | channelId: String, uid: int, state: int, reason: int | - | 音视频录制 | 已实现 |


## 智能对讲摄像头案例

目前只有这个案例中的方法/回调得到验证

1. `createEngine` 创建RtcEngine
2. 与后端通信，通知远端摄像头加入频道，获得频道ID、设备uid
3. 创建 `AgoraRemoteVideoView` 并 `joinChannel` 加入频道，注意预设options避免收听声音和麦克风录制，此时可设置`setClientRole`降低成本
4. 进入loading，等待 `onFirstRemoteVideoFrame` 回调，关闭loading
5. `muteAllRemoteAudioStreams` 用于远端静音/解除静音
6. `updateChannelMediaOptions` 设置自身上麦并进入对讲，或者下麦
7. `leaveChannel` + 可选的`destroyEngine` 离开并销毁实例

## 说明

匆匆忙忙构建了这个插件包，大多方法/回调没有得到验证；使用时需要留意。
另外我提供了一个skill，它可能会对你有帮助，当你对`agent`说：帮我集成 https://doc.shengwang.cn/api-ref/rtc/flutter/API/toc_publishnsubscribe#setDualStreamMode 时，他应该会工作，按照现有的结构帮你集成。