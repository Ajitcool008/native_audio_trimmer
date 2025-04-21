import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_audio_trimmer/native_audio_trimmer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioTrimmer', () {
    late AudioTrimmer audioTrimmer;
    late List<MethodCall> log;

    setUp(() {
      audioTrimmer = AudioTrimmer();
      log = <MethodCall>[];

      // Set up method channel mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_audio_trimmer'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'trimAudio':
              return methodCall.arguments['outputPath'] as String;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_audio_trimmer'),
        null,
      );
    });

    test('trimAudio calls platform method with correct arguments', () async {
      const String inputPath = '/path/to/input.mp3';
      const String outputPath = '/path/to/output.m4a';
      const double startTime = 10.0;
      const double endTime = 20.0;

      final String result = await audioTrimmer.trimAudio(
        inputPath,
        outputPath,
        startTime,
        endTime,
      );

      expect(log, hasLength(1));
      expect(log.first.method, 'trimAudio');
      expect(log.first.arguments['inputPath'], inputPath);
      expect(log.first.arguments['outputPath'], outputPath);
      expect(log.first.arguments['startTime'], startTime);
      expect(log.first.arguments['endTime'], endTime);
      expect(result, outputPath);
    });

    test('trimAudio throws ArgumentError with invalid input', () async {
      expect(
        () => audioTrimmer.trimAudio('', '/path/to/output.m4a', 10.0, 20.0),
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', 'Input path cannot be empty')),
      );

      expect(
        () => audioTrimmer.trimAudio('/path/to/input.mp3', '', 10.0, 20.0),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', 'Output path cannot be empty')),
      );

      expect(
        () => audioTrimmer.trimAudio(
            '/path/to/input.mp3', '/path/to/output.m4a', -1.0, 20.0),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', 'Start time cannot be negative')),
      );

      expect(
        () => audioTrimmer.trimAudio(
            '/path/to/input.mp3', '/path/to/output.m4a', 20.0, 10.0),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
            'End time must be greater than start time')),
      );
    });
  });
}
