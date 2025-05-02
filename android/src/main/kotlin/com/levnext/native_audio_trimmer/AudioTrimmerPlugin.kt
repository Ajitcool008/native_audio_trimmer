package com.levnext.native_audio_trimmer

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer

/** AudioTrimmerPlugin */
class AudioTrimmerPlugin: FlutterPlugin, MethodCallHandler {
  private val TAG = "AudioTrimmerPlugin"
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "audio_trimmer")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "trimAudio") {
      val inputPath = call.argument<String>("inputPath")
      val outputPath = call.argument<String>("outputPath")
      val start = call.argument<Double>("start")
      val end = call.argument<Double>("end")
      
      if (inputPath == null || outputPath == null || start == null || end == null) {
        result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
        return
      }
      
      try {
        trimAudio(inputPath, outputPath, start, end)
        result.success("Audio trimmed successfully")
      } catch (e: Exception) {
        Log.e(TAG, "Error trimming audio", e)
        result.error("TRIM_FAILED", "Failed to trim audio: ${e.message}", null)
      }
    } else {
      result.notImplemented()
    }
  }

  private fun trimAudio(inputPath: String, outputPath: String, startTimeInSeconds: Double, endTimeInSeconds: Double) {
    // Ensure the output directory exists
    val outputFile = File(outputPath)
    if (outputFile.exists()) {
      outputFile.delete()
    }
    val parentDir = outputFile.parentFile
    if (parentDir != null && !parentDir.exists()) {
      parentDir.mkdirs()
    }

    // Get source file information
    val extractor = MediaExtractor()
    extractor.setDataSource(inputPath)

    // Find the first audio track
    var audioTrackIndex = -1
    for (i in 0 until extractor.trackCount) {
      val format = extractor.getTrackFormat(i)
      val mime = format.getString(MediaFormat.KEY_MIME)
      if (mime != null && mime.startsWith("audio/")) {
        audioTrackIndex = i
        break
      }
    }

    if (audioTrackIndex < 0) {
      throw IOException("No audio track found in the input file.")
    }

    // Select the audio track
    extractor.selectTrack(audioTrackIndex)
    val format = extractor.getTrackFormat(audioTrackIndex)

    // Create a new muxer
    val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    val outputTrackIndex = muxer.addTrack(format)
    muxer.start()

    // Convert start and end times to microseconds
    val startTimeUs = (startTimeInSeconds * 1_000_000).toLong()
    val endTimeUs = (endTimeInSeconds * 1_000_000).toLong()

    // Seek to the start position
    extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

    // Allocate buffer for reading
    val maxBufferSize = 1024 * 1024 // 1MB buffer
    val buffer = ByteBuffer.allocate(maxBufferSize)
    val bufferInfo = MediaCodec.BufferInfo()

    // Write samples within the specified time range
    while (true) {
      val sampleSize = extractor.readSampleData(buffer, 0)
      if (sampleSize < 0) {
        // End of stream
        break
      }

      val sampleTime = extractor.sampleTime
      if (sampleTime > endTimeUs) {
        // Beyond the end time
        break
      }

      if (sampleTime >= startTimeUs) {
        bufferInfo.size = sampleSize
        bufferInfo.offset = 0
        bufferInfo.flags = extractor.sampleFlags
        bufferInfo.presentationTimeUs = sampleTime - startTimeUs
        
        muxer.writeSampleData(outputTrackIndex, buffer, bufferInfo)
      }
      
      extractor.advance()
    }

    // Release resources
    muxer.stop()
    muxer.release()
    extractor.release()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}