//
//  Maintainer+Cards.swift
//  Manaprobe-maintainer
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
        guard let localPath = Resource.cards.localPath(cachePath, filePrefix) else {
            return
        }

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
        
        try await processFile(label: label,
                              localPath: localPath,
                              callback: callback)
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
        
        let languages = loadData(forResource: "languages", withExtension: "plist")
        let code = lang
        var displayCode = "NULL"
        var name = "NULL"
        var nameSection = "NULL"
        
        if let language = languages[code] {
            if let value = language["display_code"] {
                displayCode = value
            }
            if let value = language["name"] {
                name = value
            }
            if let value = language["name_section"] {
                nameSection = value
            }
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
        
        let layouts = loadData(forResource: "layouts", withExtension: "plist")
        let code = layout
        let name = capitalize(string: displayFor(name: code))
        var description_ = "NULL"
        
        if let layout = layouts[code] {
            if let value = layout["description_"] {
                description_ = value
            }
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
        
        let frames = loadData(forResource: "frames", withExtension: "plist")
        let name = frame
        var description_ = "NULL"
        
        if let frame = frames[name] {
            if let value = frame["description_"] {
                description_ = value
            }
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
        
        let effects = loadData(forResource: "frameEffects", withExtension: "plist")
        
        for frameEffect in frameEffects {
            let id = frameEffect
            let name = capitalize(string: id)
            var description_ = "NULL"
            
            if let effect = effects[id] {
                if let value = effect["description_"] {
                    description_ = value
                }
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
