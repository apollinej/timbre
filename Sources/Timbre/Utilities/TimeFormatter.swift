import Foundation

enum TimeFormatter {
    /// Formats seconds as "M:SS" for short durations or "H:MM:SS" for long ones
    static func format(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Formats seconds as "MM:SS.ms" for precise timestamps
    static func formatPrecise(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        let ms = Int((seconds - Double(totalSeconds)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, secs, ms)
    }

    /// Formats for SRT subtitle format "HH:MM:SS,mmm"
    static func formatSRT(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        let ms = Int((seconds - Double(totalSeconds)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, ms)
    }
}
