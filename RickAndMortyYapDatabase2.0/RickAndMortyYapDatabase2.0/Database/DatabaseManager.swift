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
            connection = database.newConnection()
        } catch {
            fatalError("Failed to initialize YapDatabase with error: \(error)")
        }
    }

    private static func setupDatabase() throws -> YapDatabase {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let baseDir = paths.first ?? NSTemporaryDirectory()
        let databaseName = "database.sqlite"
        let databasePath = (baseDir as NSString).appendingPathComponent(databaseName)
        let databaseUrl = URL(fileURLWithPath: databasePath)

        guard let databaseWithPath = YapDatabase(url: databaseUrl) else {
            throw YapDatabaseError.databaseInitializationFailed
        }

        return databaseWithPath
    }

    func saveCharacter(_ character: Character, key: String) {
        do {
            let data = try JSONEncoder().encode(character)
            connection.readWrite { transaction in
                transaction.setObject(data, forKey: key, inCollection: charactersCollection)

                var order = transaction.object(
                    forKey: "order",
                    inCollection: charactersOrderCollection) as? [String] ?? []
                if !order.contains(key) {
                    order.append(key)
                    transaction.setObject(order, forKey: "order", inCollection: charactersOrderCollection)
                }
            }
        } catch {
            print("Failed to encode character: \(error)")
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
            if let data = transaction.object(forKey: key, inCollection: charactersCollection) as? Data {
                do {
                    character = try JSONDecoder().decode(Character.self, from: data)
                } catch {
                    print("Failed to decode character: \(error)")
                }
            }
        }
        return character
    }

    func loadAllCharacters() -> [Character] {
        var characters = [Character]()
        connection.read { transaction in
            // Загружаем порядок ключей
            if let order = transaction.object(forKey: "order", inCollection: charactersOrderCollection) as? [String] {
                for key in order {
                    if let data = transaction.object(forKey: key, inCollection: charactersCollection) as? Data {
                        do {
                            let character = try JSONDecoder().decode(Character.self, from: data)
                            characters.append(character)
                        } catch {
                            print("Failed to decode character for key \(key): \(error)")
                        }
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
