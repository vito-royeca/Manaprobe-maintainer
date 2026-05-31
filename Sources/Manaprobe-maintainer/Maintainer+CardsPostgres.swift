//
//  Maintainer+CardsPostgres.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 10/27/19.
//

import Foundation
import PostgresClientKit

extension Maintainer {
    func processOtherCardsData() async throws {
        
        let label = "processOtherCardsData"
        let date = startActivity(label: label)
            
        try await createOtherLanguages()
        try await createOtherPrintings()
        try await createVariations()
            
        endActivity(label: label, from: date)
    }
    
    func create(artist: String) async throws {
        let query = "SELECT createOrUpdateArtist($1,$2,$3,$4,$5)"
        try await exec(query: query, with: filter(artist: artist))
    }
    
    func create(rarity: String) async throws {
        let capName = capitalize(string: displayFor(name: rarity))
        let nameSection = sectionFor(name: rarity) ?? "NULL"
        
        let query = "SELECT createOrUpdateRarity($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createLanguage(code: String, displayCode: String, name: String) async throws {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateLanguage($1,$2,$3,$4)"
        let parameters = [
            code,
            displayCode,
            name,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createLayout(code: String, name: String, description_: String) async throws {
        let query = "SELECT createOrUpdateLayout($1,$2,$3)"
        let parameters = [
            code,
            name,
            description_
        ]
        try await exec(query: query, with: parameters)
    }
    
    func create(watermark: String) async throws {
        let capName = capitalize(string: displayFor(name: watermark))
        let nameSection = sectionFor(name: watermark) ?? "NULL"
        
        let query = "SELECT createOrUpdateWatermark($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createFrame(name: String, description_: String) async throws {
        let capName = capitalize(string: displayFor(name: name))
        
        let query = "SELECT createOrUpdateFrame($1,$2)"
        let parameters = [
            capName,
            description_
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createFrameEffect(id: String, name: String, description_: String) async throws {
        let query = "SELECT createOrUpdateFrameEffect($1,$2,$3)"
        let parameters = [
            id,
            name,
            description_
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createColor(symbol: String, name: String, isManaColor: Bool) async throws {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateColor($1,$2,$3,$4)"
        let parameters = [symbol,
                          name,
                          nameSection,
                          isManaColor] as [Any]
        try await exec(query: query, with: parameters)
    }
    
    func create(format: String) async throws {
        let capName = capitalize(string: displayFor(name: format))
        let nameSection = sectionFor(name: format) ?? "NULL"
        
        let query = "SELECT createOrUpdateFormat($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func create(legality: String) async throws {
        let capName = capitalize(string: displayFor(name: legality))
        let nameSection = sectionFor(name: legality) ?? "NULL"
        
        let query = "SELECT createOrUpdateLegality($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createCardType(name: String, parent: String) async throws {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateCardType($1,$2,$3)"
        let parameters = [
            name,
            nameSection,
            parent
        ]
        try await exec(query: query, with: parameters)
    }
    
    func create(component: String) async throws {
        let capName = capitalize(string: displayFor(name: component))
        let nameSection = sectionFor(name: component) ?? "NULL"
        
        let query = "SELECT createOrUpdateComponent($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createFace(card: String, cardFace: String) async throws {
        let query = "SELECT createOrUpdateCardFaces($1,$2)"
        let parameters = [
            card,
            cardFace
        ]
        try await exec(query: query, with: parameters)
    }
    
    func createPart(card: String, component: String, cardPart: String) async throws {
        let capName = capitalize(string: displayFor(name: component))
        
        let query = "SELECT createOrUpdateCardParts($1,$2,$3)"
        let parameters = [
            card,
            capName,
            cardPart
        ]
        try await exec(query: query, with: parameters)
    }

    func createOtherLanguages() async throws {
        try await exec(query: "select createOrUpdateCardOtherLanguages()")
    }

    func createOtherPrintings() async throws {
        try await exec(query: "select createOrUpdateCardOtherPrintings()")
    }
    
    func createVariations() async throws {
        try await exec(query: "select createOrUpdateCardVariations()")
    }
    
    func create(game: String) async throws {
        let capName = capitalize(string: displayFor(name: game))
        let nameSection = sectionFor(name: game) ?? "NULL"
        
        let query = "SELECT createOrUpdateGame($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func create(keyword: String) async throws {
        let capName = capitalize(string: displayFor(name: keyword))
        let nameSection = sectionFor(name: keyword) ?? "NULL"
        
        let query = "SELECT createOrUpdateKeyword($1,$2)"
        let parameters = [
            capName,
            nameSection
        ]
        try await exec(query: query, with: parameters)
    }
    
    func create(card: [String: Any]) async throws {
        let collectorNumber = card["collector_number"] as? String ?? "NULL"
        let cmc = card["cmc"] as? Double ?? Double(0)
        let flavorText = card["flavor_text"] as? String ?? "NULL"
        let isFoil = card["foil"] as? Bool ?? false
        let isFullArt = card["full_art"] as? Bool ?? false
        let isHighresImage = card["highres_image"] as? Bool ?? false
        let isNonfoil = card["nonfoil"] as? Bool ?? false
        let isOversized = card["oversized"] as? Bool ?? false
        let isReserved = card["reserved"] as? Bool ?? false
        let isStorySpotlight = card["story_spotlight"] as? Bool ?? false
        let language = card["lang"] as? String ?? "NULL"
        let loyalty = card["loyalty"] as? String ?? "NULL"
        let manaCost = card["mana_cost"] as? String ?? "NULL"
        
        var multiverseIds = "{}"
        if let a = card["multiverse_ids"] as? [Int],
            !a.isEmpty {
            multiverseIds = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var nameSection = "NULL"
        if let name = card["name"] as? String {
            nameSection = sectionFor(name: name) ?? "NULL"
        }

        var numberOrder = Double(0)
        if collectorNumber != "NULL" {
            numberOrder = order(of: collectorNumber)
        }
        
        let name = card["name"] as? String ?? "NULL"
        let oracleText = card["oracle_text"] as? String ?? "NULL"
        let power = card["power"] as? String ?? "NULL"
        let printedName = card["printed_name"] as? String ?? "NULL"
        let printedText = card["printed_text"] as? String ?? "NULL"
        let toughness = card["toughness"] as? String ?? "NULL"
        let arenaId = card["arena_id"] as? String ?? "NULL"
        let mtgoId = card["mtgo_id"] as? String ?? "NULL"
        let tcgplayerId = card["tcgplayer_id"] as? Int ?? Int(0)
        let handModifier = card["hand_modifier"] as? String ?? "NULL"
        let lifeModifier = card["life_modifier"] as? String ?? "NULL"
        let isBooster = card["booster"] as? Bool ?? false
        let isDigital = card["digital"] as? Bool ?? false
        let isPromo = card["promo"] as? Bool ?? false
        let releasedAt = card["released_at"] as? String ?? "NULL"
        let isTextless = card["textless"] as? Bool ?? false
        let mtgoFoilId = card["mtgo_foil_id"] as? String ?? "NULL"
        let isReprint = card["reprint"] as? Bool ?? false
        let set = card["set"] as? String ?? "NULL"
        let rarity = capitalize(string: card["rarity"] as? String ?? "NULL")
        let layout = card["layout"] as? String ?? "NULL"
        let watermark = capitalize(string: card["watermark"] as? String ?? "NULL")
        let frame = capitalize(string: card["frame"] as? String ?? "NULL")
        
        var artists = "{}"
        if let a = card["artist"] as? String,
            !a.isEmpty {
            var array = [String]()
            
            for person in a.components(separatedBy: "&").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
                if !person.isEmpty {
                    let personArray = filter(artist: person)
                    if let first = personArray.first {
                        array.append(first)
                    }
                }
            }
            
            artists = "\(array)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }

        
        
        var frameEffects = "{}"
        if let a = card["frame_effects"] as? [String],
            !a.isEmpty {
            frameEffects = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colors = "{}"
        if let a = card["colors"] as? [String],
            !a.isEmpty {
            colors = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colorIdentities = "{}"
        if let a = card["color_identity"] as? [String],
            !a.isEmpty {
            colorIdentities = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colorIndicators = "{}"
        if let a = card["color_indicator"] as? [String],
            !a.isEmpty {
            colorIndicators = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var legalities = "{}"
        if let legalitiesDict = card["legalities"] as? [String: String] {
            var newLegalities = [String: String]()
            for (k,v) in legalitiesDict {
                newLegalities[capitalize(string: displayFor(name: k))] = capitalize(string: displayFor(name: v))
            }
            legalities = "\(newLegalities)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        let faceOrder = card["face_order"] as? Int ?? Int(0)
        let cleanCollectorNumber = collectorNumber.replacingOccurrences(of: "★", with: "star")
                                                  .replacingOccurrences(of: "†", with: "cross")
        let newId = card["new_id"] as? String ?? "\(set)_\(language)_\(cleanCollectorNumber)"
        let oracle_id = card["oracle_id"] as? String ?? "NULL"
        let id = card["id"] as? String ?? "NULL"

        let typeLine = (card["type_line"] as? String ?? "NULL")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")

        let printedTypeLine = (card["printed_type_line"] as? String ?? "NULL")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        var cardtypeSubtypes = "{}"
        var cardtypeSupertypes = "{}"
        if typeLine != "NULL" {
            let subtypes = extractSubtypesFrom(typeLine)
            cardtypeSubtypes = "\(subtypes)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
            
            let supertypes = extractSupertypesFrom(typeLine)
            cardtypeSupertypes = "\(supertypes)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
            
        var artCropURL = "NULL"
        var normalURL = "NULL"
        var pngURL = "NULL"
        if let imageURIs = card["image_uris"] as? [String: Any] {
            if let artCrop = imageURIs["art_crop"] as? String,
               let first = artCrop.components(separatedBy: "?").first {
                artCropURL = first
            }
            
            if let normal = imageURIs["normal"] as? String,
               let first = normal.components(separatedBy: "?").first {
                normalURL = first
            }
            
            if let png = imageURIs["png"] as? String,
               let first = png.components(separatedBy: "?").first {
                pngURL = first
            }
        }
        
        var games = "{}"
        if let a = card["games"] as? [String],
            !a.isEmpty {
            let array = a.map { capitalize(string: displayFor(name: $0)) }
            games = "\(array)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var keywords = "{}"
        if let a = card["keywords"] as? [String],
            !a.isEmpty {
            let array = a.map { capitalize(string: displayFor(name: $0)) }
            keywords = "\(array)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        let query = "SELECT createOrUpdateCard($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$50,$51,$52,$53,$54,$55,$56,$57,$58)"
        let parameters = [
            collectorNumber,
            cmc,
            flavorText,
            isFoil,
            isFullArt,
            isHighresImage,
            isNonfoil,
            isOversized,
            isReserved,
            isStorySpotlight,
            loyalty,
            manaCost,
            multiverseIds,
            nameSection,
            numberOrder,
            name,
            oracleText,
            power,
            printedName,
            printedText,
            toughness,
            arenaId,
            mtgoId,
            tcgplayerId,
            handModifier,
            lifeModifier,
            isBooster,
            isDigital,
            isPromo,
            releasedAt,
            isTextless,
            mtgoFoilId,
            isReprint,
            artists,
            set,
            rarity,
            language,
            layout,
            watermark,
            frame,
            frameEffects,
            colors,
            colorIdentities,
            colorIndicators,
            legalities,
            typeLine,
            printedTypeLine,
            cardtypeSubtypes,
            cardtypeSupertypes,
            faceOrder,
            newId,
            oracle_id,
            id,
            artCropURL,
            normalURL,
            pngURL,
            games,
            keywords
        ] as [Any]
        try await exec(query: query, with: parameters)
    }
}
