import Foundation

/// A type that can decode from either a JSON number or a JSON string
struct FlexibleDouble: Codable, Equatable, Sendable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as Double first
        if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
            return
        }

        // Try decoding as String and converting
        if let stringValue = try? container.decode(String.self),
           let doubleValue = Double(stringValue) {
            self.value = doubleValue
            return
        }

        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected Double or String containing a number"
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// Optional flexible double
extension Optional where Wrapped == FlexibleDouble {
    var doubleValue: Double? {
        self?.value
    }
}
