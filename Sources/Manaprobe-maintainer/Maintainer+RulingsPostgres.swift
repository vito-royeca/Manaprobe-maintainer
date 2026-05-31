//
//  Maintainer+RulingsPostgres.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 11/5/19.
//

import Foundation
import PostgresClientKit

extension Maintainer {
    func createRuling(dict: [String: Any]) async throws {
        let oracleId = dict["oracle_id"] as? String ?? "NULL"
        let text = dict["comment"] as? String ?? "NULL"
        let datePublished = dict["published_at"] as? String ?? "NULL"
        
        let query = "SELECT createOrUpdateRuling($1,$2,$3)"
        let parameters = [
            oracleId,
            text,
            datePublished
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createDeleteRulings() async throws {
        try await exec(query: "DELETE FROM cmruling")
    }
}
