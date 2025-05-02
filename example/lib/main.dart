import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_audio_trimmer/native_audio_trimmer.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _trimStatus = 'Idle';
  String? _selectedFilePath;
  String? _outputFilePath;
  bool _isLoading = false;
  double _startTime = 0.0;
  double _endTime = 5.0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _trimStatus = 'File selected: ${_selectedFilePath!.split('/').last}';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _trimStatus = 'Failed to pick file: ${e.message}';
      });
    }
  }

  Future<void> _trimAudio() async {
    if (_selectedFilePath == null) {
      setState(() {
        _trimStatus = 'Please select an audio file first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _trimStatus = 'Trimming...';
    });

    try {
      // Get temp directory to save the trimmed file
      final directory = await getTemporaryDirectory();
      final outputPath =
          '${directory.path}/trimmed_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _outputFilePath = outputPath;

      // Trim audio
      final result = await NativeAudioTrimmer.trimAudio(
        inputPath: _selectedFilePath!,
        outputPath: outputPath,
        startTimeInSeconds: _startTime,
        endTimeInSeconds: _endTime,
      );

      setState(() {
        _trimStatus = 'Trim result: $result\nOutput: $outputPath';
      });
    } on PlatformException catch (e) {
      setState(() {
        _trimStatus = 'Failed to trim: ${e.message}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Audio Trimmer Example')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _pickAudioFile,
                child: const Text('Select Audio File'),
              ),
              const SizedBox(height: 20),
              if (_selectedFilePath != null) ...[
                Text(
                  'File: ${_selectedFilePath!.split('/').last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Start Time (seconds):'),
                Slider(
                  value: _startTime,
                  min: 0,
                  max: 60,
                  divisions: 60,
                  label: _startTime.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _startTime = value;
                    });
                  },
                ),
                const Text('End Time (seconds):'),
                Slider(
                  value: _endTime,
                  min: 0,
                  max: 60,
                  divisions: 60,
                  label: _endTime.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _endTime = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _trimAudio,
                  child: const Text('Trim Audio'),
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Text(_trimStatus),
              if (_outputFilePath != null &&
                  File(_outputFilePath!).existsSync()) ...[
                const SizedBox(height: 20),
                const Text(
                  'Trimmed Audio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Here you could add audio player widget to play the trimmed file
                Text(
                  'File size: ${(File(_outputFilePath!).lengthSync() / 1024).toStringAsFixed(2)} KB',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
