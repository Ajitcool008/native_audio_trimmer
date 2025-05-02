#import "AudioTrimmerPlugin.h"
#if __has_include(<native_audio_trimmer/native_audio_trimmer-Swift.h>)
#import <native_audio_trimmer/native_audio_trimmer-Swift.h>
#else
#import "native_audio_trimmer-Swift.h"
#endif

@implementation AudioTrimmerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioTrimmerPlugin registerWithRegistrar:registrar];
}
@end