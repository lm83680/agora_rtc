package com.changteng.agora_rtc

import io.agora.rtc2.AgoraMediaRecorder
import io.agora.rtc2.IMediaRecorderCallback
import io.agora.rtc2.RecorderInfo
import io.agora.rtc2.RecorderStreamInfo
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class AgoraRtcEngineRecordingActions(
  private val engineHolder: AgoraRtcEngineHolder,
  private val emitter: AgoraEventEmitter
) {
  private var mediaRecorder: AgoraMediaRecorder? = null
  private var shouldDestroyOnStop: Boolean = false

  fun clear() {
    mediaRecorder = null
    shouldDestroyOnStop = false
  }

  fun handleStartRecording(call: MethodCall, result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "参数缺失", null)
      return
    }
    val configMap = args["config"] as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "config 为空", null)
      return
    }
    val channelId = configMap["channelId"] as? String ?: ""
    val uid = (configMap["uid"] as? Number)?.toInt() ?: 0
    val storagePath = configMap["storagePath"] as? String
    val containerFormat = (configMap["containerFormat"] as? Number)?.toInt() ?: AgoraMediaRecorder.CONTAINER_MP4
    val streamType = (configMap["streamType"] as? Number)?.toInt() ?: AgoraMediaRecorder.STREAM_TYPE_BOTH
    val maxDurationMs = (configMap["maxDurationMs"] as? Number)?.toInt() ?: 120000
    val recorderInfoUpdateInterval = (configMap["recorderInfoUpdateInterval"] as? Number)?.toInt() ?: 0
    if (storagePath.isNullOrBlank()) {
      result.error("INVALID_ARGS", "storagePath 为空", null)
      return
    }
    try {
      if (mediaRecorder == null) {
        val streamInfo = RecorderStreamInfo().apply {
          this.channelId = channelId
          this.uid = uid
        }
        mediaRecorder = engine.createMediaRecorder(streamInfo)
        mediaRecorder?.setMediaRecorderObserver(object : IMediaRecorderCallback {
          override fun onRecorderStateChanged(channelId: String?, uid: Int, state: Int, error: Int) {
            emitter.emit(
              "onRecorderStateChanged",
              mapOf(
                "channelId" to (channelId ?: ""),
                "uid" to uid,
                "state" to state,
                "reason" to error
              )
            )
            if (shouldDestroyOnStop) {
              mediaRecorder?.setMediaRecorderObserver(null)
              engine.destroyMediaRecorder(mediaRecorder)
              mediaRecorder = null
              shouldDestroyOnStop = false
            }
          }

          override fun onRecorderInfoUpdated(channelId: String?, uid: Int, info: RecorderInfo?) {
          }
        })
      }
      val config = AgoraMediaRecorder.MediaRecorderConfiguration(
        storagePath,
        containerFormat,
        streamType,
        maxDurationMs,
        recorderInfoUpdateInterval
      )
      val code = mediaRecorder?.startRecording(config) ?: -1
      result.success(code)
    } catch (ex: Exception) {
      result.error("RECORDER_UNSUPPORTED", ex.message, null)
    }
  }

  fun handleStopRecording(result: Result) {
    val engine = engineHolder.rtcEngine
    if (engine == null) {
      result.error("NO_ENGINE", "RtcEngine 未初始化", null)
      return
    }
    val recorder = mediaRecorder ?: run {
      result.success(-1)
      return
    }
    shouldDestroyOnStop = true
    val stopCode = recorder.stopRecording()
    if (stopCode < 0) {
      recorder.setMediaRecorderObserver(null)
      engine.destroyMediaRecorder(recorder)
      mediaRecorder = null
      shouldDestroyOnStop = false
    }
    result.success(stopCode)
  }
}
