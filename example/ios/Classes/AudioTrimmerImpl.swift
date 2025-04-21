import Foundation
import AVFoundation

class AudioTrimmerImpl {
    func trimAudio(inputPath: String, outputPath: String, startTimeInSeconds: Double, endTimeInSeconds: Double) throws -> String {
        // Convert file paths to URLs
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Create output directory if it doesn't exist
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Remove existing output file if it exists
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(atPath: outputPath)
        }
        
        // Create AVAsset from input file
        let asset = AVAsset(url: inputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "com.levnext.native_audio_trimmer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"])
        }
        
        // Set up export parameters
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        // Set time range for trimming
        let startTime = CMTime(seconds: startTimeInSeconds, preferredTimescale: 1000)
        let endTime = CMTime(seconds: endTimeInSeconds, preferredTimescale: 1000)
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // Create a semaphore to wait for export completion
        let semaphore = DispatchSemaphore(value: 0)
        
        // Start export
        exportSession.exportAsynchronously {
            semaphore.signal()
        }
        
        // Wait for export to complete
        semaphore.wait()
        
        // Check for export errors
        if let error = exportSession.error {
            throw error
        }
        
        switch exportSession.status {
        case .completed:
            return outputPath
        case .failed:
            throw NSError(domain: "com.levnext.native_audio_trimmer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
        case .cancelled:
            throw NSError(domain: "com.levnext.native_audio_trimmer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"])
        default:
            throw NSError(domain: "com.levnext.native_audio_trimmer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export ended with status: \(exportSession.status.rawValue)"])
        }
    }
}