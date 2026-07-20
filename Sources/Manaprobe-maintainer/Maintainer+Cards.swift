//
//  Maintainer+Cards.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 21.10.18.
//

import Foundation
import PostgresClientKit

enum CardsDataType {
    case misc, cards, partsAndFaces
}

extension Maintainer {
    func processCardsData(type: CardsDataType) async throws {
        let label = switch type {
        case .misc:
            "createMiscData"
        case .cards:
            "createCards"
        case .partsAndFaces:
            "createCardPartsAndFaces"
        }
        let date = startActivity(label: label)
        let callback: ([[String: Any]]) -> [() async throws -> Void] = { cards in
            var processes = [() async throws -> Void]()
            
            for card in cards {
                switch type {
                case .misc:
                    processes.append(contentsOf: self.createMiscCardProcesses(dict: card))
                case .cards:
                    processes.append(contentsOf: self.createCardProcesses(dict: card))
                case .partsAndFaces:
                    processes.append(contentsOf: self.createCardPartsAndFacesProcesses(dict: card))
                }
                
            }
            return processes
        }
        
        try await processCards(label: label, callback: callback)
        endActivity(label: label, from: date)
    }
    
    private func createMiscCardProcesses(dict: [String: Any]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        if let artist = dict["artist"] as? String {
            for person in artist.components(separatedBy: "&").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
                if !person.isEmpty {
                    let array = filter(artist: person)
                    
                    if artistsCache[array[0]] == nil {
                        artistsCache[array[0]] = array
                        
                        processes.append({
                            try await self.create(artist: person)
                        })
                    }
                }
            }
        }
        
        if let rarity = dict["rarity"] as? String {
            if !raritiesCache.contains(rarity) {
                raritiesCache.append(rarity)
                
                processes.append({
                    try await self.create(rarity: rarity)
                })
            }
        }
        
        if let language = filterLanguage(dict: dict) {
            if languagesCache.filter({ $0["code"] == language["code"] }).isEmpty {
                languagesCache.append(language)
                
                processes.append({
                    try await self.createLanguage(code: language["code"] ?? "NULL",
                                                  displayCode: language["display_code"] ?? "NULL",
                                                  name: language["name"] ?? "NULL")
                })
            }
        }
        
        if let watermark = dict["watermark"] as? String {
            if !watermarksCache.contains(watermark) {
                watermarksCache.append(watermark)
                
                processes.append({
                    try await self.create(watermark: watermark)
                })
            }
        }
        
        if let layout = filterLayout(dict: dict) {
            if layoutsCache.filter({ $0["code"] == layout["code"] }).isEmpty {
                layoutsCache.append(layout)
                
                processes.append({
                    try await self.createLayout(code: layout["code"] ?? "NULL",
                                                name: layout["name"] ?? "NULL",
                                                description_: layout["description_"] ?? "NULL")
                })
            }
        }
        
        if let frame = filterFrame(dict: dict) {
            if framesCache.filter({ $0["name"] == frame["name"] }).isEmpty {
                framesCache.append(frame)
                
                processes.append({
                    try await self.createFrame(name: frame["name"] ?? "NULL",
                                               description_: frame["description_"] ?? "NULL")
                })
            }
        }
        
        for frameEffect in filterFrameEffects(dict: dict) {
            if frameEffectsCache.filter({ $0["id"] == frameEffect["id"] }).isEmpty {
                frameEffectsCache.append(frameEffect)
                
                processes.append({
                    try await self.createFrameEffect(id: frameEffect["id"] ?? "NULL",
                                                     name: frameEffect["name"] ?? "NULL",
                                                     description_: frameEffect["description_"] ?? "NULL")
                })
            }
        }
        
        for color in filterColors(dict: dict) {
            if colorsCache.filter({ $0["name"] as? String ?? "NULL" == color["name"] as? String ?? "NULL" }).isEmpty {
                colorsCache.append(color)
                
                processes.append({
                    try await self.createColor(symbol: color["symbol"] as? String ?? "NULL",
                                               name: color["name"] as? String ?? "NULL",
                                               isManaColor: color["is_mana_color"] as? Bool ?? false)
                })
            }
        }
        
        if let dictLegalities = dict["legalities"] as? [String: String] {
            for key in dictLegalities.keys {
                if !formatsCache.contains(key) {
                    formatsCache.append(key)
                    
                    processes.append({
                        try await self.create(format: key)
                    })
                }
            }
            for value in dictLegalities.values {
                if !legalitiesCache.contains(value) {
                    legalitiesCache.append(value)
                    
                    processes.append({
                        try await self.create(legality: value)
                    })
                }
            }
        }
        
        for type in filterTypes(dict: dict) {
            if typesCache.filter({ $0["name"] as? String ?? "NULL" == type["name"] as? String ?? "NULL" }).isEmpty {
                typesCache.append(type)
                
                processes.append({
                    try await self.createCardType(name: type["name"] as? String ?? "NULL",
                                                  parent: type["parent"] as? String ?? "NULL")
                })
            }
        }
        
        for component in filterComponents(dict: dict) {
            if !componentsCache.contains(component) {
                componentsCache.append(component)
                
                processes.append({
                    try await self.create(component: component)
                })
            }
        }
        
        if let games = dict["games"] as? [String] {
            for game in games {
                if !gamesCache.contains(game) {
                    gamesCache.append(game)
                    
                    processes.append({
                        try await self.create(game: game)
                    })
                }
            }
        }
        
        if let keywords = dict["keywords"] as? [String] {
            for keyword in keywords {
                if !keywordsCache.contains(keyword) {
                    keywordsCache.append(keyword)
                    
                    processes.append({
                        try await self.create(keyword: keyword)
                    })
                }
            }
        }
            
        return processes
    }
    
    private func createCardProcesses(dict: [String: Any]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        processes.append({
            try await self.create(card: dict)
        })

        return processes
    }
    
    private func createCardPartsAndFacesProcesses(dict: [String: Any]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        
        if let parts = self.filterParts(dict: dict) {
            for part in parts {
                if let card = part["cmcard"] as? String,
                   let component = part["cmcomponent"] as? String,
                   let cardPart = part["cmcard_part"] as? String {
                    processes.append({
                        try await self.createPart(card: card,
                                                  component: component,
                                                  cardPart: cardPart)
                    })
                }
            }
        }

        if let faces = self.filterFaces(dict: dict) {
            for face in faces {
                processes.append(contentsOf: self.createMiscCardProcesses(dict: face))
                processes.append({
                    try await self.create(card: face)
                })
                
                if let card = face["cmcard"] as? String,
                   let cardFace = face["new_id"] as? String {
                    processes.append({
                        try await self.createFace(card: card,
                                                  cardFace: cardFace)
                    })
                }
            }
        }
        
        return processes
    }
    
    private func filterLanguage(dict: [String: Any]) -> [String: String]? {
        guard let lang = dict["lang"] as? String else {
            return nil
        }
        
        let code = lang
        var displayCode = "NULL"
        var name = "NULL"
        var nameSection = "NULL"
        
        switch code {
        case "en":
            displayCode = "EN"
            name = "English"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "es":
            displayCode = "ES"
            name = "Spanish"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "fr":
            displayCode = "FR"
            name = "French"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "de":
            displayCode = "DE"
            name = "German"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "it":
            displayCode = "IT"
            name = "Italian"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "pt":
            displayCode = "PT"
            name = "Portuguese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ja":
            displayCode = "JP"
            name = "Japanese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ko":
            displayCode = "KR"
            name = "Korean"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ru":
            displayCode = "RU"
            name = "Russian"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "zhs":
            displayCode = "CS"
            name = "Simplified Chinese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "zht":
            displayCode = "CT"
            name = "Traditional Chinese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "he":
            name = "Hebrew"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "la":
            name = "Latin"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "grc":
            name = "Ancient Greek"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ar":
            name = "Arabic"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "sa":
            name = "Sanskrit"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ph":
            name = "Phyrexian"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "qya":
            name = "Quenya"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "dw":
            name = "Dwarvish"
            nameSection = sectionFor(name: name) ?? "NULL"
        default:
            ()
        }
        
        return [
            "code": code,
            "display_code": displayCode,
            "name": name,
            "name_section": nameSection
        ]
    }
    
    private func filterLayout(dict: [String: Any]) -> [String: String]? {
        guard let layout = dict["layout"] as? String else {
            return nil
        }
        
        let code = layout
        let name = capitalize(string: displayFor(name: code))
        var description_ = "NULL"
        
        switch code {
        case "normal":
            description_ = "A standard Magic card with one face"
        case "split":
            description_ = "A split-faced card"
        case "flip":
            description_ = "Cards that invert vertically with the flip keyword"
        case "transform":
            description_ = "Double-sided cards that transform"
        case "modal_dfc":
            description_ = "Double-sided cards that can be played either-side"
        case "meld":
            description_ = "Cards with meld parts printed on the back"
        case "leveler":
            description_ = "Cards with Level Up"
        case "class":
            description_ = "Class-type enchantment cards"
        case "case":
            description_ = "Case-type enchantment cards"
        case "saga":
            description_ = "Saga-type cards"
        case "adventure":
            description_ = "Cards with an Adventure spell part"
        case "prepare":
            description_ = "Cards with a prepared spell part"
        case "mutate":
            description_ = "Cards with Mutate"
        case "prototype":
            description_ = "Cards with Prototype"
        case "battle":
            description_ = "Battle-type cards"
        case "planar":
            description_ = "Plane and Phenomenon-type cards"
        case "scheme":
            description_ = "Scheme-type cards"
        case "vanguard":
            description_ = "Vanguard-type cards"
        case "token":
            description_ = "Token cards"
        case "double_faced_token":
            description_ = "Tokens with another token printed on the back"
        case "emblem":
            description_ = "Emblem cards"
        case "augment":
            description_ = "Cards with Augment"
        case "host":
            description_ = "Host-type cards"
        case "art_series":
            description_ = "Art Series collectable double-faced cards"
        case "reversible_card":
            description_ = "A Magic card with two sides that are unrelated"
        default:
            ()
        }

        return [
            "code": code,
            "name": name,
            "description_": description_
        ]
    }
    
    private func filterFrame(dict: [String: Any]) -> [String: String]? {
        guard let frame = dict["frame"] as? String else {
            return nil
        }
        
        let name = frame
        var description_ = "NULL"
        
        switch name {
        case "1993":
            description_ = "The original Magic card frame, starting from Limited Edition Alpha."
        case "1997":
            description_ = "The updated classic frame starting from Mirage block."
        case "2003":
            description_ = "The \"modern\" Magic card frame, introduced in Eighth Edition and Mirrodin block."
        case "2015":
            description_ = "The holofoil-stamp Magic card frame, introduced in Magic 2015."
        case "future":
            description_ = "The frame used on cards from the future."
        default:
            ()
        }
        return [
            "name": name,
            "description_": description_
        ]
    }
    
    private func filterFrameEffects(dict: [String: Any]) -> [[String: String]] {
        var array = [[String: String]]()
        
        guard let frameEffects = dict["frame_effects"] as? [String] else {
            return array
        }
        
        for frameEffect in frameEffects {
            let id = frameEffect
            var name = "NULL"
            var description_ = "NULL"
            
            switch id {
            case "legendary":
                name = capitalize(string: id)
                description_ = "The cards have a legendary crown"
            case "miracle":
                name = capitalize(string: id)
                description_ = "The miracle frame effect"
            case "enchantment":
                name = capitalize(string: id)
                description_ = "The enchantment frame effect"
            case "draft":
                name = capitalize(string: id)
                description_ = "The draft-matters frame effect"
            case "devoid":
                name = capitalize(string: id)
                description_ = "The Devoid frame effect"
            case "tombstone":
                name = capitalize(string: id)
                description_ = "The Odyssey tombstone mark"
            case "colorshifted":
                name = capitalize(string: id)
                description_ = "A colorshifted frame"
            case "inverted":
                name = capitalize(string: id)
                description_ = "Predominantly inverted text"
            case "sunmoondfc":
                name = capitalize(string: id)
                description_ = "The sun and moon transform marks"
            case "compasslanddfc":
                name = capitalize(string: id)
                description_ = "The compass and land transform marks"
            case "originpwdfc":
                name = capitalize(string: id)
                description_ = "The Origins and planeswalker transform marks"
            case "mooneldrazidfc":
                name = capitalize(string: id)
                description_ = "The moon and Eldrazi transform marks"
            case "waxingandwaningmoondfc":
                name = capitalize(string: id)
                description_ = "The waxing and waning crescent moon transform marks"
            case "showcase":
                name = capitalize(string: id)
                description_ = "A custom Showcase frame"
            case "extendedart":
                name = capitalize(string: id)
                description_ = "An extended art frame"
            case "companion":
                name = capitalize(string: id)
                description_ = "The cards have a companion frame"
            case "etched":
                name = capitalize(string: id)
                description_ = "The cards have an etched foil treatment"
            case "snow":
                name = capitalize(string: id)
                description_ = "The cards have the snowy frame effect"
            case "lesson":
                name = capitalize(string: id)
                description_ = "The cards have the Lesson frame effect"
            case "shatteredglass":
                name = capitalize(string: id)
                description_ = "The cards have the Shattered Glass frame effect"
            case "convertdfc":
                name = capitalize(string: id)
                description_ = "The cards have More Than Meets the Eye™ marks"
            case "fandfc":
                name = capitalize(string: id)
                description_ = "The cards have fan transforming marks"
            case "upsidedowndfc":
                name = capitalize(string: id)
                description_ = "The cards have the Upside Down transforming marks"
            case "spree":
                name = capitalize(string: id)
                description_ = "The cards have Spree asterisks"
            default:
                ()
            }
        
            array.append([
                "id": id,
                "name": name,
                "description_": description_
            ])
        }
        
        return array
    }
    
    func filterColors(dict: [String: Any]) -> [[String: Any]] {
        var array = [[String: Any]]()
        
        guard let colors = dict["colors"] as? [String] else {
            return array
        }
        
        array = colors.compactMap({
            let symbol = $0
            var name = "NULL"

            switch symbol {
            case "B":
                name = "Black"
            case "G":
                name = "Green"
            case "R":
                name = "Red"
            case "U":
                name = "Blue"
            case "W":
                name = "White"
            default:
                ()
            }

            return [
                "symbol": symbol,
                "name": name,
                "is_mana_color": true
            ]
        })
        
        return array
    }
    
    func filter(artist: String) -> [String] {
        var name = "NULL"
        var firstName = "NULL"
        var lastName = "NULL"
        var nameSection = "NULL"
        var info = "NULL"
        
        var names = [String]()
        var tempName = ""
        var suffix = ""

        if artist.lowercased().hasSuffix("inc.") {
            return [artist,
                    firstName,
                    lastName,
                    sectionFor(name: artist) ?? "NULL",
                    info]
        }

        if artist.contains(",") {
            let array = artist.components(separatedBy: ",")

            if let last = array.last {
                if last.lowercased().hasSuffix("jr.") ||
                    last.lowercased().hasSuffix("sr.") {
                    suffix = last.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    info = last.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if let first = array.first {
                tempName = first.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            tempName = artist
        }

        if tempName.contains("(") {
            if let slice = artist.slice(from: "(",
                                        to: ")") {
                
                info = slice.trimmingCharacters(in: .whitespacesAndNewlines)
                tempName = tempName.replacing(slice.trimmingCharacters(in: .whitespacesAndNewlines),
                                              with: "")
                    .replacing("(",
                               with: "")
                    .replacing(")",
                               with: "")
                    .replacing("--",
                               with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if tempName.contains("“") {
            tempName = tempName.replacing("“",
                                          with: "\"")
                               .replacing("”",
                                          with: "\"")
            
            if let slice = tempName.slice(from: "\"",
                                           to: "\"") {
                
                if info == "NULL" {
                    info = slice.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    info.append("; \(slice)")
                }
                
                tempName = tempName.replacing(slice.trimmingCharacters(in: .whitespacesAndNewlines),
                                              with: "")
                    .replacing("\"",
                               with: "")
                    .replacing("--",
                               with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        names = tempName.components(separatedBy: " ")
        
        if names.count > 1 {
            if let last = names.last {
                lastName = last.trimmingCharacters(in: .whitespacesAndNewlines)
                nameSection = lastName
            }
            
            firstName = ""
            for i in 0...names.count - 2 {
                firstName.append("\(names[i])")
                if i != names.count - 2 && names.count >= 3 {
                    firstName.append(" ")
                }
            }
            firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } else {
            if let first = names.first {
                firstName = first.trimmingCharacters(in: .whitespacesAndNewlines)
                nameSection = firstName
            }
        }
        
        if let section =  sectionFor(name: nameSection) {
            nameSection = section
        }
        
        name = "\(firstName == "NULL" ? "" : firstName) \(lastName == "NULL" ? "" : lastName)\(!suffix.isEmpty ? ", \(suffix)" : "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !suffix.isEmpty {
            firstName.append(" \(suffix)")
        }
        
        return [name,
                firstName,
                lastName,
                nameSection,
                info]
    }

    private func filterTypes(dict: [String: Any]) -> [[String: Any]] {
        guard let typeLine = dict["type_line"] as? String else {
            return [[String: Any]]()
        }
        
        return extractTypesFrom(typeLine)
    }
    
    private func filterComponents(dict: [String: Any]) -> [String] {
        var array = [String]()
        
        guard let parts = dict["all_parts"] as? [[String: Any]] else {
            return array
        }
        
        for part in parts {
            if let component = part["component"] as? String {
                array.append(component)
            }
        }
        
        return array
    }
    
    private func filterParts(dict: [String: Any]) -> [[String: Any]]? {
        guard let parts = dict["all_parts"] as? [[String: Any]],
              let set = dict["set"] as? String,
              let language = dict["lang"] as? String,
              let collectorNumber = dict["collector_number"] as? String else {
            return nil
        }
        
        let cleanCollectorNumber = collectorNumber.replacingOccurrences(of: "★", with: "star")
                                                  .replacingOccurrences(of: "†", with: "cross")
        let newId = "\(set)_\(language)_\(cleanCollectorNumber)"
        var array = [[String: Any]]()
        
        for i in 0...parts.count-1 {
            let part = parts[i]
            
            if let partId = part["id"] as? String,
                let component = part["component"] as? String {
                array.append(["cmcard": newId,
                              "cmcomponent": component,
                              "cmcard_part": partId])
            }
        }
        
        return array
    }
    
    private func filterFaces(dict: [String: Any]) -> [[String: Any]]? {
        guard let faces = dict["card_faces"] as? [[String: Any]],
              let set = dict["set"] as? String,
              let language = dict["lang"] as? String,
              let collectorNumber = dict["collector_number"] as? String else {
            return nil
        }
        
        let cleanCollectorNumber = collectorNumber.replacingOccurrences(of: "★", with: "star")
                                                  .replacingOccurrences(of: "†", with: "cross")
        let newId = "\(set)_\(language)_\(cleanCollectorNumber)"
        var array = [[String: Any]]()
        
        for i in 0...faces.count-1 {
            let face = faces[i]
            let faceId = "\(newId)_\(i)"
            var newFace = [String: Any]()

            for (k,v) in face {
                newFace[k] = v
            }

            newFace["face_order"] = i
            newFace["cmcard"] = newId
            newFace["new_id"] = faceId

            array.append(newFace)
        }
        
        return array
    }
    
    func extractTypesFrom(_ typeLine: String) -> [[String: String]]  {
        var filteredTypes = [[String: String]]()
        
        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                filteredTypes.append(contentsOf: extractTypesFrom(type))
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)
            
            if let first = s.first,
               let last = s.last {

                let cleanFirst = clean(type: first)
                let cleanLast = clean(type: last)
                
                if !cleanFirst.isEmpty,
                   !cleanLast.isEmpty,
                   filteredTypes.filter({ $0["name"] == cleanLast }).isEmpty {
                    filteredTypes.append([
                        "name": cleanLast,
                        "parent": cleanFirst
                    ])
                }
            
                if !cleanFirst.isEmpty,
                   filteredTypes.filter({ $0["name"] == cleanFirst }).isEmpty {
                    filteredTypes.append([
                        "name": cleanFirst,
                        "parent": "NULL"
                    ])
                }
            }
        } else {
            let cleanTypeline = clean(type: typeLine)
            
            if !cleanTypeline.isEmpty,
               filteredTypes.filter({ $0["name"] == cleanTypeline }).isEmpty {
                filteredTypes.append([
                    "name": cleanTypeline,
                    "parent": "NULL"
                ])
            }
        }
        
        return filteredTypes
    }

    func extractSupertypesFrom(_ typeLine: String) -> Set<String>  {
        var types = Set<String>()

        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                for s in extractSupertypesFrom(type) {
                    types.insert(s)
                }
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)

            if let first = s.first {
                for string in filterTypesFrom(first) {
                    types.insert(string)
                }
            }
        } else {
            for string in filterTypesFrom(typeLine) {
                types.insert(string)
            }
        }

        return types
    }

    func extractSubtypesFrom(_ typeLine: String) -> Set<String>  {
        var types = Set<String>()

        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                for s in extractSubtypesFrom(type) {
                    types.insert(s)
                }
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)

            if let last = s.last {
                for string in filterTypesFrom(last) {
                    types.insert(string)
                }
            }
        } else {
            for string in filterTypesFrom(typeLine) {
                types.insert(string)
            }
        }

        return types
    }

    private func filterTypesFrom(_ string: String) -> Set<String>  {
        var types = Set<String>()
        
        let cleanTypeline = clean(type: string)
        
        if !cleanTypeline.isEmpty {
            types.insert(cleanTypeline)
        }
        
        return types
    }

    private func clean(type: String) -> String  {
        var cleanType = type
                .replacingOccurrences(of: emdash, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanType.contains(" ") {
            cleanType = cleanType.capitalized
        }
        
        return cleanType
    }
}
