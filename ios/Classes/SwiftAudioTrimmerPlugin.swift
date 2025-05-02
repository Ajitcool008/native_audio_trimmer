import Flutter
import UIKit
import AVFoundation

public class SwiftAudioTrimmerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "audio_trimmer", binaryMessenger: registrar.messenger())
    let instance = SwiftAudioTrimmerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "trimAudio" {
      guard let args = call.arguments as? [String: Any],
            let inputPath = args["inputPath"] as? String,
            let outputPath = args["outputPath"] as? String,
            let start = args["start"] as? Double,
            let end = args["end"] as? Double else {
        result(FlutterError(code: "INVALID_ARGUMENTS", 
                            message: "Missing or invalid arguments", 
                            details: nil))
        return
      }
      
      trimAudio(inputPath: inputPath, outputPath: outputPath, startTime: start, endTime: end) { success, error in
        if success {
          result("Audio trimmed successfully")
        } else {
          result(FlutterError(code: "TRIM_FAILED", 
                              message: "Failed to trim audio", 
                              details: error?.localizedDescription))
        }
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func trimAudio(inputPath: String, outputPath: String, startTime: Double, endTime: Double, completion: @escaping (Bool, Error?) -> Void) {
    // Verify input file exists
    let inputURL = URL(fileURLWithPath: inputPath)
    guard FileManager.default.fileExists(atPath: inputPath) else {
        let error = NSError(domain: "AudioTrimmer", code: 404, userInfo: [NSLocalizedDescriptionKey: "Input file does not exist"])
        completion(false, error)
        return
    }
    
    // Ensure output directory exists
    let outputURL = URL(fileURLWithPath: outputPath)
    let outputDirectory = outputURL.deletingLastPathComponent()
    
    do {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error creating directory: \(error.localizedDescription)")
        completion(false, error)
        return
    }
    
    // Remove any existing file at output path
    if FileManager.default.fileExists(atPath: outputPath) {
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
            print("Error removing existing file: \(error.localizedDescription)")
            // Continue anyway, the export might still work
        }
    }
    
    // Create AVAsset
    let asset = AVAsset(url: inputURL)
    
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
        let error = NSError(domain: "AudioTrimmer", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"])
        completion(false, error)
        return
    }
    
    // Set export session output URL and file type
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .m4a
    
    // Define the time range for trimming
    let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
    let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
    let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
    
    exportSession.timeRange = timeRange
    
    exportSession.exportAsynchronously {
      switch exportSession.status {
      case .completed:
        completion(true, nil)
      case .failed, .cancelled:
        completion(false, exportSession.error)
      default:
        completion(false, nil)
      }
    }
  }
}