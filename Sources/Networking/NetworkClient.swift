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

    // Continuations to bridge delegate callbacks to async/await
    private var dataContinuations: [Int: CheckedContinuation<(Data, URLResponse), Error>] = [:]
    private var downloadContinuations: [Int: CheckedContinuation<(URL, URLResponse), Error>] = [:]
    private var dataAccumulators: [Int: Data] = [:]
    private let continuationQueue = DispatchQueue(label: "BoxSdkGen.NetworkClient.continuationQueue.\(UUID().uuidString)")

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
        var options = options
        if let fileStream = options.fileStream, !(fileStream is MemoryInputStream) {
            let memoryInputStream = MemoryInputStream(data: Utils.readByteStream(byteStream: fileStream))
            options = options.withFileStream(fileStream: memoryInputStream)
        }

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

        if let fileStream = options.fileStream, let memoryInputStream = fileStream as? MemoryInputStream, attempt > 1 {
            memoryInputStream.reset()
        }

        if let downloadDestinationURL = options.downloadDestinationURL {
            let (downloadUrl, urlResponse) = try await sendDownloadRequest(urlRequest, downloadDestinationURL: downloadDestinationURL, networkSession: networkSession)
            let conversation = FetchConversation(options: options, urlRequest: urlRequest, urlResponse: urlResponse as! HTTPURLResponse, responseType: .url(downloadUrl))
            return try await processResponse(using: conversation, networkSession: networkSession, attempt: attempt, isUpload: isUpload)
        } else if isUpload {
            let (data, urlResponse) = try await sendUploadRequest(urlRequest, networkSession: networkSession)
            let conversation = FetchConversation(options: options, urlRequest: urlRequest, urlResponse: urlResponse as! HTTPURLResponse, responseType: .data(data))
            return try await processResponse(using: conversation, networkSession: networkSession, attempt: attempt, isUpload: isUpload)
        } else {
            let (data, urlResponse) =  try await sendDataRequest(urlRequest, networkSession: networkSession)
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
                dataContinuations[task.taskIdentifier] = continuation
                dataAccumulators[task.taskIdentifier] = Data()
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
                downloadContinuations[task.taskIdentifier] = continuation
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
    private func sendUploadRequest(_ urlRequest: URLRequest, networkSession: NetworkSession) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            guard let httpBody = urlRequest.httpBody else {
                continuation.resume(throwing: BoxNetworkError(message: "HTTP body is nil for upload request."))
                return
            }
            continuationQueue.sync {
                let task = networkSession.session.uploadTask(with: urlRequest, from: httpBody)
                dataContinuations[task.taskIdentifier] = continuation
                dataAccumulators[task.taskIdentifier] = Data()
                task.resume()
            }
        }
    }

    /// Creates the request object `URLRequest` based on  parameters passed in `options`.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - options: Request options  that provides request-specific information, such as the request type, and body, query parameters.
    ///   - networkSession: The Networking Session object which provides the URLSession object along with a network configuration parameters used in network communication.
    /// - Returns: The URLRequest object which represents information about the request.
    /// - Throws: An error if the operation fails for any reason.
    private func createRequest(
        options: FetchOptions,
        networkSession: NetworkSession
    ) async throws -> URLRequest {
        var urlRequest = URLRequest(url: createEndpointUrl(url: options.url, params: options.params))
        urlRequest.httpMethod = options.method.rawValue

        try await updateRequestWithHeaders(&urlRequest, options: options, networkSession: networkSession)

        if let fileStream = options.fileStream {
            urlRequest.httpBodyStream = fileStream
        } else if let multipartData = options.multipartData {
            try updateRequestWithMultipartData(&urlRequest, multipartData: multipartData)
        }

        if let serializedData = options.data {
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

        if let contentType = options.contentType {
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

    /// Updates the passed request object `URLRequest` with multipart data,  based on  parameters passed in `multipartData`.
    ///
    /// - Parameters:
    ///   - urlRequest: The request object.
    ///   - multipartData: An array of `MultipartItem` which will be used to create the body of the request.
    private func updateRequestWithMultipartData(_ urlRequest: inout URLRequest, multipartData: [MultipartItem]) throws {
        var parameters: [String: Any] = [:]
        var partName = ""
        var fileName = ""
        var mimeType = ""
        var bodyStream = InputStream(data: Data())
        let boundary = "Boundary-\(UUID().uuidString)"
        for part in multipartData {
            if let body = part.data {
                parameters[part.partName] = Utils.Strings.from(data: try body.toJson())
            } else if let fileStream = part.fileStream {
                let unwrapFileName = part.fileName ?? ""
                let unwrapMimeType = part.contentType ?? ""

                partName = part.partName
                fileName = unwrapFileName
                mimeType = unwrapMimeType
                bodyStream = fileStream
            }
        }

        let bodyStreams = createMultipartBodyStreams(parameters, partName: partName, fileName: fileName, mimetype: mimeType, bodyStream: bodyStream, boundary: boundary)
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: HTTPHeaderKey.contentType)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBodyStream = ArrayInputStream(inputStreams: bodyStreams)
    }

    /// Creates an array of `InputStream`based on passed arguments, which will be used as an bodyStream of the request.
    ///
    /// - Parameters:
    ///   - parameters: The parameters of the multipart request in form of a Dictionary.
    ///   - partName: The name of the file part.
    ///   - fileName: The file name.
    ///   - mimetype: The content type of the file part.
    ///   - bodyStream: The stream containing the file contents.
    ///   - boundary: The boundary value,  used to separate name/value pair.
    /// - Returns: An array of `InputStream`streams.
    private func createMultipartBodyStreams(_ parameters: [String: Any]?, partName: String, fileName: String, mimetype: String, bodyStream: InputStream, boundary: String) -> [InputStream] {
        var preBody = Data()
        if let parameters = parameters {
            for (key, value) in parameters {
                preBody.append("--\(boundary)\r\n".data(using: .utf8)!)
                preBody.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                preBody.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        preBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        preBody.append("Content-Disposition: form-data; name=\"\(partName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        preBody.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)

        var postBody = Data()
        postBody.append("\r\n".data(using: .utf8)!)
        postBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var bodyStreams: [InputStream] = []
        bodyStreams.append(InputStream(data: preBody))
        bodyStreams.append(bodyStream)
        bodyStreams.append(InputStream(data: postBody))

        return bodyStreams
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
    // Handle task completion
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Handle Data and Upload Tasks
        if let continuation = dataContinuations[task.taskIdentifier] {
            dataContinuations[task.taskIdentifier] = nil

            if let error = error {
                dataAccumulators[task.taskIdentifier] = nil
                continuation.resume(throwing: BoxNetworkError(message: error.localizedDescription, error: error))
                return
            }

            guard let response = task.response else {
                dataAccumulators[task.taskIdentifier] = nil
                continuation.resume(throwing: BoxNetworkError(message: "No response received for task. URL: \(task.originalRequest?.url?.absoluteString ?? "unknown")"))
                return
            }

            // Retrieve accumulated data
            let accumulatedData = dataAccumulators[task.taskIdentifier] ?? Data()
            dataAccumulators[task.taskIdentifier] = nil
            continuation.resume(returning: (accumulatedData, response))
        }

        // Handle Download Tasks
        if let continuation = downloadContinuations[task.taskIdentifier] {
            downloadContinuations[task.taskIdentifier] = nil
            if let error = error {
                continuation.resume(throwing: BoxNetworkError(message: error.localizedDescription, error: error))
                return
            }

            // Completion is handled in `didFinishDownloadingTo`
            // No action needed here
        }
    }

    // Handle data received for data and upload tasks
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let continuation = dataContinuations[dataTask.taskIdentifier] {
            // Initialize accumulator if not present
            if dataAccumulators[dataTask.taskIdentifier] == nil {
                dataAccumulators[dataTask.taskIdentifier] = Data()
            }

            // Append received data
            dataAccumulators[dataTask.taskIdentifier]?.append(data)
        }
    }

    // Handle download completion
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let continuation = downloadContinuations[downloadTask.taskIdentifier] {
            downloadContinuations[downloadTask.taskIdentifier] = nil
            guard let response = downloadTask.response else {
                continuation.resume(throwing: BoxNetworkError(message: "No response received for download task. URL: \(downloadTask.originalRequest?.url?.absoluteString ?? "unknown")"))
                return
            }

            continuation.resume(returning: (location, response))
        }
    }
}
