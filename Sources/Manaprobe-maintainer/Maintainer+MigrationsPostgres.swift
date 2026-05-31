//
//  Maintainer+MigrationsPostgres.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 9/14/25.
//

extension Maintainer {
    func createMigration(new_id: String) async throws {
        
        let query = "select deleteCard($1)"
        let parameters = [
            new_id
        ]
        try await exec(query: query, with: parameters)
    }
}
