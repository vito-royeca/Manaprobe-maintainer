//
//  Maintainer+Rulings.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 14/07/2019.
//

import Foundation

extension Maintainer {
    func processRulingsData() async throws {
        let label = "processRulingsData"
        let date = startActivity(label: label)
        var processes = [() async throws -> Void]()

        processes.append({
            try await self.createDeleteRulings()

        })
        
        let callback: ([[String: Any]]) -> [() async throws -> Void] = { rulings in
            var processes = [() async throws -> Void]()
            
            for ruling in rulings {
                processes.append({
                    try await self.createRuling(dict: ruling)
                })
            }
            return processes
        }
        
        try await exec(processes: processes)
        try await processFile(label: label,
                              localPath: Resource.rulings.localPath(cachePath, filePrefix),
                              callback: callback)
        
        endActivity(label: label, from: date)
    }
    
    func rulingsData() -> [[String: Any]] {
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        guard let array = try! JSONSerialization.jsonObject(with: data,
                                                            options: .mutableContainers) as? [[String: Any]] else {
            fatalError("Malformed data")
        }
        
        return array
    }
}
