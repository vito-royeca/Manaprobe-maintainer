//
//  Maintainer+Migrations.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 9/14/25.
//

import Foundation
import PostgresClientKit

extension Maintainer {
    func fetchMigrations() async throws {
        var hasMore = true
        var page = 1
        
        repeat {
            let remotePath = "\(migrationsRemotePath)?page=\(page)"
            let fileName = self.migrationsFileName.replacingOccurrences(of: ".json", with: "_\(page).json")
            let localPath = "\(cachePath)/\(filePrefix)_\(fileName)"
            
            try await fetchData(from: remotePath, saveTo: localPath)
            let data = try! Data(contentsOf: URL(fileURLWithPath: localPath))
            guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                               options: .mutableContainers) as? [String: Any] else {
                fatalError("Malformed data")
            }
            
            migrationsLocalPaths.append(localPath)
            hasMore = dict["has_more"] as? Bool ?? false
            page += 1
            
        } while hasMore
    }

    func processMigrationsData() async throws {
        let label = "processMigrationsData"
        let date = startActivity(label: label)
        try await exec(processes: filterMigrations())
        endActivity(label: label, from: date)
    }
    
    private func filterMigrations() -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        for localPath in migrationsLocalPaths {
            print(localPath)
            let data = try! Data(contentsOf: URL(fileURLWithPath: localPath))
            guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                               options: .mutableContainers) as? [String: Any],
                  let arrayData = dict["data"] as? [[String: Any]] else {
                    fatalError("Malformed data")
            }
 
            for arrayDict in arrayData {
                if let metadata = arrayDict["metadata"] as? [String: Any],
                   let langCode = metadata["lang"] as? String,
                   let setCode = metadata["set_code"] as? String,
                   let collectorNumber = metadata["collector_number"] as? String {
                    let cleanCollectorNumber = collectorNumber.replacingOccurrences(of: "★", with: "star")
                                                              .replacingOccurrences(of: "†", with: "cross")
                    let new_id = "\(setCode)_\(langCode)_\(cleanCollectorNumber)"
                    processes.append({
                        try await self.createMigration(new_id: new_id)

//                        let path   = "\(self.imagesPath)/\(setCode)/\(langCode)/\(cleanCollectorNumber)"
//                        let (_,_,_) = Process.shell(
//                            path: "/bin/bash",
//                            args: ["-c", "rm -fvr \(path)"])
                    })
                } else if let id = arrayDict["old_scryfall_id"] as? String {
                    processes.append({
                        try await self.createMigration(new_id: id)
                    })
                }
            }
        }

        return processes
    }
}
