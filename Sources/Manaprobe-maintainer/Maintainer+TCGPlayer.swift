//
//  Maintainer+TCGPlayer.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 23/10/2018.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import PostgresClientKit

extension Maintainer {
    func processPricingData() async throws {
        let label = "processPricingData"
        let date = startActivity(label: label)
        var processes = [() async throws -> Void]()
        var groupIds = [Int32]()
        
        try await getTcgPlayerToken()
        if let sets = try await fetchSets() {
            for set in sets {
                for (key,value) in set {
                    if key == "tcgplayer_id",
                       let tcgPlayerId = value as? Int32,
                       tcgPlayerId > 0 {
                        groupIds.append(tcgPlayerId)
                    }
                }
            }
        }
            
        for groupId in groupIds {
            let array = try await fetchCardPricingBy(groupId: groupId)
            processes.append(contentsOf: array)
        }
        try await exec(processes: processes)
        
        endActivity(label: label, from: date)
    }

    func getTcgPlayerToken() async throws {
        let urlString = "https://api.tcgplayer.com/token"
        
        guard let cleanUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: cleanUrl) else {
            fatalError("Malformed url")
        }
        
        let query = "grant_type=client_credentials&client_id=\(TCGPlayer.publicKey)&client_secret=\(TCGPlayer.privateKey)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = query.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.asyncData(for: request)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            tcgplayerAPIToken = token
        } else {
            fatalError("access_token is nil")
        }
    }
    
    func fetchCardPricingBy(groupId: Int32) async throws -> [() async throws -> Void] {
        let urlString = "https://api.tcgplayer.com/\(TCGPlayer.apiVersion)/pricing/group/\(groupId)"

        guard let cleanUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: cleanUrl) else {
            fatalError("Malformed url")
        }
            
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(tcgplayerAPIToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.asyncData(for: request)
        var processes = [() async throws -> Void]()
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]] {
            for result in results {
                processes.append({
                    try await self.createCardPricing(price: result)
                })
            }
        }
        
        return processes
    }
    
    func createCardPricing(price: [String: Any]) async throws {
        let low = price["lowPrice"] as? Double ?? 0.0
        let median = price["midPrice"] as? Double ?? 0.0
        let high = price["highPrice"] as? Double ?? 0.0
        let market = price["marketPrice"] as? Double ?? 0.0
        let directLow = price["directLowPrice"] as? Double ?? 0.0
        let tcgPlayerId = price["productId"]  as? Int ?? 0
        let isFoil = price["subTypeName"] as? String ?? "Foil" == "Foil" ? true : false
        
        let query = "SELECT createOrUpdateCardPrice($1,$2,$3,$4,$5,$6,$7)"
        let parameters = [
            low,
            median,
            high,
            market,
            directLow,
            tcgPlayerId,
            isFoil
        ] as [Any]
        try await exec(query: query, with: parameters)
    }
}
