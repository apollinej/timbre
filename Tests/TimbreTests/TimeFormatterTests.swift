import XCTest
@testable import Timbre

final class TimeFormatterTests: XCTestCase {
    func testFormatSeconds() {
        XCTAssertEqual(TimeFormatter.format(0), "0:00")
        XCTAssertEqual(TimeFormatter.format(65), "1:05")
        XCTAssertEqual(TimeFormatter.format(3661), "1:01:01")
    }

    func testFormatSRT() {
        XCTAssertEqual(TimeFormatter.formatSRT(0), "00:00:00,000")
        XCTAssertEqual(TimeFormatter.formatSRT(65.5), "00:01:05,500")
        XCTAssertEqual(TimeFormatter.formatSRT(3661.123), "01:01:01,123")
    }
}
