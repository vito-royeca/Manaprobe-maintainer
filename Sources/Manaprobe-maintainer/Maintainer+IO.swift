//
//  Maintainer+IO.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 10/9/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Maintainer {
    func processCards(label: String,
                      callback: ([[String: Any]]) -> [() async throws -> Void]) async throws {
        let fileReader = StreamingFileReader(path: cardsLocalPath)
        let path = "\(cachePath)/managuide-\(label).json"
        var cards = [[String: Any]]()
        var offset = 0

        repeat {
            let startDate = Date()
            var milestone = readMilestone(at: path)
            var seeking = false
            
            if offset + milestone.value <= milestone.value &&
                milestone.fileOffset != 0 {
                print("seeking to milestone: \(milestone.value), offset: \(milestone.fileOffset)")
                fileReader.seek(toOffset: milestone.fileOffset)
                seeking = true
            }
            
            cards = readFileData(fileReader: fileReader, lines: printMilestone)
            let processes = callback(cards)
            try await exec(processes: processes)
            
            offset = seeking ? milestone.value : offset + cards.count
            milestone.value += cards.count
            milestone.fileOffset = fileReader.offset
            writeMilestone(milestone, at: path)
            
            let endDate = Date()
            let timeDifference = endDate.timeIntervalSince(startDate)
            print("\(label): \(offset) Elapsed time: \(format(timeDifference))")

        } while !cards.isEmpty
        
        try FileManager.default.removeItem(atPath: path)
    }
    
    func readFileData(fileReader: StreamingFileReader, lines: Int) -> [[String: Any]] {
        var array = [[String: Any]]()
        
        while let line = fileReader.readLine() {
            var cleanLine = String(line)
            
            if cleanLine.hasSuffix("}},") {
                cleanLine.removeLast()
            }
            
            guard cleanLine.hasPrefix("{\""),
                let data = cleanLine.data(using: .utf16),
                let dict = try! JSONSerialization.jsonObject(with: data,
                                                             options: .mutableContainers) as? [String: Any] else {
                continue
            }
            
            array.append(dict)
            
            if array.count == lines {
                break
            }
        }
        
        return array
    }

    func fetchData(from remotePath: String, saveTo localPath: String) async throws {
        guard !FileManager.default.fileExists(atPath: localPath) else {
            return
        }
            
        guard let urlString = remotePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString) else {
            fatalError("Malformed url")
        }

        let (localURL, _) = try await URLSession.shared.asyncDownload(from: url)
        try FileManager.default.moveItem(atPath: localURL.path, toPath: localPath)
    }

    func readMilestone(at path: String) -> Milestone {
        guard FileManager.default.fileExists(atPath: path) else {
            return Milestone(value: 0, fileOffset: UInt64(0))
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let milestone = try decoder.decode(Milestone.self, from: data)
            return milestone
        } catch {
            return Milestone(value: 0, fileOffset: UInt64(0))
        }
    }
    
    func writeMilestone(_ milestone: Milestone, at path: String) {
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(milestone)
            
            let _ = FileManager.default.createFile(atPath: path,
                                                   contents: data,
                                                   attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func readStatus(directoryPath: String) -> String? {
        let statusFile = "\(directoryPath)/status.json"
            
        guard FileManager.default.fileExists(atPath: statusFile) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: statusFile), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let cardStatus = try decoder.decode(CardStatus.self, from: data)
            return cardStatus.status
        } catch {
            return nil
        }
    }
    
    func writeStatus(directoryPath: String, status: String) {
        let statusFile = "\(directoryPath)/status.json"
        
        do {
            if FileManager.default.fileExists(atPath: statusFile) {
                try FileManager.default.removeItem(atPath: statusFile)
            }
            
            let cardStatus = CardStatus(status: status)
            let encoder = JSONEncoder()
            let data = try encoder.encode(cardStatus)
            
            self.prepare(destinationFile: statusFile)
            let _ = FileManager.default.createFile(atPath: statusFile,
                                                   contents: data,
                                                   attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func prepare(destinationFile: String) {
        do {
            let destinationURL = URL(fileURLWithPath: destinationFile)
            let parentDir = destinationURL.deletingLastPathComponent().path
            
            // create parent dirs
            if !FileManager.default.fileExists(atPath: parentDir) {
                try! FileManager.default.createDirectory(atPath: parentDir,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
            }
            
            // delete if existing
            if FileManager.default.fileExists(atPath: destinationFile) {
                try FileManager.default.removeItem(atPath: destinationFile)
            }
        } catch {
            print(error)
        }
    }
    
    func startActivity(label: String) -> Date {
        let date = Date()
        print("\(label) started on: \(localFormat(date))")
        return date
    }
    
    func endActivity(label: String, from: Date) {
        let endDate = Date()
        let timeDifference = endDate.timeIntervalSince(from)
        
        print("\(label) ended   on: \(localFormat(endDate))")
        print("Elapsed time: \(format(timeDifference))\n")
    }
}
