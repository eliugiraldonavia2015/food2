import Foundation
import CryptoKit

enum StableUUID {
    static func fromString(_ value: String) -> UUID {
        let digest = SHA256.hash(data: Data(value.utf8))
        let bytes = Array(digest)
        let uuidBytes: [UInt8] = Array(bytes.prefix(16))
        let uuid = uuidBytes.withUnsafeBytes { rawBuffer -> UUID in
            let tuple = rawBuffer.bindMemory(to: UInt8.self)
            return UUID(uuid: (
                tuple[0], tuple[1], tuple[2], tuple[3],
                tuple[4], tuple[5],
                tuple[6], tuple[7],
                tuple[8], tuple[9],
                tuple[10], tuple[11], tuple[12], tuple[13], tuple[14], tuple[15]
            ))
        }
        return uuid
    }
}

