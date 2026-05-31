//
//  Maintainer.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 23/10/2018.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import PostgresClientKit
import SSLService

class Maintainer {
    // MARK: - Constants
    let printMilestone     = 3000
    let bulkDataFileName   = "scryfall-bulkData.json"
    let setsFileName       = "scryfall-sets.json"
    let keyruneFileName    = "keyrune.html"
    let rulesFileName      = "MagicCompRules.txt"
    let migrationsFileName = "scryfall-migration.json"
    let cachePath          = "/tmp"
    let emdash             = "\u{2014}"
    
    // MARK: - Variables
    var tcgplayerAPIToken  = ""
    var filePrefix         = ""
    
    // remote file names
    let bulkDataRemotePath = "https://api.scryfall.com/bulk-data"
    var cardsRemotePath    = ""
    var rulingsRemotePath  = ""
    let setsRemotePath     = "https://api.scryfall.com/sets"
    let keyruneRemotePath  = "https://keyrune.andrewgioia.com/cheatsheet.html"
    let rulesRemotePath    = "https://media.wizards.com/2025/downloads/MagicCompRules%2020250404.txt"
    let migrationsRemotePath = "https://api.scryfall.com/migrations"

    // local file names
    var bulkDataLocalPath  = ""
    var cardsLocalPath     = ""
    var rulingsLocalPath   = ""
    var setsLocalPath      = ""
    var keyruneLocalPath   = ""
    var rulesLocalPath     = ""
    var milestoneLocalPath = ""
    var migrationsLocalPaths = [String]()
    
    // caches
    var artistsCache      = [String: [String]]()
    var raritiesCache     = [String]()
    var languagesCache    = [[String: String]]()
    var watermarksCache   = [String]()
    var layoutsCache      = [[String: String]]()
    var framesCache       = [[String: String]]()
    var frameEffectsCache = [[String: String]]()
    var colorsCache       = [[String: Any]]()
    var formatsCache      = [String]()
    var legalitiesCache   = [String]()
    var typesCache        = [[String: Any]]()
    var componentsCache   = [String]()
    var gamesCache        = [String]()
    var keywordsCache     = [String]()
    
    // TCGPlayer
    public enum TCGPlayer {
        public static let apiVersion = "v1.39.0"
        public static let apiLimit   = 300
        public static let partnerKey = "ManaGuide"
        public static let publicKey  = "A49D81FB-5A76-4634-9152-E1FB5A657720"
        public static let privateKey = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
    }
    
    // lazy variables
    var _bulkArray: [[String: Any]]?
    var bulkArray: [[String: Any]] {
        get {
            if _bulkArray == nil {
                _bulkArray = self.bulkData()
            }
            return _bulkArray!
        }
    }
    
    var _setsArray: [[String: Any]]?
    var setsArray: [[String: Any]] {
        get {
            if _setsArray == nil {
                _setsArray = self.setsData()
            }
            return _setsArray!
        }
    }
    
    var _rulingsArray: [[String: Any]]?
    var rulingsArray: [[String: Any]] {
        get {
            if _rulingsArray == nil {
                _rulingsArray = self.rulingsData()
            }
            return _rulingsArray!
        }
    }
    
    var _rulesArray: [String]?
    var rulesArray: [String] {
        get {
            if _rulesArray == nil {
                _rulesArray = self.rulesData()
            }
            return _rulesArray!
        }
    }
    
    var _connection: Connection?
    var connection: Connection {
        get {
            if _connection == nil {
                _connection = self.createConnection()
            }
            return _connection!
        }
    }

    // options variables
    var host: String
    var port: Int
    var database: String
    var user: String
    var password: String
    var isFullUpdate: Bool
    var imagesPath: String
    
    // MARK: - init

    init(host: String,
         port: Int,
         database: String,
         user: String,
         password: String,
         isFullUpdate: Bool,
         imagesPath: String) {
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password
        self.isFullUpdate = isFullUpdate
        self.imagesPath = imagesPath
    }
    
    // MARK: - Database methods

    func createConnection() -> Connection {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = host
        configuration.port = port
        configuration.database = database
        configuration.user = user
        
        // For CLI
//        configuration.credential = .cleartextPassword(password: password)
        
        // For Jenkins
        configuration.credential = .scramSHA256(password: password)
        
        configuration.ssl = false
        configuration.sslServiceConfiguration = SSLService.Configuration()
        
        do {
            let connection = try PostgresClientKit.Connection(configuration: configuration)
            return connection
        } catch {
            fatalError("\(error)")
        }
    }
    
    func updateDatabase() async throws -> Void {
        let label = "updateDatabase"
        let dateStart = startActivity(label: label)
        var processes = [() async throws -> Void]()
        
        if isFullUpdate {
            filePrefix         = "managuide-\(Date().timeIntervalSince1970)"
            bulkDataLocalPath  = "\(cachePath)/\(filePrefix)_\(bulkDataFileName)"
            setsLocalPath      = "\(cachePath)/\(filePrefix)_\(setsFileName)"
            keyruneLocalPath   = "\(cachePath)/\(filePrefix)_\(keyruneFileName)"
            rulesLocalPath     = "\(cachePath)/\(filePrefix)_\(rulesFileName)"
            
            // downloads
            processes.append({
                try await self.fetchData(from: self.bulkDataRemotePath, saveTo: self.bulkDataLocalPath)
            })
            processes.append({
                try await self.createBulkData()
            })
            processes.append({
                try await self.fetchData(from: self.setsRemotePath, saveTo: self.setsLocalPath)
            })
            processes.append({
                try await self.fetchData(from: self.keyruneRemotePath, saveTo: self.keyruneLocalPath)
            })
            processes.append({
                try await self.fetchData(from: self.cardsRemotePath, saveTo: self.cardsLocalPath)
            })
            processes.append({
                try await self.fetchData(from: self.rulingsRemotePath, saveTo: self.rulingsLocalPath)
            })
            processes.append({
                try await self.fetchData(from: self.rulesRemotePath, saveTo: self.rulesLocalPath)
            })
            processes.append({
                try await self.downloadSetLogos()
            })
            processes.append({
                try await self.fetchCardImages()
            })
            processes.append({
                try await self.fetchMigrations()
            })
            
            // updates
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
        }
        
        processes.append({
            try await self.processPricingData()
        })
        processes.append({
            try await self.processServerUpdate()
        })
        processes.append({
            try await self.processServerReindex()
        })
        processes.append({
            try await self.processServerVacuum()
        })

        try await exec(processes: processes)

        do {
            if FileManager.default.fileExists(atPath: self.bulkDataLocalPath) {
                try FileManager.default.removeItem(atPath: self.bulkDataLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.setsLocalPath) {
                try FileManager.default.removeItem(atPath: self.setsLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.keyruneLocalPath) {
                try FileManager.default.removeItem(atPath: self.keyruneLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.cardsLocalPath) {
                try FileManager.default.removeItem(atPath: self.cardsLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.rulingsLocalPath) {
                try FileManager.default.removeItem(atPath: self.rulingsLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.rulesLocalPath) {
                try FileManager.default.removeItem(atPath: self.rulesLocalPath)
            }
            if FileManager.default.fileExists(atPath: self.milestoneLocalPath) {
                try FileManager.default.removeItem(atPath: self.milestoneLocalPath)
            }
        } catch {
            print(error)
        }
        self.endActivity(label: label, from: dateStart)
        exit(EXIT_SUCCESS)
    }

    // MARK: - Bulk Data methods

    func createBulkData() async throws {
        let _ = bulkArray
    }
    
    func bulkData() -> [[String: Any]] {
        let data = try! Data(contentsOf: URL(fileURLWithPath: bulkDataLocalPath))
        guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                           options: .mutableContainers) as? [String: Any] else {
            fatalError("Malformed data")
        }
        guard let array = dict["data"] as? [[String: Any]] else {
            fatalError("Malformed data")
        }

        for dict in array {
            for (k,v) in dict {
                if k == "name" {
                    if let value = v as? String {
                        switch value {
                        case "All Cards":
                            if let downloadURI = dict["download_uri"] as? String {
                                cardsRemotePath = downloadURI
                                
                                if let last = cardsRemotePath.components(separatedBy: "/").last {
                                    cardsLocalPath = "\(cachePath)/managuide-\(last)"
                                }
                            }
                        case "Rulings":
                            if let downloadURI = dict["download_uri"] as? String {
                                rulingsRemotePath = downloadURI
                                
                                if let last = rulingsRemotePath.components(separatedBy: "/").last {
                                    rulingsLocalPath = "\(cachePath)/managuide-\(last)"
                                }
                            }
                        default:
                            ()
                        }
                    }
                }
            }
        }
        return array
    }
    
    // MARK: - Other methods
    
    func exec(query: String, with parameters: [Any]? = nil) async throws {
        do {
            let statement = try connection.prepareStatement(text: query)
            
            if let parameters = parameters {
                let convertibles = parameters.compactMap({
                    $0 as? PostgresValueConvertible
                })
                
                try statement.execute(parameterValues: convertibles)
            } else {
                try statement.execute()
            }
            
            statement.close()
        } catch {
            print("Error in query: \(query)")
            if let parameters = parameters {
                print("With parameters: \(parameters)")
            }
            fatalError(error.localizedDescription)
        }
    }
    
    func exec(processes: [() async throws -> Void]) async throws {
        do {
            for process in processes {
                try await process()
            }
        } catch {
            throw error
        }
    }
}

