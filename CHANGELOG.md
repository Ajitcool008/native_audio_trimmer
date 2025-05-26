# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0

* **STABLE RELEASE** - First major version with comprehensive testing
* Fixed MP3 file compatibility issues on both iOS and Android
* Improved audio format detection and error handling
* Enhanced performance for large audio files
* Better memory management during trimming operations
* Updated documentation with detailed examples
* Added comprehensive error messages for debugging

## 0.0.5

* Initial release
* Implemented trimAudio method for iOS and Android platforms
* Added support for trimming audio files without FFmpeg
* iOS implementation using AVAssetExportSession
* Android implementation using MediaExtractor, MediaCodec, and MediaMuxer
* Example app demonstrating plugin usage