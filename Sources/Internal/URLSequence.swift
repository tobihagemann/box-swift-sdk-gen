import Foundation

/// A `Sequence` that yields `URL`s pointing to chunk files.
/// Conforms to the `Sequence` protocol and provides an iterator that yields chunk file URLs.
public struct URLSequence: Sequence {
    /// The type of elements that this sequence yields.
    public typealias Element = URL

    /// The local file URL of the file to split into chunks.
    private let fileURL: URL

    /// The size of each chunk in bytes.
    private let chunkSize: Int

    /// The total size of the file in bytes.
    private let fileSize: Int

    /// Initializes a `URLSequence` with the given file URL, chunk size, and file size.
    ///
    /// - Parameters:
    ///   - fileURL: The local file URL of the file to split into chunks.
    ///   - chunkSize: The size of each chunk in bytes.
    ///   - fileSize: The total size of the file in bytes.
    public init(fileURL: URL, chunkSize: Int, fileSize: Int) {
        self.fileURL = fileURL
        self.chunkSize = chunkSize
        self.fileSize = fileSize
    }

    /// Creates and returns an iterator for this sequence.
    ///
    /// - Returns: A `URLIterator` that yields URLs to chunk files.
    public func makeIterator() -> URLIterator {
        return URLIterator(fileURL: fileURL, chunkSize: chunkSize, fileSize: fileSize)
    }
}

/// An iterator that yields URLs to chunk files.
/// Conforms to the `IteratorProtocol` and yields `URL`s pointing to temporary chunk files.
public struct URLIterator: IteratorProtocol {
    /// The type of elements that this iterator yields.
    public typealias Element = URL

    /// The local file URL of the file to split into chunks.
    private let fileURL: URL

    /// The size of each chunk in bytes.
    private let chunkSize: Int

    /// The total size of the file in bytes.
    private let fileSize: Int

    /// The current offset in the file.
    private var offset: Int = 0

    /// The URL of the previously yielded chunk file.
    private var previousChunkURL: URL? = nil

    /// Initializes a `URLIterator` with the given file URL, chunk size, and file size.
    ///
    /// - Parameters:
    ///   - fileURL: The local file URL of the file to split into chunks.
    ///   - chunkSize: The size of each chunk in bytes.
    ///   - fileSize: The total size of the file in bytes.
    public init(fileURL: URL, chunkSize: Int, fileSize: Int) {
        self.fileURL = fileURL
        self.chunkSize = chunkSize
        self.fileSize = fileSize
    }

    /// Reads the next chunk of data from the file and returns its temporary file URL.
    ///
    /// - Returns: A `URL` pointing to the next chunk file, or `nil` if no more chunks are available.
    public mutating func next() -> URL? {
        // Delete the previous chunk file if it exists
        if let previousURL = previousChunkURL {
            do {
                try FileManager.default.removeItem(at: previousURL)
            } catch {
                print("Error deleting previous chunk file at \(previousURL): \(error)")
                // Depending on requirements, you might want to handle this error differently
                // For now, we'll proceed to the next chunk
            }
        }

        // Check if we've processed the entire file
        guard offset < fileSize else { return nil }

        // Determine the size of the current chunk
        let remainingBytes = fileSize - offset
        let currentChunkSize = min(chunkSize, remainingBytes)

        // Attempt to open the file for reading
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
            print("Failed to open file at \(fileURL) for reading.")
            return nil
        }
        defer { try? fileHandle.close() }

        // Seek to the current offset and read the chunk data
        fileHandle.seek(toFileOffset: UInt64(offset))
        let data = fileHandle.readData(ofLength: currentChunkSize)

        // Generate a unique temporary file URL for the chunk
        let tempChunkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            // Write the chunk data to the temporary file
            try data.write(to: tempChunkURL)
        } catch {
            print("Error writing chunk to temporary file at \(tempChunkURL): \(error)")
            return nil
        }

        // Update the offset for the next chunk
        offset += currentChunkSize

        // Update the previous chunk URL to the current one
        previousChunkURL = tempChunkURL

        return tempChunkURL
    }
}
