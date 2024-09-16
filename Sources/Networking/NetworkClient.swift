import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum HTTPHeaderKey {
    static let authorization = "Authorization"
    static let contentType = "Content-Type"
    static let retryAfter = "Retry-After"
}

enum HTTPHeaderContentTypeValue {
    static let urlEncoded = "application/x-www-form-urlencoded"
}

/// Networking layer interface
public class NetworkClient: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    public static let shared = NetworkClient()

    private let utilityQueue = DispatchQueue.global(qos: .utility)
    private let continuationQueue = DispatchQueue(label: "BoxSdkGen.NetworkClient.continuationQueue.\(UUID().uuidString)")
    private var taskInfos: [Int: TaskInfo] = [:]

    private override init() {
        super.init()
    }

    /// Executes requests
    ///
    /// - Parameters:
    ///   - options: Request options  that provides request-specific information, such as the request type, and body, query parameters.
    ///   - isUpload: A flag indicating whether this is an upload request.
    /// - Returns: Response of the request in the form of FetchResponse object.
    /// - Throws: An error if the request fails for any reason.
    public func fetch(options: FetchOptions, isUpload: Bool = false) async throws -> FetchResponse {
        return try await fetch(
            options: options,
            networkSession: options.networkSession ?? NetworkSession(),
            attempt: 1,
            isUpload: isUpload
        )
    }

    /// Executes requests
    ///
    /// - Parameters:
    ///   - options: Request options  that provides request-specific information, such as the request type, and body, query parameters.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with a network configuration parameters used in network communication.
    ///   - attempt: The request attempt number.
    ///   - isUpload: A flag indicating whether this is an upload request.
    /// - Returns: Response of the request in the form of FetchResponse object.
    /// - Throws: An error if the request fails for any reason.
    private func fetch(
        options: FetchOptions,
        networkSession: NetworkSession,
        attempt: Int,
        isUpload: Bool
    ) async throws -> FetchResponse {
        let urlRequest = try await createRequest(
            options: options,
            networkSession: networkSession
        )

        if let downloadDestinationURL = options.downloadDestinationURL {
            let (downloadUrl, urlResponse) = try await sendDownloadRequest(urlRequest, downloadDestinationURL: downloadDestinationURL, networkSession: networkSession)
            let conversation = FetchConversation(options: options, urlRequest: urlRequest, urlResponse: urlResponse as! HTTPURLResponse, responseType: .url(downloadUrl))
            return try await processResponse(using: conversation, networkSession: networkSession, attempt: attempt, isUpload: isUpload)
        } else if isUpload {
            let (data, urlResponse) = try await sendUploadRequest(urlRequest, options: options, networkSession: networkSession)
            let conversation = FetchConversation(options: options, urlRequest: urlRequest, urlResponse: urlResponse as! HTTPURLResponse, responseType: .data(data))
            return try await processResponse(using: conversation, networkSession: networkSession, attempt: attempt, isUpload: isUpload)
        } else {
            let (data, urlResponse) = try await sendDataRequest(urlRequest, networkSession: networkSession)
            let conversation = FetchConversation(options: options, urlRequest: urlRequest, urlResponse: urlResponse as! HTTPURLResponse, responseType: .data(data))
            return try await processResponse(using: conversation, networkSession: networkSession, attempt: attempt, isUpload: isUpload)
        }
    }

    /// Executes data request using dataTask and converts its callback-based API into an async API.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with network configuration parameters used in network communication.
    /// - Returns: Tuple of (Data, URLResponse)
    /// - Throws: An error if the request fails for any reason.
    private func sendDataRequest(_ urlRequest: URLRequest, networkSession: NetworkSession) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            continuationQueue.sync {
                let task = networkSession.session.dataTask(with: urlRequest)
                let taskInfo = DataTaskInfo(continuation: continuation)
                taskInfos[task.taskIdentifier] = taskInfo
                task.resume()
            }
        }
    }

    /// Executes download request using downloadTask and converts its callback-based API into an async API.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - downloadDestinationURL: The local URL where the downloaded file should be moved.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with network configuration parameters used in network communication.
    /// - Returns: Tuple of (URL, URLResponse)
    /// - Throws: An error if the request fails for any reason.
    private func sendDownloadRequest(_ urlRequest: URLRequest, downloadDestinationURL: URL, networkSession: NetworkSession) async throws -> (URL, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            continuationQueue.sync {
                let task = networkSession.session.downloadTask(with: urlRequest)
                let taskInfo = DownloadTaskInfo(continuation: continuation, destinationURL: downloadDestinationURL)
                taskInfos[task.taskIdentifier] = taskInfo
                task.resume()
            }
        }
    }

    /// Executes upload request using uploadTask and converts its delegate-based API into an async API.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with network configuration parameters used in network communication.
    /// - Returns: Tuple of (Data, URLResponse)
    /// - Throws: An error if the request fails for any reason.
    private func sendUploadRequest(_ urlRequest: URLRequest, options: FetchOptions, networkSession: NetworkSession) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            continuationQueue.sync {
                if let serializedData = options.data {
                    let task = networkSession.session.uploadTask(with: urlRequest, from: serializedData.data)
                    let taskInfo = DataTaskInfo(continuation: continuation)
                    taskInfos[task.taskIdentifier] = taskInfo
                    task.resume()
                } else if let fileURL = options.fileURL {
                    let task = networkSession.session.uploadTask(with: urlRequest, fromFile: fileURL)
                    let taskInfo = DataTaskInfo(continuation: continuation)
                    taskInfos[task.taskIdentifier] = taskInfo
                    task.resume()
                } else if let multipartData = options.multipartData {
                    do {
                        var mutableRequest = urlRequest
                        let tempFileURL = try updateRequestWithMultipartData(&mutableRequest, multipartData: multipartData)
                        let task = networkSession.session.uploadTask(with: mutableRequest, fromFile: tempFileURL)
                        let taskInfo = DataTaskInfo(continuation: continuation, multipartTempFileURL: tempFileURL)
                        taskInfos[task.taskIdentifier] = taskInfo
                        task.resume()
                    } catch {
                        continuation.resume(throwing: error)
                        return
                    }
                }
            }
        }
    }

    /// Updates the passed request object `URLRequest` with multipart data, based on parameters passed in `multipartData`.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - multipartData: An array of `MultipartItem` which will be used to create the body of the request.
    /// - Returns: The URL of the multipart file created.
    /// - Throws: An error if writing fails.
    private func updateRequestWithMultipartData(_ urlRequest: inout URLRequest, multipartData: [MultipartItem]) throws -> URL {
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: HTTPHeaderKey.contentType)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        return try createMultipartFile(multipartData: multipartData, boundary: boundary)
    }

    /// Creates a multipart/form-data file based on passed arguments.
    ///
    /// - Parameters:
    ///   - multipartData: Array of `MultipartItem`.
    ///   - boundary: The boundary string.
    /// - Throws: An error if writing fails.
    /// - Returns: The URL of the multipart file created.
    private func createMultipartFile(multipartData: [MultipartItem], boundary: String) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outputStream = OutputStream(url: fileURL, append: false)!
        outputStream.open()
        defer { outputStream.close() }
        for part in multipartData {
            try outputStream.write("--\(boundary)\r\n")
            if let serializedData = part.data {
                try outputStream.write("Content-Disposition: form-data; name=\"\(part.partName)\"\r\n\r\n")
                try outputStream.write(Utils.Strings.from(data: try serializedData.toJson()))
                try outputStream.write("\r\n")
            } else if let fileURL = part.fileURL {
                try outputStream.write("Content-Disposition: form-data; name=\"\(part.partName)\"; filename=\"\(part.fileName ?? "")\"\r\n")
                try outputStream.write("Content-Type: \(part.contentType ?? "")\r\n\r\n")
                try outputStream.write(contentsOf: fileURL)
                try outputStream.write("\r\n")
            }
        }
        try outputStream.write("--\(boundary)--\r\n")
        return fileURL
    }

    /// Creates the `URLRequest` based on the provided `FetchOptions`.
    ///
    /// - Parameters:
    ///   - options: Fetch options.
    ///   - networkSession: Networking session configuration.
    /// - Returns: Configured `URLRequest`.
    /// - Throws: An error if the operation fails.
    private func createRequest(
        options: FetchOptions,
        networkSession: NetworkSession
    ) async throws -> URLRequest {
        var urlRequest = URLRequest(url: createEndpointUrl(url: options.url, params: options.params))
        urlRequest.httpMethod = options.method.rawValue

        try await updateRequestWithHeaders(&urlRequest, options: options, networkSession: networkSession)

        if options.multipartData != nil || options.fileURL != nil {
            // Do not set httpBody or httpBodyStream
        } else if let serializedData = options.data {
            if HTTPHeaderContentTypeValue.urlEncoded == options.contentType {
                urlRequest.httpBody = (try serializedData.toUrlParams()).data(using: .utf8)
            } else {
                urlRequest.httpBody = try serializedData.toJson()
            }
        }

        return urlRequest
    }

    /// Updates the passed request object `URLRequest` with headers,  based on  parameters passed in `options`.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - options: Request options  that provides request-specific information, such as the request type, and body, query parameters.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with a network configuration parameters used in network communication.
    /// - Throws: An error if the operation fails for any reason.
    private func updateRequestWithHeaders(_ urlRequest: inout URLRequest, options: FetchOptions, networkSession: NetworkSession) async throws {
        urlRequest.allHTTPHeaderFields = options.headers.compactMapValues { $0?.paramValue }

        for (key, value) in networkSession.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let contentType = options.contentType, options.multipartData == nil {
            urlRequest.setValue(contentType, forHTTPHeaderField: HTTPHeaderKey.contentType)
        }

        for (key, value) in BoxConstants.analyticsHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        try await updateRequestWithAuthorizationHeader(&urlRequest, options: options, networkSession: networkSession)
    }

    /// Updates the passed request object `URLRequest` with authorization header,  based on  parameters passed in `options`.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - options: Request options  that provides request-specific information, such as the request type, and body, query parameters.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with a network configuration parameters used in network communication.
    /// - Throws: An error if the operation fails for any reason.
    private func updateRequestWithAuthorizationHeader(_ urlRequest: inout URLRequest, options: FetchOptions, networkSession: NetworkSession) async throws {
        if let auth = options.auth, let token = (try await auth.retrieveToken(networkSession: networkSession)).accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: HTTPHeaderKey.authorization)
        }
    }

    /// Creates a `URL`object  based on url and query parameters
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - params: Query parameters to be passed in the URL.
    /// - Returns: The URL of the endpoint.
    private func createEndpointUrl(url: String, params: [String: ParameterConvertible?]?) -> URL {
        guard let params = params else {
            return URL(string: url)!
        }

        let nonNullQueryParams: [String: String] = params.compactMapValues { $0?.paramValue }
        var components = URLComponents(url: URL(string: url)!, resolvingAgainstBaseURL: true)!
        components.queryItems = nonNullQueryParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        return components.url!
    }

    /// Processes  response and performs the appropriate action
    ///
    /// - Parameters:
    ///   - using: Represents a data combined with the request and the corresponding response.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with a network configuration parameters used in network communication.
    ///   - attempt: The request attempt number.
    /// - Returns: Response of the request in the form of FetchResponse object.
    /// - Throws: An error if the operation fails for any reason.
    private func processResponse(
        using conversation: FetchConversation,
        networkSession: NetworkSession,
        attempt: Int,
        isUpload: Bool
    ) async throws -> FetchResponse {
        let statusCode = conversation.urlResponse.statusCode
        let isStatusCodeAcceptedWithRetryAfterHeader = statusCode == 202 && conversation.urlResponse.value(forHTTPHeaderField: HTTPHeaderKey.retryAfter) != nil

        // OK
        if statusCode >= 200 && statusCode < 400 && !isStatusCodeAcceptedWithRetryAfterHeader {
            return conversation.convertToFetchResponse()
        }

        // available attempts exceeded
        if attempt >= networkSession.networkSettings.maxRetryAttempts {
            throw BoxAPIError(fromConversation: conversation, message: "Request has hit the maximum number of retries.")
        }

        // Unauthorized
        if statusCode == 401, let auth = conversation.options.auth  {
            _ = try await auth.refreshToken(networkSession: networkSession)
            return try await fetch(options: conversation.options, networkSession: networkSession, attempt: attempt + 1, isUpload: isUpload)
        }

        // Retryable
        if statusCode == 429 || statusCode >= 500 || isStatusCodeAcceptedWithRetryAfterHeader {
            let retryTimeout = Double(conversation.urlResponse.value(forHTTPHeaderField: HTTPHeaderKey.retryAfter) ?? "")
            ?? networkSession.networkSettings.retryStrategy.getRetryTimeout(attempt: attempt)
            try await wait(seconds: retryTimeout)

            return try await fetch(options: conversation.options, networkSession: networkSession, attempt: attempt + 1, isUpload: isUpload)
        }

        throw BoxAPIError(fromConversation: conversation)
    }

    /// Suspends the current task for the given duration of seconds.
    ///
    /// - Parameters:
    ///   - seconds: Number of seconds to wait.
    /// - Throws: An error if the operation fails for any reason.
    private func wait(seconds delay: TimeInterval) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            utilityQueue.asyncAfter(
                deadline: .now() + .milliseconds(Int(delay * 1000))
            ) {
                continuation.resume()
            }
        }
    }
}

// MARK: - URLSessionDelegate Methods

extension NetworkClient {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        continuationQueue.sync {
            guard let taskInfo = taskInfos[task.taskIdentifier] else { return }
            switch taskInfo {
            case let dataTaskInfo as DataTaskInfo:
                taskInfos.removeValue(forKey: task.taskIdentifier)
                if let error = error {
                    dataTaskInfo.continuation.resume(throwing: BoxNetworkError(message: error.localizedDescription, error: error))
                    return
                }
                guard let response = task.response else {
                    dataTaskInfo.continuation.resume(throwing: BoxNetworkError(message: "No response received for task. URL: \(task.originalRequest?.url?.absoluteString ?? "unknown")"))
                    return
                }
                if let tempFileURL = dataTaskInfo.multipartTempFileURL {
                    try? FileManager.default.removeItem(at: tempFileURL)
                }
                dataTaskInfo.continuation.resume(returning: (dataTaskInfo.accumulatedData, response))
            case let downloadTaskInfo as DownloadTaskInfo:
                taskInfos.removeValue(forKey: task.taskIdentifier)
                if let error = error {
                    downloadTaskInfo.continuation.resume(throwing: BoxNetworkError(message: error.localizedDescription, error: error))
                }
            default:
                break
            }
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        continuationQueue.sync {
            guard let dataTaskInfo = taskInfos[dataTask.taskIdentifier] as? DataTaskInfo else { return }
            dataTaskInfo.accumulatedData.append(data)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        continuationQueue.sync {
            guard let downloadTaskInfo = taskInfos[downloadTask.taskIdentifier] as? DownloadTaskInfo else { return }
            do {
                try FileManager.default.moveItem(at: location, to: downloadTaskInfo.destinationURL)
                downloadTaskInfo.continuation.resume(returning: (downloadTaskInfo.destinationURL, downloadTask.response!))
            } catch {
                downloadTaskInfo.continuation.resume(throwing: BoxSDKError(message: "Could not move downloaded file: \(error.localizedDescription)"))
            }
        }
    }
}
