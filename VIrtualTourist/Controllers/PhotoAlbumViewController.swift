//
//  PhotoAlbumViewController.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, PhotoStoreClient {
    
    // MARK: Properties
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the collection
            fetchedResultsController?.delegate = self
            executeSearch()
            photoCollectionView.reloadData()
        }
    }
    
    var store: PhotoStore!
    private var batchUpdateOperation = [BlockOperation]()
    private let reuseIdentifier = "PhotoCollectionViewCell"
    var pin: Pin?
    
    // MARK: Outlets
    
    @IBOutlet weak var photoAlbumMapView: MKMapView!
    @IBOutlet weak var photoCollectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        //photoCollectionView.delegate = self
        setupLayout()
        
        guard let pin = pin else {
           
            AlertViewHelper.presentAlert(self, title: "Location Error", message: "Missing location information.  Cannot load images.")
            return
        }
        
        loadData(pin)
    }
    
    fileprivate func enableUI(_ isEnabled: Bool) {
        newCollectionButton.isEnabled = isEnabled
        isEnabled ? activityIndicator.stopAnimating(): activityIndicator.startAnimating()
    }
    
    fileprivate func loadData(_ pin: Pin) {
        if let fc = fetchedResultsController, let count = fc.sections?.count, count == 0 {
            
            enableUI(false)
            
            store.fetchPhotos(for: pin, context: fc.managedObjectContext) { (photoResult) in
                
                if case PhotosResult.failure = photoResult {
                    AlertViewHelper.presentAlert(self, title: "Flickr Photo Error", message: "Could not retrieve photos for this location.")
                }
                
                self.enableUI(true)
            }
        }
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
    
    
    @IBAction func getNewCollection(_ sender: Any) {
        
        // Posible change create a temp array for the photos to delete and then delete after successful fetch
        if let photos = fetchedResultsController?.fetchedObjects {
            for photo in photos {
                fetchedResultsController?.managedObjectContext.delete(photo as! NSManagedObject)
            }
        }
        
        loadData(pin!)
    }
    
    deinit {
        for operation in batchUpdateOperation {
            operation.cancel()
        }
        batchUpdateOperation.removeAll()
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
/*
extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    // Code for this method based on information in: iOS Programming: The Big Nerd Ranch Guide (Big Nerd Ranch Guides) 6th Edition, Kindle Edition
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        // Download the image data, which could take some time
        store.fetchImage(for: photo) { (result) -> Void in
            // The index path for the photo might have changed between the
            // time the request started and finished, so find the most
            // recent index path

            guard let photoIndexPath = self.fetchedResultsController?.indexPath(forObject: photo),
                case let .success(image) = result else {
                    return
            }
            
            // When the request finishes, only update the cell if it's still visible
            if let cell = collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(with: image)
            }
        }
    }
}
 
 */

// MARK: - PhotoAlbumViewController: UICollectionViewDataSource
extension PhotoAlbumViewController: UICollectionViewDataSource {
   
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
        
        let imageResult = store.fetchImage(for: photo, context:  (fetchedResultsController?.managedObjectContext)!)
        
        switch imageResult {
        case .success(let image):
            cell.update(with: image)
        case .downloading:
            cell.update(with: nil)
        case .failure(let error):
            print(error)
            cell.update(with: UIImage(named: "No-Image-Found"))
        }
        
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
// Code for this extension based on information found at: http://swiftexample.info/snippet/uicollectionview-nsfetchedresultscontrollerswift_nor0x_swift

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    private func addUpdateBlock(processingBlock:@escaping ()->Void) {
        batchUpdateOperation.append(BlockOperation(block: processingBlock))
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Change UI to show something is happening
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            addUpdateBlock {self.photoCollectionView.insertSections(set)}
        case .delete:
            addUpdateBlock {self.photoCollectionView.deleteSections(set)}
        default:
            // irrelevant in our case
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            addUpdateBlock {self.photoCollectionView.insertItems(at: [newIndexPath!])}
        case .delete:
            addUpdateBlock {self.photoCollectionView.deleteItems(at: [indexPath!])}
        case .update:
            addUpdateBlock {self.photoCollectionView.reloadItems(at: [indexPath!])}
        case .move:
            addUpdateBlock {self.photoCollectionView.deleteItems(at: [indexPath!])}
            addUpdateBlock {self.photoCollectionView.insertItems(at: [newIndexPath!])}
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        photoCollectionView.performBatchUpdates({ () -> Void in
            for operation in self.batchUpdateOperation {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.batchUpdateOperation.removeAll(keepingCapacity: false)
        })
    }
}
