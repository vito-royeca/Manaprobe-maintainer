//
//  Maintainer+MaterializedViewsPostgres.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 9/15/25.
//

import Foundation

extension Maintainer {
    func deleteSetMaterializedView(code: String, language: String) async throws {
        let query = "DROP MATERIALIZED VIEW IF EXISTS matv_cmset_\(code)_\(language)"
        try await exec(query: query)
    }
    
    func createSetMaterializedView(code: String, language: String) async throws {
        let query = "SELECT createSetMaterializedView($1,$2)"
        let parameters = [code, language]
        try await exec(query: query, with: parameters)
    }
    
    func updateSetMaterializedView(code: String, language: String) async throws {
        let query = "SELECT updateSetMaterializedView($1,$2)"
        let parameters = [code, language]
        try await exec(query: query, with: parameters)
    }
    
    func createSetsMaterializedView() async throws {
        let query = "SELECT createSetsMaterializedView()"
        try await exec(query: query)
    }

    func updateSetsMaterializedView() async throws {
        let query = "SELECT updateSetsMaterializedView()"
        try await exec(query: query)
    }
}
