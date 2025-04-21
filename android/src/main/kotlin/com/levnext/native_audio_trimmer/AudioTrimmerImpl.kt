package com.levnext.native_audio_trimmer

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.nio.ByteBuffer

class AudioTrimmerImpl {
    companion object {
        private const val TAG = "AudioTrimmerImpl"
        private const val BUFFER_SIZE = 1024 * 1024 // 1MB buffer size
    }

    /**
     * Trims an audio file between specified start and end times.
     *
     * @param inputPath Path to the source audio file
     * @param outputPath Path where the trimmed audio file will be saved
     * @param startTimeInSeconds Start time for trimming in seconds
     * @param endTimeInSeconds End time for trimming in seconds
     * @return Path to the trimmed output file
     */
    fun trimAudio(
        inputPath: String,
        outputPath: String,
        startTimeInSeconds: Double,
        endTimeInSeconds: Double
    ): String {
        Log.d(TAG, "Trimming audio from $startTimeInSeconds to $endTimeInSeconds seconds")
        
        // Convert seconds to microseconds
        val startTimeUs = (startTimeInSeconds * 1_000_000).toLong()
        val endTimeUs = (endTimeInSeconds * 1_000_000).toLong()
        
        // Ensure output directory exists
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        
        // If the output file already exists, delete it to avoid conflicts
        if (outputFile.exists()) {
            outputFile.delete()
        }
        
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        
        try {
            // Set up the MediaExtractor
            extractor.setDataSource(inputPath)
            
            // Find the audio track and select it
            var audioTrackIndex = -1
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    extractor.selectTrack(i)
                    audioTrackIndex = i
                    break
                }
            }
            
            if (audioTrackIndex == -1) {
                throw Exception("No audio track found in the input file")
            }
            
            // Get the audio format
            val originalFormat = extractor.getTrackFormat(audioTrackIndex)
            
            // Create a new MediaMuxer for the output file
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val outputAudioTrackIndex = muxer.addTrack(originalFormat)
            muxer.start()
            
            // Seek to the start position
            extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
            
            // Prepare buffer for reading
            val byteBuffer = ByteBuffer.allocate(BUFFER_SIZE)
            val bufferInfo = MediaCodec.BufferInfo()
            
            // Extract and write audio samples
            while (true) {
                // Read a sample from extractor
                val sampleSize = extractor.readSampleData(byteBuffer, 0)
                
                // Check if we've reached the end
                if (sampleSize < 0) {
                    break
                }
                
                // Get the current sample time
                val currentTime = extractor.sampleTime
                
                // If we've reached the end time, stop processing
                if (currentTime > endTimeUs) {
                    break
                }
                
                // Set the buffer info
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = currentTime - startTimeUs // Adjust presentation time
                bufferInfo.offset = 0
                bufferInfo.flags = extractor.sampleFlags
                
                // Write the sample to the muxer
                muxer.writeSampleData(outputAudioTrackIndex, byteBuffer, bufferInfo)
                
                // Advance to the next sample
                extractor.advance()
            }
            
            // Everything went well, return the output path
            return outputPath
            
        } catch (e: Exception) {
            Log.e(TAG, "Error trimming audio: ${e.message}", e)
            // Clean up partial files on error
            if (outputFile.exists()) {
                outputFile.delete()
            }
            throw e
        } finally {
            // Clean up resources
            try {
                extractor.release()
                muxer?.stop()
                muxer?.release()
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing resources: ${e.message}", e)
            }
        }
    }
}