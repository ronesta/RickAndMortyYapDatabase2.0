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

    private let charactersKey = "charactersKey"
    private let charactersCollection = "characters"
    private let imagesCollection = "images"
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

    func saveCharacters(_ characters: [Character]) {
        do {
            let data = try JSONEncoder().encode(characters)
            connection.readWrite { transaction in
                transaction.setObject(data, forKey: charactersKey, inCollection: charactersCollection)
            }
        } catch {
            print("Failed to encode characters: \(error)")
        }
    }

    func saveImage(_ image: Data, key: String) {
        connection.readWrite { transaction in
            transaction.setObject(image, forKey: key, inCollection: imagesCollection)
        }
    }

    func loadCharacters(completion: @escaping ([Character]?) -> Void) {
        connection.read { transaction in
            if let data = transaction.object(forKey: charactersKey, inCollection: charactersCollection) as? Data {
                do {
                    let characters = try JSONDecoder().decode([Character].self, from: data)
                    completion(characters)
                } catch {
                    print("Failed to decode characters: \(error)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    func loadImage(key: String, completion: @escaping (Data?) -> Void) {
        connection.read { transaction in
            if let data = transaction.object(forKey: key, inCollection: imagesCollection) as? Data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }

    func clearCharacters() {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: charactersKey, inCollection: charactersCollection)
        }
    }

    func clearImage(key: String) {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: key, inCollection: imagesCollection)
        }
    }
}

// MARK: extension DatabaseManager
extension DatabaseManager {
    func saveCharacter(_ character: Character) {
        do {
            let data = try JSONEncoder().encode(character)
            connection.readWrite { transaction in
                transaction.setObject(data, forKey: String(character.id), inCollection: charactersCollection)
            }
        } catch {
            print("Failed to encode character: \(error)")
        }
    }

    func loadCharacter(by id: String) -> Character? {
        var character: Character?
        connection.read { transaction in
            if let data = transaction.object(forKey: id, inCollection: charactersCollection) as? Data {
                do {
                    character = try JSONDecoder().decode(Character.self, from: data)
                } catch {
                    print("Failed to decode character: \(error)")
                }
            }
        }
        return character
    }

    func clearCharacter(by id: String) {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: id, inCollection: charactersCollection)
        }
    }
}
