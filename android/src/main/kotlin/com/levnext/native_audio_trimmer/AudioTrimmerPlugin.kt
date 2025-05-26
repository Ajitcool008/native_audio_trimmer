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
        val finalOutputPath = trimAudio(inputPath, outputPath, start, end)
        result.success(finalOutputPath)
      } catch (e: Exception) {
        Log.e(TAG, "Error trimming audio", e)
        result.error("TRIM_FAILED", "Failed to trim audio: ${e.message}", null)
      }
    } else {
      result.notImplemented()
    }
  }

  private fun trimAudio(inputPath: String, outputPath: String, startTimeInSeconds: Double, endTimeInSeconds: Double): String {
    // Get source file information first
    val extractor = MediaExtractor()
    extractor.setDataSource(inputPath)

    // Find the first audio track
    var audioTrackIndex = -1
    var inputFormat: MediaFormat? = null
    for (i in 0 until extractor.trackCount) {
      val format = extractor.getTrackFormat(i)
      val mime = format.getString(MediaFormat.KEY_MIME)
      if (mime != null && mime.startsWith("audio/")) {
        audioTrackIndex = i
        inputFormat = format
        break
      }
    }

    if (audioTrackIndex < 0 || inputFormat == null) {
      extractor.release()
      throw IOException("No audio track found in the input file.")
    }

    val inputMime = inputFormat.getString(MediaFormat.KEY_MIME)
    Log.d(TAG, "Input audio format: $inputMime")

    // Determine the final output path based on input format
    val finalOutputPath = if (inputMime == "audio/mpeg" && outputPath.endsWith(".mp3")) {
      outputPath.replace(".mp3", ".m4a")
    } else {
      outputPath
    }

    // Ensure the output directory exists
    val outputFile = File(finalOutputPath)
    if (outputFile.exists()) {
      outputFile.delete()
    }
    val parentDir = outputFile.parentFile
    if (parentDir != null && !parentDir.exists()) {
      parentDir.mkdirs()
    }

    extractor.release()

    // Handle different audio formats
    return when (inputMime) {
      "audio/mpeg" -> {
        Log.d(TAG, "Converting MP3 to AAC format")
        trimMp3ToAac(inputPath, finalOutputPath, startTimeInSeconds, endTimeInSeconds)
      }
      else -> {
        Log.d(TAG, "Direct copy for format: $inputMime")
        trimDirectCopy(inputPath, finalOutputPath, startTimeInSeconds, endTimeInSeconds)
      }
    }
  }

  private fun trimMp3ToAac(inputPath: String, outputPath: String, startTimeInSeconds: Double, endTimeInSeconds: Double): String {
    val extractor = MediaExtractor()
    var decoder: MediaCodec? = null
    var encoder: MediaCodec? = null
    var muxer: MediaMuxer? = null

    try {
      // Set up extractor
      extractor.setDataSource(inputPath)
      
      // Find audio track
      var audioTrackIndex = -1
      var inputFormat: MediaFormat? = null
      for (i in 0 until extractor.trackCount) {
        val format = extractor.getTrackFormat(i)
        val mime = format.getString(MediaFormat.KEY_MIME)
        if (mime?.startsWith("audio/") == true) {
          extractor.selectTrack(i)
          audioTrackIndex = i
          inputFormat = format
          break
        }
      }

      if (inputFormat == null) {
        throw IOException("No audio track found")
      }

      // Create decoder
      decoder = MediaCodec.createDecoderByType("audio/mpeg")
      decoder.configure(inputFormat, null, null, 0)
      decoder.start()

      // Create output format for AAC
      val sampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
      val channelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
      
      val outputFormat = MediaFormat.createAudioFormat("audio/mp4a-latm", sampleRate, channelCount)
      outputFormat.setInteger(MediaFormat.KEY_BIT_RATE, 128000)
      outputFormat.setInteger(MediaFormat.KEY_AAC_PROFILE, 2) // AAC_LC profile

      // Create encoder
      encoder = MediaCodec.createEncoderByType("audio/mp4a-latm")
      encoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
      encoder.start()

      // Create muxer - we'll recreate it after getting the actual output format
      var muxerTrackIndex = -1
      var muxerStarted = false

      // Convert time to microseconds
      val startTimeUs = (startTimeInSeconds * 1_000_000).toLong()
      val endTimeUs = (endTimeInSeconds * 1_000_000).toLong()

      // Seek to start position
      extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

      val decoderBufferInfo = MediaCodec.BufferInfo()
      val encoderBufferInfo = MediaCodec.BufferInfo()
      
      var decoderDone = false
      var encoderDone = false

      while (!encoderDone) {
        // Feed decoder
        if (!decoderDone) {
          val inputBufferIndex = decoder.dequeueInputBuffer(10000)
          if (inputBufferIndex >= 0) {
            val inputBuffer = decoder.getInputBuffer(inputBufferIndex)
            inputBuffer?.clear()
            
            val sampleSize = extractor.readSampleData(inputBuffer!!, 0)
            val sampleTime = extractor.sampleTime
            
            if (sampleSize >= 0 && sampleTime <= endTimeUs) {
              decoder.queueInputBuffer(inputBufferIndex, 0, sampleSize, sampleTime, 0)
              extractor.advance()
            } else {
              decoder.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
              decoderDone = true
            }
          }
        }

        // Get decoded data
        val decoderOutputIndex = decoder.dequeueOutputBuffer(decoderBufferInfo, 10000)
        if (decoderOutputIndex >= 0) {
          val decodedBuffer = decoder.getOutputBuffer(decoderOutputIndex)
          
          if (decoderBufferInfo.size > 0 && decoderBufferInfo.presentationTimeUs >= startTimeUs) {
            // Feed to encoder
            val encoderInputIndex = encoder.dequeueInputBuffer(10000)
            if (encoderInputIndex >= 0) {
              val encoderInputBuffer = encoder.getInputBuffer(encoderInputIndex)
              encoderInputBuffer?.clear()
              encoderInputBuffer?.put(decodedBuffer)
              
              encoder.queueInputBuffer(
                encoderInputIndex, 
                0, 
                decoderBufferInfo.size,
                decoderBufferInfo.presentationTimeUs - startTimeUs,
                0
              )
            }
          }
          
          if (decoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
            val encoderInputIndex = encoder.dequeueInputBuffer(10000)
            if (encoderInputIndex >= 0) {
              encoder.queueInputBuffer(encoderInputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            }
          }
          
          decoder.releaseOutputBuffer(decoderOutputIndex, false)
        }

        // Get encoded data
        val encoderOutputIndex = encoder.dequeueOutputBuffer(encoderBufferInfo, 10000)
        if (encoderOutputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
          // Create muxer with the actual output format from encoder
          if (!muxerStarted) {
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxerTrackIndex = muxer.addTrack(encoder.outputFormat)
            muxer.start()
            muxerStarted = true
          }
        } else if (encoderOutputIndex >= 0) {
          val encodedBuffer = encoder.getOutputBuffer(encoderOutputIndex)
          
          if (muxerStarted && encoderBufferInfo.size > 0) {
            muxer?.writeSampleData(muxerTrackIndex, encodedBuffer!!, encoderBufferInfo)
          }
          
          encoder.releaseOutputBuffer(encoderOutputIndex, false)
          
          if (encoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
            encoderDone = true
          }
        }
      }

      return outputPath

    } finally {
      try {
        decoder?.stop()
        decoder?.release()
        encoder?.stop()
        encoder?.release()
        muxer?.stop()
        muxer?.release()
        extractor.release()
      } catch (e: Exception) {
        Log.e(TAG, "Error releasing resources: ${e.message}")
      }
    }
  }

  private fun trimDirectCopy(inputPath: String, outputPath: String, startTimeInSeconds: Double, endTimeInSeconds: Double): String {
    val extractor = MediaExtractor()
    var muxer: MediaMuxer? = null

    try {
      // Set up extractor
      extractor.setDataSource(inputPath)

      // Find audio track
      var audioTrackIndex = -1
      var inputFormat: MediaFormat? = null
      for (i in 0 until extractor.trackCount) {
        val format = extractor.getTrackFormat(i)
        val mime = format.getString(MediaFormat.KEY_MIME)
        if (mime?.startsWith("audio/") == true) {
          extractor.selectTrack(i)
          audioTrackIndex = i
          inputFormat = format
          break
        }
      }

      if (inputFormat == null) {
        throw IOException("No audio track found")
      }

      // Create muxer
      muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
      val outputTrackIndex = muxer.addTrack(inputFormat)
      muxer.start()

      // Convert time to microseconds
      val startTimeUs = (startTimeInSeconds * 1_000_000).toLong()
      val endTimeUs = (endTimeInSeconds * 1_000_000).toLong()

      // Seek to start position
      extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

      // Allocate buffer
      val maxBufferSize = 1024 * 1024 // 1MB buffer
      val buffer = ByteBuffer.allocate(maxBufferSize)
      val bufferInfo = MediaCodec.BufferInfo()

      // Copy samples within time range
      while (true) {
        val sampleSize = extractor.readSampleData(buffer, 0)
        if (sampleSize < 0) {
          break
        }

        val sampleTime = extractor.sampleTime
        if (sampleTime > endTimeUs) {
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

      return outputPath

    } finally {
      try {
        muxer?.stop()
        muxer?.release()
        extractor.release()
      } catch (e: Exception) {
        Log.e(TAG, "Error releasing resources: ${e.message}")
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}