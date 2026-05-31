//
//  StreamingFileReader.swift
//
//  From https://www.morgandavison.com/2020/02/05/streaming-file-reader-in-swift/
//
//  Created by Vito Royeca on 6/13/21.
//

import Foundation

class StreamingFileReader {
    let bufferSize: Int = 1024
    var fileHandle: FileHandle?
    var buffer: Data
    var offset = UInt64(0)
    
    // Using new line as the delimiter
    let delimiter = "\n".data(using: .utf8)!
    
    init(path: String) {
        fileHandle = FileHandle(forReadingAtPath: path)
        buffer = Data(capacity: bufferSize)
    }
    
    func readLine() -> String? {
//        if buffer.count <= 0 {
//            return nil
//        }

        var rangeOfDelimiter = buffer.range(of: delimiter)
        
        while rangeOfDelimiter == nil {
            guard let chunk = fileHandle?.readData(ofLength: bufferSize) else {
                return nil
            }
            offset += UInt64(bufferSize)
            
            if chunk.count == 0 {
                if buffer.count > 0 {
                    defer { buffer.count = 0 }
                    
                    return String(data: buffer, encoding: .utf8)
                }
                
                return nil
            } else {
                buffer.append(chunk)
                rangeOfDelimiter = buffer.range(of: delimiter)
            }
        }
        
        let rangeOfLine = 0 ..< rangeOfDelimiter!.upperBound
        let line = String(data: buffer.subdata(in: rangeOfLine), encoding: .utf8)
        
        buffer.removeSubrange(rangeOfLine)
        if rangeOfLine.upperBound == 0 && rangeOfLine.lowerBound == 0 {
            print(line ?? "----------")
        }
        return line?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func seek(toOffset offset: UInt64) {
        do {
            self.offset = offset
            try fileHandle?.seek(toOffset: offset)
        } catch {
            print(error)
        }
    }
}
