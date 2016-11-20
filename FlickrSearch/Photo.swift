//
//  Photo.swift
//  FlickrSearch
//
//  Created by Jeff Norton on 11/20/16.
//  Copyright © 2016 JeffCryst. All rights reserved.
//

import UIKit

class Photo {
    
    //==================================================
    // MARK: - _Properties
    //==================================================
    
    let farm: Int
    var largeImage: UIImage?
    let photoID: String
    let secret: String
    let server: String
    var thumbnail: UIImage?
    let title: String
    
    //==================================================
    // MARK: - Initializers
    //==================================================
    
    init(farm: Int, photoID: String, secret: String, server: String, title: String) {
        
        self.farm = farm
        self.photoID = photoID
        self.secret = secret
        self.server = server
        self.title = title
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func imageURL(ofSize size: String = "m") -> URL? {
        
        if let url = URL(string: "https://farm\(self.farm).staticflickr.com/\(server)/\(self.photoID)_\(secret)_\(size).jpg") {
            return url
        }
        
        return nil
    }
    
    func loadLargeImage(_ completion: @escaping (_ photo: Photo?, _ error: NSError?) -> Void) {
        
        guard let loadURL = imageURL(ofSize: "b") else {
            
            NSLog("Error: Problem building the URL wth a size of \"b\".")
            DispatchQueue.main.async {
                completion(self, nil)
            }
            return
        }
        
        NetworkController.performRequest(for: loadURL, httpMethod: .Get) { (data, error) in
            
            if let error = error {
                NSLog("Error: \(error.localizedDescription)")
                completion(nil, error as NSError?)
            }
            
            guard let data = data else {
                
                NSLog("Error: Problem unwrapping the data.")
                DispatchQueue.main.async {
                    completion(self, nil)
                }
                return
            }
            
            let image = UIImage(data: data)
            self.largeImage = image
            
            DispatchQueue.main.async {
                completion(self, nil)
            }
        }
    }
    
    func sizeToFillWidths(ofSize size: CGSize) -> CGSize {
        
        guard let thumbnail = self.thumbnail else {
            return size
        }
        
        let imageSize = thumbnail.size
        var returnSize = size
        
        let aspectRatio = imageSize.width / imageSize.height
        returnSize.height = returnSize.width / aspectRatio
        
        if returnSize.height > size.height {
            
            returnSize.height = size.height
            returnSize.width = size.height * aspectRatio
        }
        
        return returnSize
    }
}

func == (lhs: Photo, rhs: Photo) -> Bool {
    
    return lhs.photoID == rhs.photoID
}



























