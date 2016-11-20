//
//  PhotoController.swift
//  FlickrSearch
//
//  Created by Jeff Norton on 11/20/16.
//  Copyright © 2016 JeffCryst. All rights reserved.
//

import UIKit

class PhotoController {
    
    //==================================================
    // MARK: - _Properties
    //==================================================
    
    let apiKey = "3d9428f4ec04aa56ff264ce4daa08a4e"
    let flickrSearchURL = URL(string: "https://api.flickr.com/services/rest/")
    let processingQueue = OperationQueue()
    let resultsPerPage = 25
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func searchFlickr(forSearchTerm searchTerm: String, completion: @escaping (_ results: PhotoSearchResults?, _ error: NSError?) -> Void) {
        
        guard let flickrSearchURL = flickrSearchURL else {
            
            NSLog("Error unwrapping the Flickr Search URL.")
            completion(nil, nil)
            return
        }
        
        let urlParameters: [String: String] = ["method": "flickr.photos.search", "api_key": apiKey, "text": searchTerm, "per_page": String(resultsPerPage), "format": "json", "nojsoncallback": "1"]
        
        NetworkController.performRequest(for: flickrSearchURL, httpMethod: .Get, urlParameters: urlParameters) { (data, error) in
            
            if let _ = error {
                
                let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Unknown API response."])
                OperationQueue.main.addOperation ({
                    completion(nil, apiError)
                })
                
                return
            }
            
            guard let data = data else {
                
                let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Unknown API response."])
                OperationQueue.main.addOperation ({
                    completion(nil, apiError)
                })
                
                return
            }
            
            do {
                
                guard let resultsDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject]
                    , let stat = resultsDictionary["stat"] as? String else {
                        
                        let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Unknown API response."])
                        OperationQueue.main.addOperation ({
                            completion(nil, apiError)
                        })
                        
                        return
                }
                
                switch stat {
                case "ok":
                    
                    NSLog("Reulsts processed OK.")
                    
                case "fail":
                    
                    if let message = resultsDictionary["message"] {
                        
                        let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: message])
                        OperationQueue.main.addOperation ({
                            completion(nil, apiError)
                        })
                        
                        return
                    }
                    
                    let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: nil)
                    OperationQueue.main.addOperation ({
                        completion(nil, apiError)
                    })
                    
                    return
                
                default:
                    
                    let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Unknown API response."])
                    OperationQueue.main.addOperation ({
                        completion(nil, apiError)
                    })
                    
                    return
            }
                
                guard let photosContainer = resultsDictionary["photos"] as? [String: AnyObject]
                    , let photosReceived = photosContainer["photo"] as? [[String: AnyObject]] else {
                        
                        let apiError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Unknown API response."])
                        OperationQueue.main.addOperation ({
                            completion(nil, apiError)
                        })
                        
                        return   
                }
                
            var photos = [Photo]()
                
                for currentPhoto in photosReceived {
                    
                    guard let farm = currentPhoto["farm"] as? Int
                        , let photoID = currentPhoto["id"] as? String
                        , let secret = currentPhoto["secret"] as? String
                        , let server = currentPhoto["server"] as? String
                        , let title = currentPhoto["title"] as? String else {
                            
                            break
                    }
                    
                    let photo = Photo(farm: farm, photoID: photoID, secret: secret, server: server, title: title)
                    
                    if let url = photo.imageURL()
                        , let imageData = try? Data(contentsOf: url as URL)
                        , let image = UIImage(data: imageData) {
                        
                        photo.thumbnail = image
                        
                    } else {
                        
                        photo.thumbnail = UIImage(named: "photo-unavailable")
                    }
                    
                    photos.append(photo)
                }
                
                OperationQueue.main.addOperation ({
                    completion(PhotoSearchResults(searchTerm: searchTerm, searchResults: photos), nil)
                })
                
            } catch {
                
                NSLog("Error: \(error)")
                completion(nil, nil)
                return
            }
        }
    }
}




























