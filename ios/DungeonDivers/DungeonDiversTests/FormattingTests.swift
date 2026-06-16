import XCTest
@testable import DungeonDivers

final class FormattingTests: XCTestCase {
    func testSmallNumbersExact() {
        XCTAssertEqual(Formatting.short(0), "0")
        XCTAssertEqual(Formatting.short(42), "42")
        XCTAssertEqual(Formatting.short(999), "999")
    }

    func testThousandsAndUp() {
        XCTAssertEqual(Formatting.short(1000), "1.00K")
        XCTAssertEqual(Formatting.short(1500), "1.50K")
        XCTAssertEqual(Formatting.short(12345), "12.3K")
        XCTAssertEqual(Formatting.short(250_000), "250K")
        XCTAssertEqual(Formatting.short(1_000_000), "1.00M")
        XCTAssertEqual(Formatting.short(2_500_000_000), "2.50B")
    }
}
