import XCTest
@testable import food

final class ULIDTests: XCTestCase {
    func testULIDLengthAndAlphabet() {
        let id = ULID.new()
        XCTAssertEqual(id.count, 26)
        let allowed = CharacterSet(charactersIn: "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        for ch in id {
            let s = String(ch)
            XCTAssertNotNil(s.rangeOfCharacter(from: allowed))
        }
    }
}
