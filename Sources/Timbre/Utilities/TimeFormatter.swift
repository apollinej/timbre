import Foundation

enum TimeFormatter {
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

    static func formatSRT(_ seconds: TimeInterval) -> String {
        let totalMs = Int(seconds * 1000)
        let hours = totalMs / 3_600_000
        let minutes = (totalMs % 3_600_000) / 60_000
        let secs = (totalMs % 60_000) / 1_000
        let ms = totalMs % 1_000
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, ms)
    }
}
