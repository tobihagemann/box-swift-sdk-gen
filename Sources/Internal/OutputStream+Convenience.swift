import Foundation

/// Extension to OutputStream to support writing Strings and Data
extension OutputStream {
    /// Writes a `String` to the output stream.
    ///
    /// - Parameter string: The string to write.
    /// - Throws: An error if writing fails.
    func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw BoxSDKError(message: "Failed to convert string to data.")
        }
        try write(data)
    }

    /// Writes `Data` to the output stream.
    ///
    /// - Parameter data: The data to write.
    /// - Throws: An error if writing fails.
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw BoxSDKError(message: "Failed to access data bytes.")
            }
            try write(buffer: pointer, length: buffer.count)
        }
    }

    /// Writes the contents of the file at the specified URL to the OutputStream.
    ///
    /// - Parameter fileURL: The URL of the file to write.
    /// - Throws: An error if reading from the file or writing to the stream fails.
    func write(contentsOf fileURL: URL) throws {
        guard let inputStream = InputStream(url: fileURL) else {
            throw BoxSDKError(message: "Unable to create input stream from file URL: \(fileURL)")
        }

        inputStream.open()
        defer { inputStream.close() }

        let bufferSize = 65536 // 64KB buffer size
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                throw BoxSDKError(message: "Failed to read data from input stream.")
            } else if bytesRead == 0 {
                break // End of file reached
            }
            try self.write(buffer: buffer, length: bytesRead)
        }
    }

    /// Writes bytes to the output stream, ensuring all data is written.
    ///
    /// - Parameters:
    ///   - buffer: Pointer to the data buffer.
    ///   - length: Number of bytes to write.
    /// - Throws: An error if writing fails.
    func write(buffer: UnsafePointer<UInt8>, length: Int) throws {
        var bytesRemaining = length
        var currentPointer = buffer

        while bytesRemaining > 0 {
            let bytesWritten = self.write(currentPointer, maxLength: bytesRemaining)
            if bytesWritten < 0 {
                throw BoxSDKError(message: "Failed to write data to output stream.")
            }
            bytesRemaining -= bytesWritten
            currentPointer += bytesWritten
        }
    }
}

