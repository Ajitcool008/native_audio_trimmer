import 'dart:async';

import 'package:flutter/services.dart';

class NativeAudioTrimmer {
  static const MethodChannel _channel = MethodChannel('audio_trimmer');

  /// Trims an audio file.
  ///
  /// [inputPath] is the path to the source audio file.
  /// [outputPath] is the path where the trimmed audio file will be saved.
  /// [startTimeInSeconds] is the start time of the trim in seconds.
  /// [endTimeInSeconds] is the end time of the trim in seconds.
  ///
  /// Returns a Future that completes with a string message on success.
  /// Throws a PlatformException if trimming fails.
  static Future<String> trimAudio({
    required String inputPath,
    required String outputPath,
    required double startTimeInSeconds,
    required double endTimeInSeconds,
  }) async {
    final result = await _channel.invokeMethod('trimAudio', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'start': startTimeInSeconds,
      'end': endTimeInSeconds,
    });

    return result;
  }
}
