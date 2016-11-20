//
//  FlickrPhotoViewController.swift
//  FlickrSearch
//
//  Created by Jeff Norton on 11/20/16.
//  Copyright © 2016 JeffCryst. All rights reserved.
//
import UIKit

class FlickrPhotoViewController: UIViewController {
    
    //==================================================
    // MARK: - _Properties
    //==================================================
    
    let cellReuseIdentifier = "resultPhotoCell"
    fileprivate let itemsPerRow: CGFloat = 3
    var largePhotoIndexPath: NSIndexPath? {
        
        didSet {
            var indexPaths = [IndexPath]()
            
            if let largePhotoIndexPath = self.largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath as IndexPath)
            }
            
            if let oldValue = oldValue {
                indexPaths.append(oldValue as IndexPath)
            }
            
            self.resultsCollectionView.performBatchUpdates({
                
                self.resultsCollectionView.reloadItems(at: indexPaths)
                
            }) { (completed) in
                
                if let largePhotoIndexPath = self.largePhotoIndexPath {
                    
                    self.resultsCollectionView.selectItem(at: largePhotoIndexPath as IndexPath, animated: true, scrollPosition: .centeredVertically)
                }
            }
        }
    }
    
    fileprivate let photoController = PhotoController()
    @IBOutlet weak var resultsCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    fileprivate var searches = [PhotoSearchResults]()
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    //==================================================
    // MARK: - General
    //==================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
}

private extension FlickrPhotoViewController {
    
    func photo(forIndexPath indexPath: IndexPath) -> Photo {
        
        return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as NSIndexPath).row]
    }
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotoViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return searches.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
        return searches[section].searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "PhotoHeaderView",
                                                                             for: indexPath) as! PhotoHeaderView
            
            headerView.sectionLabel.text = searches[(indexPath as NSIndexPath).section].searchTerm
            
            return headerView
            
        default:
            
            assert(false, "Unexpected element kind")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier,
                                                      for: indexPath) as! PhotoCollectionViewCell
        
        let currentPhoto = photo(forIndexPath: indexPath)
        
        cell.activityIndicator.stopAnimating()
        
        guard indexPath as NSIndexPath? == largePhotoIndexPath else {
            
            cell.photo = currentPhoto
            
            return cell
        }
        
        guard currentPhoto.largeImage == nil else {
            cell.photoImageView.image = currentPhoto.largeImage
            return cell
        }
        
        cell.photoImageView.image = currentPhoto.thumbnail
        cell.activityIndicator.startAnimating()
        
        currentPhoto.loadLargeImage { (loadedPhoto, error) in
            
            cell.activityIndicator.stopAnimating()
            
            guard loadedPhoto?.largeImage != nil && error == nil else {
                return
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
                , indexPath == self.largePhotoIndexPath as? IndexPath {
                
                cell.photo = loadedPhoto
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FlickrPhotoViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        largePhotoIndexPath = largePhotoIndexPath == indexPath as NSIndexPath? ? nil : indexPath as NSIndexPath?
        
        return false
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlickrPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath as NSIndexPath? == largePhotoIndexPath {
            
            let currentPhoto = photo(forIndexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            
            return currentPhoto.sizeToFillWidths(ofSize: size)
        }
        
        let paddingSpace = sectionInsets.left * (self.itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return sectionInsets.left
    }
}

// MARK: - UISearchBarDelegate
extension FlickrPhotoViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if let searchTerm = searchBar.text, searchTerm.characters.count > 0 {
            
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            searchBar.addSubview(activityIndicator)
            activityIndicator.frame = searchBar.bounds
            activityIndicator.startAnimating()
            
            photoController.searchFlickr(forSearchTerm: searchTerm) { (results, error) in
                
                DispatchQueue.main.async {
                    activityIndicator.removeFromSuperview()
                    
                    if let error = error {
                        NSLog("Error: \(error.localizedDescription)")
                        return
                    }
                    
                    if let results = results {
                        
                        NSLog("Found \(results.searchResults.count) results matching \"\(results.searchTerm)\"")
                        self.searches.insert(results, at: 0)
                        self.resultsCollectionView.reloadData()
                    }
                    
                    //                    self.resultsCollectionView.reloadData()
                }
            }
        }
        
        searchBar.text = nil
    }
}











































