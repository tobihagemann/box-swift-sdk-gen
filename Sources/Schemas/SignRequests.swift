import Foundation

/// A standard representation of a sign request, as returned from any Box Sign
/// API endpoints by default.
public class SignRequests: Codable {
    private enum CodingKeys: String, CodingKey {
        case limit
        case nextMarker = "next_marker"
        case entries
    }

    /// The limit that was used for these entries. This will be the same as the
    /// `limit` query parameter unless that value exceeded the maximum value
    /// allowed. The maximum value varies by API.
    public let limit: Int64?
    /// The marker for the start of the next page of results.
    public let nextMarker: String?
    /// A list of sign requests
    public let entries: [SignRequest]?

    /// Initializer for a SignRequests.
    ///
    /// - Parameters:
    ///   - limit: The limit that was used for these entries. This will be the same as the
    ///     `limit` query parameter unless that value exceeded the maximum value
    ///     allowed. The maximum value varies by API.
    ///   - nextMarker: The marker for the start of the next page of results.
    ///   - entries: A list of sign requests
    public init(limit: Int64? = nil, nextMarker: String? = nil, entries: [SignRequest]? = nil) {
        self.limit = limit
        self.nextMarker = nextMarker
        self.entries = entries
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        limit = try container.decodeIfPresent(Int64.self, forKey: .limit)
        nextMarker = try container.decodeIfPresent(String.self, forKey: .nextMarker)
        entries = try container.decodeIfPresent([SignRequest].self, forKey: .entries)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(nextMarker, forKey: .nextMarker)
        try container.encodeIfPresent(entries, forKey: .entries)
    }
}
