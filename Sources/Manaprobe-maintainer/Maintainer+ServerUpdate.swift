//
//  Maintainer+ServerUpdate.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 12/7/19.
//

extension Maintainer {
    func processServerUpdate() async throws {
        let query = "SELECT createServerUpdate($1)"
        let parameters = [isFullUpdate]
        
        print("processServerUpdate()...")
        try await exec(query: query, with: parameters)
    }
    
    func processServerReindex() async throws {
        print("processServerReindex()...")
        try await exec(query: "REINDEX INDEX cmartist_name_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmartist_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmframe_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmlanguage_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmlayout_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmrarity_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmset_index;")
        try await exec(query: "REINDEX INDEX cmcard_cmwatermark_index;")
        try await exec(query: "REINDEX INDEX cmcard_collector_number_index;")
        try await exec(query: "REINDEX INDEX cmcard_id_index;")
        try await exec(query: "REINDEX INDEX cmcard_name_index;")
        try await exec(query: "REINDEX INDEX cmcard_new_id_index;")
        try await exec(query: "REINDEX INDEX cmcard_tcgplayer_id_index;")
        try await exec(query: "REINDEX INDEX cmcardtype_name_index;")
        try await exec(query: "REINDEX INDEX cmlanguage_code_index;")
        try await exec(query: "REINDEX INDEX cmset_card_count_index;")
        try await exec(query: "REINDEX INDEX cmset_code_index;")
    }

    func processServerVacuum() async throws {
        print("processServerVacuum()...")
        try await exec(query: "VACUUM FULL ANALYZE;")
    }
}
