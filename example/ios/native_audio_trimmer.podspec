Pod::Spec.new do |s|
    s.name             = 'native_audio_trimmer'
    s.version          = '0.0.3'
    s.summary          = 'A Flutter plugin for trimming audio files on iOS'
    s.description      = <<-DESC
  A Flutter plugin for trimming audio files on iOS without using FFmpeg.
                         DESC
    s.homepage         = 'https://github.com/Ajitcool008/native_audio_trimmer'
    s.license          = { :type => 'MIT', :file => '../LICENSE' }
    s.author           = { 'Your Name' => 'your.email@example.com' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.dependency 'Flutter'
    s.platform = :ios, '11.0'
    s.swift_version = '5.0'
  end