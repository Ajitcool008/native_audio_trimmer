import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_audio_trimmer/native_audio_trimmer.dart';

void main() {
  const MethodChannel channel = MethodChannel('audio_trimmer');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return 'Audio trimmed successfully';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('trimAudio', () async {
    expect(
      await NativeAudioTrimmer.trimAudio(
        inputPath: '/test/input.mp3',
        outputPath: '/test/output.m4a',
        startTimeInSeconds: 0.0,
        endTimeInSeconds: 10.0,
      ),
      'Audio trimmed successfully',
    );
  });
}
