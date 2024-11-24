//
//  StorageManager.swift
//  RickAndMortyYapDatabase2.0
//
//  Created by Ибрагим Габибли on 08.11.2024.
//

import Foundation
import UIKit
import YapDatabase

class DatabaseManager {
    static let shared = DatabaseManager()

    private let charactersCollection = "characters"
    private let imagesCollection = "images"
    private let charactersOrderCollection = "charactersOrder"
    private let database: YapDatabase
    private let connection: YapDatabaseConnection

    private init() {
        do {
            database = try DatabaseManager.setupDatabase()
            database.registerCodableSerialization(Character.self, forCollection: charactersCollection)
            connection = database.newConnection()
        } catch {
            fatalError("Failed to initialize YapDatabase with error: \(error)")
        }
    }

    private static func setupDatabase() throws -> YapDatabase {
        guard let baseDir = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask).first else {
            throw YapDatabaseError.databaseInitializationFailed
        }

        let databasePath = baseDir.appendingPathComponent("database.sqlite")

        guard let database = YapDatabase(url: databasePath) else {
            throw YapDatabaseError.databaseInitializationFailed
        }

        return database
    }

    func saveCharacter(_ character: Character, key: String) {
        connection.readWrite { transaction in
            transaction.setObject(character, forKey: key, inCollection: charactersCollection)

            var order = transaction.object(
                forKey: "order",
                inCollection: charactersOrderCollection) as? [String] ?? []
            if !order.contains(key) {
                order.append(key)
                transaction.setObject(order, forKey: "order", inCollection: charactersOrderCollection)
            }
        }
    }

    func saveImage(_ image: Data, key: String) {
        connection.readWrite { transaction in
            transaction.setObject(image, forKey: key, inCollection: imagesCollection)
        }
    }

    func loadCharacter(key: String) -> Character? {
        var character: Character?
        connection.read { transaction in
            character = transaction.object(forKey: key, inCollection: charactersCollection) as? Character
        }
        return character
    }

    func loadAllCharacters() -> [Character] {
        var characters = [Character]()
        connection.read { transaction in
            if let order = transaction.object(forKey: "order", inCollection: charactersOrderCollection) as? [String] {
                for key in order {
                    if let character = transaction.object(
                        forKey: key,
                        inCollection: charactersCollection) as? Character {
                        characters.append(character)
                    }
                }
            }
        }
        return characters
    }

    func loadImage(key: String) -> Data? {
        var result: Data?
        connection.read { transaction in
            if let data = transaction.object(forKey: key, inCollection: imagesCollection) as? Data {
                result = data
            } else {
                result = nil
            }
        }
        return result
    }
}

// MARK: extension DatabaseManager
extension DatabaseManager {
    func clearCharacter(key: String) {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: key, inCollection: charactersCollection)
        }
    }

    func clearAllCharacters() {
        connection.readWrite { transaction in
            transaction.removeAllObjects(inCollection: charactersCollection)
        }
    }

    func clearImage(key: String) {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: key, inCollection: imagesCollection)
        }
    }
}
