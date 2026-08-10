//
//  Maintainer+Resources.swift
//  Manaprobe-maintainer
//
//  Created by Vito Royeca on 8/8/26.
//


import Foundation

enum Resource: Equatable, Hashable, Identifiable, CaseIterable {
    case cards
    case rulings
    case sets
    case keyrunes
    case rules
    case migrations
    
    var id: Int {
        switch self {
        case .cards: 1000
        case .rulings: 1001
        case .sets: 1002
        case .keyrunes: 1003
        case .rules: 1004
        case .migrations: 1005
        }
    }
    
    var fileName: String {
        switch self {
        case .cards: "scryfall-all-cards.jsonl"
        case .rulings: "scryfall-rulings.jsonl"
        case .sets: "scryfall-sets.json"
        case .keyrunes: "keyrune.html"
        case .rules: "MagicCompRules.txt"
        case .migrations: "scryfall-migration.json"
        }
    }
    
    var remotePath: String {
        switch self {
        case .cards: "https://api.scryfall.com/bulk-data/all-cards"
        case .rulings: "https://api.scryfall.com/bulk-data/rulings"
        case .sets: "https://api.scryfall.com/sets"
        case .keyrunes: "https://keyrune.andrewgioia.com/cheatsheet.html"
        case .rules: "https://media.wizards.com/2025/downloads/MagicCompRules%2020250404.txt"
        case .migrations: "https://api.scryfall.com/migrations?page=1"
        }
    }
    
    func localPath(_ cachePath: String, _ localPrefix: String) -> String {
        "\(cachePath)/\(localPrefix)_\(fileName)"
    }
}

extension Maintainer {
    func fetchResources() -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        filePrefix = "manaprobe-\(Date().timeIntervalSince1970)"
        
        processes.append({
            try await self.fetchData(from: Resource.sets.remotePath,
                                     saveTo: Resource.sets.localPath(self.cachePath, self.filePrefix))
        })
        processes.append({
            try await self.fetchData(from: Resource.keyrunes.remotePath,
                                     saveTo: Resource.keyrunes.localPath(self.cachePath, self.filePrefix))
        })
        processes.append({
            try await self.fetchData(from: self.getDownloadURI(resource: .cards),
                                     saveTo: Resource.cards.localPath(self.cachePath, self.filePrefix),
                                     unpack: true)
        })
        processes.append({
            try await self.fetchData(from: self.getDownloadURI(resource: .rulings),
                                     saveTo: Resource.rulings.localPath(self.cachePath, self.filePrefix),
                                     unpack: true)
        })
        processes.append({
            try await self.fetchData(from: Resource.rules.remotePath,
                                     saveTo: Resource.rules.localPath(self.cachePath, self.filePrefix))
        })
        processes.append({
            try await self.downloadSetLogos()
        })
        processes.append({
            try await self.fetchCardImages()
        })
        return processes
    }
    
    func updateResources() -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        processes.append({
            try await self.processSetsData()
        })
        processes.append({
            try await self.processCardsData(type: .misc)
        })
        processes.append({
            try await self.processCardsData(type: .cards)
        })
        processes.append({
            try await self.processCardsData(type: .partsAndFaces)
        })
        processes.append({
            try await self.processRulingsData()
        })
        processes.append({
            try await self.processOtherCardsData()
        })
        processes.append({
            try await self.processComprehensiveRulesData()
        })
        processes.append({
            try await self.processMigrationsData()
        })
        processes.append({
            try await self.processMaterializedViews()
        })
        
        return processes
    }

    func cleanResources() {
        do {
            for reource in Resource.allCases {
                let path = reource.localPath(cachePath, filePrefix)

                if FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.removeItem(atPath: path)
                }
            }
        } catch {
            print(error)
        }
    }

    func getDownloadURI(resource: Resource) -> String {
        guard let url = URL(string: resource.remotePath) else {
            fatalError("Malformed URL")
        }
        
        let data = try! Data(contentsOf: url)
        guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                           options: .mutableContainers) as? [String: Any] else {
            fatalError("Malformed data")
        }
        guard let uri = dict["jsonl_download_uri"] as? String else {
            fatalError("URI not found")
        }

        return uri
    }
}
