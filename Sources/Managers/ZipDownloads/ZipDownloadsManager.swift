import Foundation

public class ZipDownloadsManager {
    public let auth: Authentication?
    public let networkSession: NetworkSession?

    public init(auth: Authentication? = nil, networkSession: NetworkSession? = nil) {
        self.auth = auth
        self.networkSession = networkSession
    }

    /// Creates a request to download multiple files and folders as a single `zip`
    /// archive file. This API does not return the archive but instead performs all
    /// the checks to ensure that the user has access to all the items, and then
    /// returns a `download_url` and a `status_url` that can be used to download the
    /// archive.
    /// 
    /// The limit for an archive is either the Account's upload limit or
    /// 10,000 files, whichever is met first.
    /// 
    /// **Note**: Downloading a large file can be
    /// affected by various
    /// factors such as distance, network latency,
    /// bandwidth, and congestion, as well as packet loss
    /// ratio and current server load.
    /// For these reasons we recommend that a maximum ZIP archive
    /// total size does not exceed 25GB.
    ///
    /// - Parameters:
    ///   - requestBody: Request body of createZipDownload method
    ///   - headers: Headers of createZipDownload method
    /// - Returns: The `ZipDownload`.
    /// - Throws: The `GeneralError`.
    public func createZipDownload(requestBody: ZipDownloadRequest, headers: CreateZipDownloadHeadersArg = CreateZipDownloadHeadersArg()) async throws -> ZipDownload {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/zip_downloads")", options: FetchOptions(method: "POST", headers: headersMap, body: requestBody.serialize(), contentType: "application/json", responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try ZipDownload.deserialize(from: response.text)
    }

    /// Returns the contents of a `zip` archive in binary format. This URL does not
    /// require any form of authentication and could be used in a user's browser to
    /// download the archive to a user's device.
    /// 
    /// By default, this URL is only valid for a few seconds from the creation of
    /// the request for this archive. Once a download has started it can not be
    /// stopped and resumed, instead a new request for a zip archive would need to
    /// be created.
    /// 
    /// The URL of this endpoint should not be considered as fixed. Instead, use
    /// the [Create zip download](e://post_zip_downloads) API to request to create a
    /// `zip` archive, and then follow the `download_url` field in the response to
    /// this endpoint.
    ///
    /// - Parameters:
    ///   - zipDownloadId: The unique identifier that represent this `zip` archive.
    ///     Example: "Lu6fA9Ob-jyysp3AAvMF4AkLEwZwAYbL=tgj2zIC=eK9RvJnJbjJl9rNh2qBgHDpyOCAOhpM=vajg2mKq8Mdd"
    ///   - downloadDestinationURL: The URL on disk where the file will be saved once it has been downloaded.
    ///   - headers: Headers of getZipDownloadContent method
    /// - Returns: The `URL`.
    /// - Throws: The `GeneralError`.
    public func getZipDownloadContent(zipDownloadId: String, downloadDestinationURL: URL, headers: GetZipDownloadContentHeadersArg = GetZipDownloadContentHeadersArg()) async throws -> URL {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://dl.boxcloud.com/2.0/zip_downloads/")\(zipDownloadId)\("/content")", options: FetchOptions(method: "GET", headers: headersMap, downloadDestinationURL: downloadDestinationURL, responseFormat: "binary", auth: self.auth, networkSession: self.networkSession))
        return response.downloadDestinationURL!
    }

    /// Returns the download status of a `zip` archive, allowing an application to
    /// inspect the progress of the download as well as the number of items that
    /// might have been skipped.
    /// 
    /// This endpoint can only be accessed once the download has started.
    /// Subsequently this endpoint is valid for 12 hours from the start of the
    /// download.
    /// 
    /// The URL of this endpoint should not be considered as fixed. Instead, use
    /// the [Create zip download](e://post_zip_downloads) API to request to create a
    /// `zip` archive, and then follow the `status_url` field in the response to
    /// this endpoint.
    ///
    /// - Parameters:
    ///   - zipDownloadId: The unique identifier that represent this `zip` archive.
    ///     Example: "Lu6fA9Ob-jyysp3AAvMF4AkLEwZwAYbL=tgj2zIC=eK9RvJnJbjJl9rNh2qBgHDpyOCAOhpM=vajg2mKq8Mdd"
    ///   - headers: Headers of getZipDownloadStatus method
    /// - Returns: The `ZipDownloadStatus`.
    /// - Throws: The `GeneralError`.
    public func getZipDownloadStatus(zipDownloadId: String, headers: GetZipDownloadStatusHeadersArg = GetZipDownloadStatusHeadersArg()) async throws -> ZipDownloadStatus {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/zip_downloads/")\(zipDownloadId)\("/status")", options: FetchOptions(method: "GET", headers: headersMap, responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try ZipDownloadStatus.deserialize(from: response.text)
    }

}
