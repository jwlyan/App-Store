//
//  AppsViewController.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit
import CoreData

class AppsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    var category: NSManagedObject? = nil
    var apps: [NSManagedObject]? = nil
    var selectedCellImage: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apps = DataManager.sharedManager.getAppsForCategory(category!)
        if apps != nil {
            self.tableView?.reloadData()
            self.collectionView?.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let row = tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(row, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AppDetailFromTableSegue" {
            if let viewController = segue.destinationViewController as? AppViewController {
                guard let indexPath = tableView.indexPathForSelectedRow else {
                    return
                }
                viewController.app = apps?[indexPath.row]
                selectedCellImage = tableView.cellForRowAtIndexPath(indexPath)?.imageView
                
                //viewController.transitioningDelegate = self
            }
        }
        
        if segue.identifier == "AppDetailFromCollectionSegue" {
            let viewController = segue.destinationViewController as! AppViewController
            let cell = sender as! AppsCollectionViewCell
            selectedCellImage = cell.imageView
            let indexPath = collectionView!.indexPathForCell(cell)
            viewController.app = apps?[indexPath!.row]
            //viewController.transitioningDelegate = self
        }
    }
    
    func imageForIndexPath(indexPath: NSIndexPath) -> UIImage? {
        let app = apps?[indexPath.row]
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let imageDirectory = documentsDirectory + "/Images"
        var imagePath = imageDirectory + "/\(app?.valueForKey("name") as! String).png"
        
        var imageURL = NSURL(fileURLWithPath: imagePath)
        if !NSFileManager.defaultManager().fileExistsAtPath(imagePath) {
            let image = app?.valueForKey("image") as? NSManagedObject
            imagePath = image?.valueForKey("url") as! String
            imageURL = NSURL(string: imagePath)!
        }
        let imageData = NSData(contentsOfURL: imageURL)
        return UIImage(data: imageData!)
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AppsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (apps != nil) ? apps!.count : 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AppCell")
        
        let app = apps?[indexPath.row]
        cell?.textLabel?.text = app?.valueForKey("name") as? String
        cell?.detailTextLabel?.text = app?.valueForKey("artist") as? String
        cell?.imageView?.image = imageForIndexPath(indexPath)
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("AppDetailFromTableSegue", sender: nil)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension AppsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (apps != nil) ? apps!.count : 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AppsCell", forIndexPath: indexPath) as! AppsCollectionViewCell
        
        let app = apps?[indexPath.row]
        cell.name.text = app?.valueForKey("name") as? String
        cell.artist.text = app?.valueForKey("artist") as? String
        cell.imageView.image = imageForIndexPath(indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("AppDetailFromCollectionSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
    }
}

// MARK: - UIViewControllerTransitioningDelegate
/*
extension AppsViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
                             sourceController source: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
            
            return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}*/

