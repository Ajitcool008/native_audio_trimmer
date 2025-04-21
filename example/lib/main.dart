import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:native_audio_trimmer/native_audio_trimmer.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _audioTrimmer = AudioTrimmer();
  String? _selectedFilePath;
  String? _trimmedFilePath;
  bool _isProcessing = false;
  final TextEditingController _startTimeController =
      TextEditingController(text: '0.0');
  final TextEditingController _endTimeController =
      TextEditingController(text: '10.0');
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Audio Trimmer Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _pickAudioFile,
                child: const Text('Select Audio File'),
              ),
              const SizedBox(height: 16),
              if (_selectedFilePath != null) ...[
                Text(
                  'Selected file: ${_selectedFilePath!.split('/').last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _playAudio(_selectedFilePath!),
                  child: Text(_isPlaying ? 'Stop Playing' : 'Play Original'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time (seconds)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'End Time (seconds)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _trimAudio,
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Trim Audio'),
                ),
              ],
              if (_trimmedFilePath != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Trimmed Audio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _playAudio(_trimmedFilePath!),
                  child:
                      Text(_isPlaying ? 'Stop Playing' : 'Play Trimmed Audio'),
                ),
                const SizedBox(height: 8),
                Text('Saved at: $_trimmedFilePath'),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() {
          _isPlaying = true;
        });
        // Update state when audio completes playing
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying = false;
          });
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error playing audio: ${e.toString()}';
      });
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _trimmedFilePath = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: ${e.toString()}';
      });
    }
  }

  Future<void> _trimAudio() async {
    if (_selectedFilePath == null) {
      setState(() {
        _errorMessage = 'Please select an audio file first';
      });
      return;
    }

    double? startTime = double.tryParse(_startTimeController.text);
    double? endTime = double.tryParse(_endTimeController.text);

    if (startTime == null || endTime == null) {
      setState(() {
        _errorMessage = 'Invalid start or end time';
      });
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      // Get the app's temporary directory for saving trimmed file
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/trimmed_audio.m4a';

      // Trim the audio
      final result = await _audioTrimmer.trimAudio(
        _selectedFilePath!,
        outputPath,
        startTime,
        endTime,
      );

      setState(() {
        _trimmedFilePath = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error trimming audio: ${e.toString()}';
      });
    }
  }
}
