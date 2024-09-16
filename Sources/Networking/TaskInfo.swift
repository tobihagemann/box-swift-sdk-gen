import Foundation

/// Base class for task information.
public class TaskInfo { }

/// Manages information for data and upload tasks.
public class DataTaskInfo: TaskInfo {
    /// Continuation to resume the async task.
    var continuation: CheckedContinuation<(Data, URLResponse), Error>

    /// Accumulated data for data tasks and upload responses.
    var accumulatedData: Data

    /// Temporary file URL for multipart uploads.
    var multipartTempFileURL: URL?

    /// Initializes a DataTaskInfo instance.
    ///
    /// - Parameters:
    ///   - continuation: The continuation to resume.
    ///   - multipartTempFileURL: The temporary file URL for uploads (optional).
    public init(continuation: CheckedContinuation<(Data, URLResponse), Error>, multipartTempFileURL: URL? = nil) {
        self.continuation = continuation
        self.accumulatedData = Data()
        self.multipartTempFileURL = multipartTempFileURL
    }
}

/// Manages information for download tasks.
public class DownloadTaskInfo: TaskInfo {
    /// Continuation to resume the async task.
    var continuation: CheckedContinuation<(URL, URLResponse), Error>

    /// Destination URL where the downloaded file should be moved.
    var destinationURL: URL

    /// Initializes a DownloadTaskInfo instance.
    ///
    /// - Parameters:
    ///   - continuation: The continuation to resume.
    ///   - destinationURL: The local URL where the file will be saved.
    public init(continuation: CheckedContinuation<(URL, URLResponse), Error>, destinationURL: URL) {
        self.continuation = continuation
        self.destinationURL = destinationURL
    }
}
