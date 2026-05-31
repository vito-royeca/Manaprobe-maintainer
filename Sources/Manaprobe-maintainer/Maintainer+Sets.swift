//
//  Maintainer+Sets.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 23/10/2018.
//

import Foundation
import PostgresClientKit

extension Maintainer {
    func processSetsData() async throws {
        let label = "processSetsData"
        let date = startActivity(label: label)
        var processes = [() async throws -> Void]()
        
        processes.append(contentsOf: filterSetBlocks(array: setsArray))
        processes.append(contentsOf: filterSetTypes(array: setsArray))
        processes.append(contentsOf: filterSets(array: setsArray))

        try await exec(processes: processes)
        endActivity(label: label, from: date)
    }
    
    func setsData() -> [[String: Any]] {
        let setsPath = "\(cachePath)/\(filePrefix)_\(setsFileName)"
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: setsPath))
        guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                           options: .mutableContainers) as? [String: Any] else {
            fatalError("Malformed data")
        }
        guard let array = dict["data"] as? [[String: Any]] else {
            fatalError("Malformed data")
        }
        
        return array
    }

    func filterSetBlocks(array: [[String: Any]]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        for dict in array {
            if let blockCode = dict["block_code"] as? String,
               let block = dict["block"] as? String {
                processes.append({
                    try await self.createSetBlock(blockCode: blockCode,
                                                  block: block)
                })
            }
        }

        return processes
    }
    
    func filterSetTypes(array: [[String: Any]]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        for dict in array {
            if let setType = dict["set_type"] as? String {
                processes.append({
                    try await self.createSetType(setType: setType)
                })
            }
        }

        return processes
    }
    
    func filterSets(array: [[String: Any]]) -> [() async throws -> Void] {
        let keyruneCodes = updatedKeyruneCodes()
        let defaultKeyruneClass = "dpa"
        let defaultKeyruneUnicode = "e689"
        let defaultLogoCode = "null"

        var filteredData = array.sorted(by: {
            $0["parent_set_code"] as? String ?? "" < $1["parent_set_code"] as? String ?? ""
        })
        
        for row in filteredData.indices {
            if let keyrune = keyruneCodes.filter({ $0["code"] == filteredData[row]["code"] as? String}).first {
                filteredData[row]["keyrune_unicode"] = keyrune["keyrune_unicode"]
                filteredData[row]["keyrune_class"] = keyrune["keyrune_class"]
                filteredData[row]["logo_code"] = keyrune["logo_code"]
            }
        }
        for row in filteredData.indices {
            if filteredData[row]["keyrune_class"] == nil {
                filteredData[row]["keyrune_class"] = defaultKeyruneClass
            }
            if filteredData[row]["keyrune_unicode"] == nil {
                filteredData[row]["keyrune_unicode"] = defaultKeyruneUnicode
            }
            if filteredData[row]["logo_code"] == nil {
                filteredData[row]["logo_code"] = defaultLogoCode
            }
        }
        
        var processes = [() async throws -> Void]()
        for dict in filteredData {
            processes.append({
                try await self.createSet(dict: dict)
            })
        }
        
        return processes
    }
    
    func downloadSetLogos() async throws {
        
        let label = "downloadSetLogos"
        let date = startActivity(label: label)
        let setsPath = imagesPath.replacingOccurrences(of: "cards", with: "sets")
        var processes = [() async throws -> Void]()
        
        for keyrune in updatedKeyruneCodes() {
            if let logoCode = keyrune["logo_code"],
                logoCode != "null" {
                
                let destSmall = "\(setsPath)/\(logoCode)_small.png"
                if !FileManager.default.fileExists(atPath: destSmall) {
                    print(destSmall)
                    let sourceSmall = "https://www.mtgpics.com/graph/sets/logos/" + logoCode + ".png"
                    self.prepare(destinationFile: destSmall)
                    processes.append({
                        try await self.fetchData(from: sourceSmall, saveTo: destSmall)
                    })
                }
                
                let destBig = "\(setsPath)/\(logoCode)_big.png"
                if !FileManager.default.fileExists(atPath: destBig) {
                    print(destBig)
                    let sourceBig = "https://www.mtgpics.com/graph/sets/logos_big/" + logoCode + ".png"
                    self.prepare(destinationFile: destBig)
                    processes.append({
                        try await self.fetchData(from: sourceBig, saveTo: destBig)
                    })
                }
            }
        }
        
        try await exec(processes: processes)
        endActivity(label: label, from: date)
    }
}
