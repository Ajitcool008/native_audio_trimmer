import 'package:flutter/services.dart';

/// A Flutter plugin that provides audio trimming functionality
/// using native platform implementations (no FFmpeg).
class AudioTrimmer {
  static const MethodChannel _channel = MethodChannel('native_audio_trimmer');

  /// Trims an audio file between the specified start and end times.
  ///
  /// [inputPath] - The path to the input audio file that needs to be trimmed.
  /// [outputPath] - The path where the trimmed audio file will be saved.
  /// [startTimeInSeconds] - The start time in seconds from where to begin trimming.
  /// [endTimeInSeconds] - The end time in seconds where to stop trimming.
  ///
  /// Returns a [Future] that completes with the path of the trimmed audio file
  /// on success, or throws a [PlatformException] on failure.
  Future<String> trimAudio(
    String inputPath,
    String outputPath,
    double startTimeInSeconds,
    double endTimeInSeconds,
  ) async {
    // Validate input parameters
    if (inputPath.isEmpty) {
      throw ArgumentError('Input path cannot be empty');
    }
    if (outputPath.isEmpty) {
      throw ArgumentError('Output path cannot be empty');
    }
    if (startTimeInSeconds < 0) {
      throw ArgumentError('Start time cannot be negative');
    }
    if (endTimeInSeconds <= startTimeInSeconds) {
      throw ArgumentError('End time must be greater than start time');
    }

    try {
      final String result = await _channel.invokeMethod('trimAudio', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'startTime': startTimeInSeconds,
        'endTime': endTimeInSeconds,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to trim audio: ${e.message}');
    }
  }
}
