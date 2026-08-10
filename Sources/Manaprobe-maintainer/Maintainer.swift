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

    // TCGPlayer
    public enum TCGPlayer {
        public static let apiVersion = "v1.39.0"
        public static let apiLimit   = 300
        public static let partnerKey = "ManaGuide"
        public static let publicKey  = "A49D81FB-5A76-4634-9152-E1FB5A657720"
        public static let privateKey = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
    }
    let printMilestone     = 3000
    let cachePath          = "/tmp"
    let emdash             = "\u{2014}"
    
    // MARK: - Variables

    var tcgplayerAPIToken  = ""
    var filePrefix         = ""
    
    // local file names
//    var migrationsLocalPaths = [String]()
    
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
        
        processes.append({
            try await self.startServerUpdate()
        })
        if isFullUpdate {
            processes.append(contentsOf: fetchResources())
            processes.append(contentsOf: updateResources())
        }
        
        processes.append({
            try await self.processPricingData()
        })
        processes.append({
            try await self.processServerReindex()
        })
        processes.append({
            try await self.processServerVacuum()
        })
        processes.append({
            try await self.endServerUpdate()
        })

        try await exec(processes: processes)
        cleanResources()
        endActivity(label: label, from: dateStart)

        exit(EXIT_SUCCESS)
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

