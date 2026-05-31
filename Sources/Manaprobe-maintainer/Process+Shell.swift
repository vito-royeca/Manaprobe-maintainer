//
//  Process+Shell.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 9/14/25.
//

import Foundation

extension Process {
    static func shell(path: String = "/bin/zsh", args:[String] = []) -> (Int32, String?, String?) {
        let task = Process()
        let pipeOut = Pipe()
        let pipeErr = Pipe()
        task.standardInput = nil
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        do {
            try task.run()
            task.waitUntilExit()
            let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
            let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
            return (
                task.terminationStatus,
                dataOut.isEmpty ? nil : String(data: dataOut, encoding: .utf8),
                dataErr.isEmpty ? nil : String(data: dataErr, encoding: .utf8)
            )
        } catch {
            return (0, nil, nil)
        }
    }
}
