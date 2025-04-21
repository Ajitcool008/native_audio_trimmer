import Foundation
import AVFoundation

class AudioTrimmerImpl {
    /**
     Trims an audio file between specified start and end times.
     
     - Parameters:
        - inputPath: Path to the source audio file
        - outputPath: Path where the trimmed audio file will be saved
        - startTimeInSeconds: Start time for trimming in seconds
        - endTimeInSeconds: End time for trimming in seconds
        - completion: Completion handler that returns the output path or an error
     */
    func trimAudio(
        inputPath: String,
        outputPath: String,
        startTimeInSeconds: Double,
        endTimeInSeconds: Double,
        completion: @escaping (String?, Error?) -> Void
    ) {
        // Create output directory if it doesn't exist
        let outputURL = URL(fileURLWithPath: outputPath)
        let outputDirectory = outputURL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(at: outputDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            NSLog("Error creating output directory: \(error.localizedDescription)")
            completion(nil, error)
            return
        }
        
        // Create asset from input URL
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            let error = NSError(domain: "com.levnext.native_audio_trimmer", 
                               code: -1, 
                               userInfo: [NSLocalizedDescriptionKey: "Could not create export session"])
            completion(nil, error)
            return
        }
        
        // Define the time range to export
        let startTime = CMTime(seconds: startTimeInSeconds, preferredTimescale: 1000)
        let endTime = CMTime(seconds: endTimeInSeconds, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: outputPath) {
            do {
                try FileManager.default.removeItem(atPath: outputPath)
            } catch {
                NSLog("Error removing existing file: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
        }
        
        // Configure export session
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .m4a
        exportSession.timeRange = timeRange
        
        // Start the export process
        exportSession.exportAsynchronously { [weak exportSession] in
            guard let exportSession = exportSession else {
                let error = NSError(domain: "com.levnext.native_audio_trimmer", 
                                   code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "Export session was deallocated"])
                completion(nil, error)
                return
            }
            
            switch exportSession.status {
            case .completed:
                NSLog("Audio trimming completed successfully")
                completion(outputPath, nil)
            case .failed:
                NSLog("Audio trimming failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                completion(nil, exportSession.error)
            case .cancelled:
                NSLog("Audio trimming was cancelled")
                let error = NSError(domain: "com.levnext.native_audio_trimmer", 
                                   code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "Export was cancelled"])
                completion(nil, error)
            default:
                NSLog("Audio trimming ended with status: \(exportSession.status.rawValue)")
                let error = NSError(domain: "com.levnext.native_audio_trimmer", 
                                   code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "Export ended with unexpected status"])
                completion(nil, error)
            }
        }
    }
}