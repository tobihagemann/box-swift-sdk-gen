import Foundation

public class UploadFileVersionRequestBody {
    /// The additional attributes of the file being uploaded. Mainly the
    /// name and the parent folder. These attributes are part of the multi
    /// part request body and are in JSON format.
    /// 
    /// <Message warning>
    /// 
    ///   The `attributes` part of the body must come **before** the
    ///   `file` part. Requests that do not follow this format when
    ///   uploading the file will receive a HTTP `400` error with a
    ///   `metadata_after_file_contents` error code.
    /// 
    /// </Message>
    public let attributes: UploadFileVersionRequestBodyAttributesField

    /// The local file URL of the file to upload to Box.
    /// 
    /// <Message warning>
    /// 
    ///   The `attributes` part of the body must come **before** the
    ///   `file` part. Requests that do not follow this format when
    ///   uploading the file will receive a HTTP `400` error with a
    ///   `metadata_after_file_contents` error code.
    /// 
    /// </Message>
    public let fileURL: URL

    public let fileFileName: String?

    public let fileContentType: String?

    /// Initializer for a UploadFileVersionRequestBody.
    ///
    /// - Parameters:
    ///   - attributes: The additional attributes of the file being uploaded. Mainly the
    ///     name and the parent folder. These attributes are part of the multi
    ///     part request body and are in JSON format.
    ///     
    ///     <Message warning>
    ///     
    ///       The `attributes` part of the body must come **before** the
    ///       `file` part. Requests that do not follow this format when
    ///       uploading the file will receive a HTTP `400` error with a
    ///       `metadata_after_file_contents` error code.
    ///     
    ///     </Message>
    ///   - fileURL: The local file URL of the file to upload to Box.
    ///     
    ///     <Message warning>
    ///     
    ///       The `attributes` part of the body must come **before** the
    ///       `file` part. Requests that do not follow this format when
    ///       uploading the file will receive a HTTP `400` error with a
    ///       `metadata_after_file_contents` error code.
    ///     
    ///     </Message>
    ///   - fileFileName: 
    ///   - fileContentType: 
    public init(attributes: UploadFileVersionRequestBodyAttributesField, fileURL: URL, fileFileName: String? = nil, fileContentType: String? = nil) {
        self.attributes = attributes
        self.fileURL = fileURL
        self.fileFileName = fileFileName
        self.fileContentType = fileContentType
    }

}
