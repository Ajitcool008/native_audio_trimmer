# native_audio_trimmer

A Flutter plugin for trimming audio files on both Android and iOS platforms without using FFmpeg.

## Features

- Trim audio files by specifying start and end times
- Native implementation for iOS (using AVAssetExportSession)
- Native implementation for Android (using MediaExtractor, MediaCodec, and MediaMuxer)
- No FFmpeg dependency, resulting in smaller app size and faster builds
- Support for multiple audio formats

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  native_audio_trimmer: ^0.0.1
```

### Android

Add the storage permissions to your `AndroidManifest.xml` if you're targeting Android 12 or below and need to access files outside of your app's directory:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

For Android 13+ (API level 33+), you may need to request more specific permissions depending on your use case:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### iOS

No additional setup is required for iOS.

## Usage

```dart
import 'package:native_audio_trimmer/native_audio_trimmer.dart';

// Create an instance of AudioTrimmer
final audioTrimmer = AudioTrimmer();

// Trim an audio file
try {
  String inputPath = '/path/to/input.mp3';
  String outputPath = '/path/to/output.m4a';
  
  // Trim from 10 seconds to 30 seconds
  String trimmedFilePath = await audioTrimmer.trimAudio(
    inputPath,
    outputPath,
    10.0, // Start time in seconds
    30.0, // End time in seconds
  );
  
  print('Trimmed audio saved at: $trimmedFilePath');
} catch (e) {
  print('Error trimming audio: $e');
}
```

## Example

Check out the example app in the [example](./example) folder to see a complete implementation of audio file selection, trimming, and playback.

To run the example app:

```
cd example
flutter run
```

## Implementation Details

### iOS

On iOS, this plugin uses the native `AVAssetExportSession` to perform audio trimming operations. The resulting audio file is saved in the `.m4a` format.

### Android

On Android, the plugin uses a combination of `MediaExtractor`, `MediaCodec`, and `MediaMuxer` to extract, process, and save the audio data between the specified start and end times.

## Supported Formats

### Input Formats
- MP3
- M4A/AAC
- WAV
- OGG (Android only)
- FLAC

### Output Format
- M4A (AAC) for both platforms

## Limitations

- The plugin currently only outputs to M4A format
- Very large audio files may require additional memory
- Some exotic audio formats might not be supported by the native APIs

## Contributing

Contributions are welcome! If you find a bug or want a feature, please open an issue on GitHub.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.