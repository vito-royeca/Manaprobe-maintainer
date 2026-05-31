//
//  Maintainer+Images.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 1/12/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import PostgresClientKit

struct Milestone : Codable {
    var value: Int
    var fileOffset: UInt64
}
struct CardStatus : Codable {
    var status: String
}

extension Maintainer {
    func fetchCardImages() async throws {
        let label = "fetchCardImages"
        let date = startActivity(label: label)
        let callback: ([[String: Any]]) -> [() async throws -> Void] = { cards in
            var processes = [() async throws -> Void]()
            
            for card in cards {
                processes.append(contentsOf: self.createImageDownloads(dict: card))
            }
            return processes
        }
        
        try await processCards(label: label, callback: callback)
        endActivity(label: label, from: date)
    }
    
    private func createImageDownloads(dict: [String: Any]) -> [() async throws -> Void] {
        var processes = [() async throws -> Void]()
        var filteredData = [[String: Any]]()
        
        guard let number = dict["collector_number"] as? String,
              let language = dict["lang"] as? String,
              let set = dict["set"] as? String else {
            return processes
        }
        
        let cleanNumber = number.replacingOccurrences(of: "★", with: "star")
                                .replacingOccurrences(of: "†", with: "cross")
        
        if let imageStatus = dict["image_status"] as? String,
            let imageUrisDict = dict["image_uris"] as? [String: String] {
            let imageUrisDict = createImageUris(number: cleanNumber,
                                                set: set,
                                                language: language,
                                                imageStatus: imageStatus,
                                                imageUrisDict: imageUrisDict)
            filteredData.append(imageUrisDict)
        }
        
        if let faces = dict["card_faces"] as? [[String: Any]] {
            for i in 0...faces.count-1 {
                let face = faces[i]
                
                if let imageStatus = dict["image_status"] as? String,
                    let imageUrisDict = face["image_uris"] as? [String: String] {
                    let faceImageUrisDict = createImageUris(number: "\(cleanNumber)_\(i)",
                                                            set: set,
                                                            language: language,
                                                            imageStatus: imageStatus,
                                                            imageUrisDict: imageUrisDict)
                    filteredData.append(faceImageUrisDict)
                }
            }
        }
        
        for dict in filteredData {
            processes.append({
                try await self.createImageDownload(dict: dict)
            })
        }

        return processes
    }
    
    private func createImageDownload(dict: [String: Any]) async throws {
        
        guard let number = dict["number"] as? String,
            let language = dict["language"] as? String,
            let set = dict["set"] as? String,
            let imageStatus = dict["imageStatus"] as? String,
            let imageUris = dict["imageUris"] as? [String: String] else {
            
            let error = NSError(domain: "Error",
                                code: 500,
                                userInfo: [NSLocalizedDescriptionKey: "Wrong download keys"])
            throw error
        }
        
        let path   = "\(imagesPath)/\(set)/\(language)/\(number)"
        var processes = [() async throws -> Void]()
        
        for (k,v) in imageUris {
            if !(k == "art_crop" || k == "normal" || k == "png") ||
                (v.hasSuffix("soon.jpg") || v.hasSuffix("soon.png")) {
                continue
            }
            
            var imageFile = "\(path)/\(k)"
            var willDownload = false
            
            if v.lowercased().contains(".png") {
                imageFile = "\(imageFile).png"
            } else if v.lowercased().contains(".jpg") {
                imageFile = "\(imageFile).jpg"
            }
            
            if FileManager.default.fileExists(atPath: imageFile) {
                if let status = self.readStatus(directoryPath: path) {
                    if imageStatus != status {
                        willDownload = true
                    }
                } else {
                    willDownload = true
                }
            } else {
                willDownload = true
            }
            
            if willDownload {
                processes.append({
                    self.prepare(destinationFile: imageFile)
                    try await self.fetchData(from: v, saveTo: imageFile)
                })
                                               
            }
        }

        if !processes.isEmpty {
            try await exec(processes: processes)
            print("Downloaded \(set)/\(language)/\(number)")
            writeStatus(directoryPath: path, status: imageStatus)
        }
    }
    
    private func createImageUris(number: String, set: String, language: String, imageStatus: String, imageUrisDict: [String: String]) -> [String: Any] {
        var newDict = [String: Any]()
        
        // remove the key (?APIKEY) in the url
        var newImageUris = [String: String]()
        for (k,v) in imageUrisDict {
            newImageUris[k] = v//.components(separatedBy: "?").first
        }
    
        newDict["number"]      =  number
        newDict["language"]    =  language
        newDict["set"]         =  set
        newDict["imageStatus"] =  imageStatus
        newDict["imageUris"]   =  newImageUris
        
        return newDict
    }
}
