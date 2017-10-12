//
//  PhotoCollectionViewCell.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Code for this class based on information in: iOS Programming: The Big Nerd Ranch Guide (Big Nerd Ranch Guides) 6th Edition, Kindle Edition

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        update(with: nil)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        update(with: nil)
    } */
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
            self.alpha = isSelected ? 0.5 : 1.0
        }
    }
    
    func update(with image: UIImage?) {
        if let imageToDisplay = image {
            activityIndicator.stopAnimating()
            photoImageView.image = imageToDisplay
        } else {
            activityIndicator.startAnimating()
            photoImageView.image = nil
        }
    }
    
}
