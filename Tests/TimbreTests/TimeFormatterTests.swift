import Testing
@testable import Timbre

@Suite("TimeFormatter Tests")
struct TimeFormatterTests {
    @Test("Formats seconds correctly")
    func formatSeconds() {
        #expect(TimeFormatter.format(0) == "0:00")
        #expect(TimeFormatter.format(65) == "1:05")
        #expect(TimeFormatter.format(3661) == "1:01:01")
    }

    @Test("Formats SRT timestamps correctly")
    func formatSRT() {
        #expect(TimeFormatter.formatSRT(0) == "00:00:00,000")
        #expect(TimeFormatter.formatSRT(65.5) == "00:01:05,500")
        #expect(TimeFormatter.formatSRT(3661.123) == "01:01:01,123")
    }
}
