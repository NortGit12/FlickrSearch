//
//  PhotoCollectionViewCell.swift
//  FlickrSearch
//
//  Created by Jeff Norton on 11/20/16.
//  Copyright © 2016 JeffCryst. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    //==================================================
    // MARK: - _Properties
    //==================================================
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override var isSelected: Bool {
        didSet {
            photoImageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    var photo: Photo? {
        didSet{
            updateViews()
        }
    }
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    //==================================================
    // MARK: - General
    //==================================================
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        photoImageView.layer.borderColor = UIColor.blue.cgColor
        isSelected = false
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func updateViews() {
        
        photoImageView.image = photo?.thumbnail
        titleLabel.text = photo?.title
    }
    
}
