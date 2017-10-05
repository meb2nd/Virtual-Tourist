//
//  PhotoAlbumViewController.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    // MARK: Properties
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            photoCollectionView.reloadData()
        }
    }
    
    private let reuseIdentifier = "PhotoViewCell"
    var pin: Pin!
    
    @IBOutlet weak var photoCollectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    // MARK: Initializers
    
    init?(fetchedResultsController fc : NSFetchedResultsController<NSFetchRequestResult>, coder : NSCoder) {
        fetchedResultsController = fc
        super.init(coder: coder)
    }
    
    // Do not worry about this initializer. It has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        photoCollectionView.dataSource = self
        setupLayout()
    }

    // MARK:  Layout handling
    
    func setupLayout() {
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        photoCollectionViewFlowLayout.minimumInteritemSpacing = space
        photoCollectionViewFlowLayout.minimumLineSpacing = space
        photoCollectionViewFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange(previousTraitCollection)
        
        if ((self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass)
            || (self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass)) {
            
            setupLayout()
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */

}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        // Get the photo
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        let imageData: Data = photo.imageData! as Data
        cell.photoImageView.image = UIImage(data: imageData)
        
       return cell
    }

}

// MARK: - PhotoAlbumViewController (Fetches)

extension PhotoAlbumViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK: - PhotoAlbumViewController: NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // photoCollectionView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            photoCollectionView.insertSections(set)
        case .delete:
            photoCollectionView.deleteSections(set)
        default:
            // irrelevant in our case
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            photoCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photoCollectionView.deleteItems(at: [indexPath!])
        case .update:
            photoCollectionView.reloadItems(at: [indexPath!])
        case .move:
            photoCollectionView.deleteItems(at: [indexPath!])
            photoCollectionView.insertItems(at: [newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // photoCollectionView.endUpdates()
    }
}
