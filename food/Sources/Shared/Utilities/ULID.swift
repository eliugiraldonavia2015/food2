import Foundation

public struct ULID {
    private static let crockford: [Character] = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    
    public static func new() -> String {
        let timeMs = UInt64(Date().timeIntervalSince1970 * 1000.0)
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = UInt8((timeMs >> 40) & 0xFF)
        bytes[1] = UInt8((timeMs >> 32) & 0xFF)
        bytes[2] = UInt8((timeMs >> 24) & 0xFF)
        bytes[3] = UInt8((timeMs >> 16) & 0xFF)
        bytes[4] = UInt8((timeMs >> 8) & 0xFF)
        bytes[5] = UInt8(timeMs & 0xFF)
        for i in 6..<16 {
            bytes[i] = UInt8.random(in: 0...255)
        }
        return encodeBase32(bytes)
    }
    
    private static func encodeBase32(_ data: [UInt8]) -> String {
        var bits: UInt32 = 0
        var bitCount: Int = 0
        var output = [Character]()
        for b in data {
            bits = (bits << 8) | UInt32(b)
            bitCount += 8
            while bitCount >= 5 {
                let index = Int((bits >> UInt32(bitCount - 5)) & 0x1F)
                output.append(crockford[index])
                bitCount -= 5
            }
        }
        if bitCount > 0 {
            let index = Int((bits << UInt32(5 - bitCount)) & 0x1F)
            output.append(crockford[index])
        }
        if output.count > 26 {
            return String(output.prefix(26))
        } else if output.count < 26 {
            return String(output + Array(repeating: crockford[0], count: 26 - output.count))
        }
        return String(output)
    }
}
