package com.levnext.native_audio_trimmer

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NativeAudioTrimmerPlugin */
class NativeAudioTrimmerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel : MethodChannel
  private lateinit var audioTrimmer: AudioTrimmerImpl

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_audio_trimmer")
    channel.setMethodCallHandler(this)
    audioTrimmer = AudioTrimmerImpl()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "trimAudio" -> {
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val startTime = call.argument<Double>("startTime")
        val endTime = call.argument<Double>("endTime")

        if (inputPath == null || outputPath == null || startTime == null || endTime == null) {
          result.error("INVALID_ARGUMENTS", "Required arguments missing", null)
          return
        }
        
        try {
          val trimmedFilePath = audioTrimmer.trimAudio(inputPath, outputPath, startTime, endTime)
          result.success(trimmedFilePath)
        } catch (e: Exception) {
          result.error("TRIM_ERROR", "Failed to trim audio: ${e.message}", e.stackTraceToString())
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}