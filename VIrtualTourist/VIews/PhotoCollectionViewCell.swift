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
    
    // MARK: - Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
            self.alpha = isSelected ? 0.5 : 1.0
        }
    }
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        update(with: nil)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        update(with: nil)
    }

    // MARK: - Cell Update
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
