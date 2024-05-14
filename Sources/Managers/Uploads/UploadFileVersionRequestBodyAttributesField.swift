import Foundation

public class UploadFileVersionRequestBodyAttributesField: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case contentModifiedAt = "content_modified_at"
    }

    /// An optional new name for the file. If specified, the file
    /// will be renamed when the new version is uploaded.
    public let name: String

    /// Defines the time the file was last modified at.
    /// 
    /// If not set, the upload time will be used.
    public let contentModifiedAt: Date?

    /// Initializer for a UploadFileVersionRequestBodyAttributesField.
    ///
    /// - Parameters:
    ///   - name: An optional new name for the file. If specified, the file
    ///     will be renamed when the new version is uploaded.
    ///   - contentModifiedAt: Defines the time the file was last modified at.
    ///     
    ///     If not set, the upload time will be used.
    public init(name: String, contentModifiedAt: Date? = nil) {
        self.name = name
        self.contentModifiedAt = contentModifiedAt
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        if let _contentModifiedAt = try container.decodeIfPresent(String.self, forKey: .contentModifiedAt) {
            contentModifiedAt = try Utils.Dates.dateTimeFromString(dateTime: _contentModifiedAt)
        } else {
            contentModifiedAt = nil
        }

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if let contentModifiedAt {
            try container.encode(Utils.Dates.dateTimeToString(dateTime: contentModifiedAt), forKey: .contentModifiedAt)
        }

    }

}
