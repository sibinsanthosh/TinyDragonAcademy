//
//  PersistenceService.swift
//  Tiny Dragon Academy
//
//  Robust 100% offline local persistence using JSON storage in Documents directory.
//  Preserves dragons, island decorations, mini-game stars, and user settings between launches.
//

import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    
    private let fileName = "tiny_dragon_academy_save.json"
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    private init() {}
    
    func loadState() -> AppProgressState {
        do {
            let data = try Data(contentsOf: saveURL)
            let decoder = JSONDecoder()
            let state = try decoder.decode(AppProgressState.self, from: data)
            return state
        } catch {
            print("No saved state found or parse error (\(error.localizedDescription)). Using initial state.")
            return AppProgressState.initial()
        }
    }
    
    func saveState(_ state: AppProgressState) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(state)
            try data.write(to: saveURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save state: \(error.localizedDescription)")
        }
    }
    
    func resetAllData() {
        do {
            if FileManager.default.fileExists(atPath: saveURL.path) {
                try FileManager.default.removeItem(at: saveURL)
            }
        } catch {
            print("Failed to remove save file: \(error.localizedDescription)")
        }
    }
}
