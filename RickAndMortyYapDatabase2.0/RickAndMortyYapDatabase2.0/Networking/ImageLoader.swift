//
//  ImageLoader.swift
//  RickAndMortyYapDatabase2.0
//
//  Created by Ибрагим Габибли on 08.11.2024.
//

import Foundation
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private init() {}
    var counter = 1

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let imageData = DatabaseManager.shared.loadImage(key: urlString),
           let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                completion(image)
            }
        } else {
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error {
                    print("Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                if let data,
                   let image = UIImage(data: data) {
                    DatabaseManager.shared.saveImage(data, key: urlString)
                    DispatchQueue.main.async {
                        completion(image)
                    }
                    print("Load image", self.counter)
                    self.counter += 1
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
        }
    }
}
