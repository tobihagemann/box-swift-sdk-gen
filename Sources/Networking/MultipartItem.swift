import Foundation

/// Representation of a single multipart form part.
public class MultipartItem {

    /// The name of the multipart item.
    public let partName: String

    /// The content of the part body.
    public let data: SerializedData?

    /// The local file URL containing the file to be uploaded.
    public let fileURL: URL?

    /// The name of the file.
    public let fileName: String?

    /// The content type of the part.
    public let contentType: String?

    /// Initialize a multipart.
    ///
    /// - Parameters:
    ///   - partName: The name of the part.
    ///   - data: The content of the part body.
    ///   - fileURL: The local file URL containing the file to be uploaded.
    ///   - fileName: The name of the file.
    ///   - contentType: The content type of the part.
    public init(
        partName: String,
        data: SerializedData? = nil,
        fileURL: URL? = nil,
        fileName: String? = nil,
        contentType: String? = nil
    ) {
        self.partName = partName
        self.data = data
        self.fileURL = fileURL
        self.fileName = fileName
        self.contentType = contentType
    }
}
