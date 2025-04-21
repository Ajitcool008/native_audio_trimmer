import Flutter
import UIKit
import AVFoundation

public class NativeAudioTrimmerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_audio_trimmer", binaryMessenger: registrar.messenger())
    let instance = NativeAudioTrimmerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "trimAudio":
      guard let args = call.arguments as? [String: Any],
            let inputPath = args["inputPath"] as? String,
            let outputPath = args["outputPath"] as? String,
            let startTime = args["startTime"] as? Double,
            let endTime = args["endTime"] as? Double else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Required arguments missing", details: nil))
        return
      }
      
      do {
        let audioTrimmer = AudioTrimmerImpl()
        let trimmedPath = try audioTrimmer.trimAudio(inputPath: inputPath, outputPath: outputPath, startTimeInSeconds: startTime, endTimeInSeconds: endTime)
        result(trimmedPath)
      } catch {
        result(FlutterError(code: "TRIM_ERROR", message: "Failed to trim audio: \(error.localizedDescription)", details: nil))
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}