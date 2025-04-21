#
# To learn more about a Podspec, see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
    s.name             = 'native_audio_trimmer'
    s.version          = '0.0.1'
    s.summary          = 'A Flutter plugin for trimming audio files on iOS and Android without using FFmpeg.'
    s.description      = <<-DESC
  A Flutter plugin for trimming audio files on iOS and Android platforms using native APIs without relying on FFmpeg.
                         DESC
    s.homepage         = 'https://github.com/yourusername/native_audio_trimmer'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Your Company' => 'your-email@example.com' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.public_header_files = 'Classes/**/*.h'
    s.dependency 'Flutter'
    
    # Swift version
    s.swift_version = '5.0'
    
    # iOS deployment target
    s.platform = :ios, '11.0'
    
    # Flutter.framework does not contain a i386 slice.
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  end