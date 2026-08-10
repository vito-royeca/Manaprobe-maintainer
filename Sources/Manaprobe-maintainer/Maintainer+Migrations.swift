//
//  Maintainer+Migrations.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 9/14/25.
//

import Foundation
import PostgresClientKit

class Migrations: Codable {
    let object: String
    let hasMore: Bool
    let nextPage: String?
    let data: [Migration]

    enum CodingKeys: String, CodingKey {
        case object,
          hasMore = "has_more",
          nextPage = "next_page",
          data
    }

    required init(from decoder : Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        object = try container.decode(String.self, forKey: .object)
        hasMore = try container.decode(Bool.self, forKey: .hasMore)
        nextPage = try container.decodeIfPresent(String.self, forKey: .nextPage) ?? nil
        data = try container.decode([Migration].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object, forKey: .object)
        try container.encode(hasMore, forKey: .hasMore)
        try container.encode(nextPage, forKey: .nextPage)
        try container.encode(data, forKey: .data)
    }
}

class Migration: Codable, Identifiable {
    let object: String
    let id: String
    let uri: String
    let performedAt: String
    let migrationStrategy: String
    let oldScryfallId: String
    let newScryfallId: String?
    let note: String
    let metadata: MigrationMetadata?
    
    enum CodingKeys: String, CodingKey {
        case object,
          id,
          uri,
          performedAt = "performed_at",
          migrationStrategy = "migration_strategy",
          oldScryfallId = "old_scryfall_id",
          newScryfallId = "new_scryfall_id",
          note,
          metadata
    }

    required init(from decoder : Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        uri = try container.decode(String.self, forKey: .uri)
        performedAt = try container.decode(String.self, forKey: .performedAt)
        migrationStrategy = try container.decode(String.self, forKey: .migrationStrategy)
        oldScryfallId = try container.decode(String.self, forKey: .oldScryfallId)
        newScryfallId = try container.decodeIfPresent(String.self, forKey: .newScryfallId) ?? nil
        note = try container.decode(String.self, forKey: .note)
        metadata = try container.decodeIfPresent(MigrationMetadata.self, forKey: .metadata) ?? nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object, forKey: .object)
        try container.encode(id, forKey: .id)
        try container.encode(uri, forKey: .uri)
        try container.encode(performedAt, forKey: .performedAt)
        try container.encode(migrationStrategy, forKey: .migrationStrategy)
        try container.encode(oldScryfallId, forKey: .oldScryfallId)
        try container.encode(newScryfallId, forKey: .newScryfallId)
        try container.encode(note, forKey: .note)
        try container.encode(metadata, forKey: .metadata)
    }
}

class MigrationMetadata: Codable, Identifiable {
    let id: String
    let lang: String
    let name: String
    let setCode: String
    let oracleId: String
    let collectorNumber: String
    
    enum CodingKeys: String, CodingKey {
        case id,
          lang,
          name,
          setCode = "set_code",
          oracleId = "oracle_id",
          collectorNumber = "collector_number"
    }
    
    required init(from decoder : Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        lang = try container.decode(String.self, forKey: .lang)
        name = try container.decode(String.self, forKey: .name)
        setCode = try container.decode(String.self, forKey: .setCode)
        oracleId = try container.decode(String.self, forKey: .oracleId)
        collectorNumber = try container.decode(String.self, forKey: .collectorNumber)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(lang, forKey: .lang)
        try container.encode(name, forKey: .name)
        try container.encode(setCode, forKey: .setCode)
        try container.encode(oracleId, forKey: .oracleId)
        try container.encode(collectorNumber, forKey: .collectorNumber)
    }
}

extension Maintainer {
    func processMigrationsData() async throws {
        let label = "processMigrationsData"
        let date = startActivity(label: label)
        try await exec(processes: filterMigrations())
        endActivity(label: label, from: date)
    }

    func fetchMigrations() async throws -> [Migration] {
        var migrations = [Migration]()
        var nextPage: String? = nil
        var hasMore = true
        var page = 1
        
        nextPage = Resource.migrations.remotePath
        repeat {
            guard hasMore, let remotePath = nextPage else {
                return migrations
            }
            
            do {
                let url = URL(string: remotePath)!
                let (data, _) = try await URLSession.shared.data(from: url)
                let responseObject = try JSONDecoder().decode(Migrations.self, from: data)
                
                hasMore = responseObject.hasMore
                nextPage = responseObject.nextPage
                page += 1
                migrations.append(contentsOf: responseObject.data)
            } catch {
                fatalError("In fetchMigrations: \(error)")
            }
            
        } while hasMore
        
        return migrations
    }
    
    private func filterMigrations() async -> [() async throws -> Void] {
        do {
            var processes = [() async throws -> Void]()
            let migrations = try await fetchMigrations()

            for migration in migrations {
                // note: only performs the delete strategy
                if migration.migrationStrategy == "delete",
                   let metadata = migration.metadata {
                    let collectorNumber = metadata.collectorNumber
                    let cleanCollectorNumber = collectorNumber.replacingOccurrences(of: "★", with: "star")
                        .replacingOccurrences(of: "†", with: "cross")
                    let new_id = "\(metadata.setCode)_\(metadata.lang)_\(cleanCollectorNumber)"
                    processes.append({
                        try await self.createMigration(new_id: new_id)
                        
                        // Delete existing images
//                        let path   = "\(self.imagesPath)/\(setCode)/\(langCode)/\(cleanCollectorNumber)"
//                        let (_,_,_) = Process.shell(
//                            path: "/bin/bash",
//                            args: ["-c", "rm -fvr \(path)"])
//                        })
                    })
                }
            }
            
            return processes
        } catch {
            fatalError("In filterMigrations: \(error)")
        }
    }
}
