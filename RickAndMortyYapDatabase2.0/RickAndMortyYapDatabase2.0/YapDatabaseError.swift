//
//  YapDatabaseError.swift
//  RickAndMortyYapDatabase2.0
//
//  Created by Ибрагим Габибли on 10.11.2024.
//

import Foundation

enum YapDatabaseError: Error {
    case databaseInitializationFailed
    case encodingFailed(Error)
    case decodingFailed(Error)
}
