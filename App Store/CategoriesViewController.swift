//
//  CategoriesViewController.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit
import CoreData

class CategoriesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    var categories: [NSManagedObject]? = nil
    var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Jale para recargar")
        self.refreshControl.addTarget(self, action: #selector(CategoriesViewController.refresh), forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.refresh()
    }
    
    func refresh()
    {
        if DataManager.sharedManager.isConnectedToNetwork() {
            DataManager.sharedManager.syncData {
                self.categories = DataManager.sharedManager.getCategories()
                if self.categories != nil {
                    self.tableView?.reloadData()
                    self.collectionView?.reloadData()
                }
            }
        } else {
            categories = DataManager.sharedManager.getCategories()
            if categories != nil && categories?.count > 0 {
                self.tableView?.reloadData()
                self.collectionView?.reloadData()
            } else {
                let alert = UIAlertController(title: "Primera vez", message: "Por favor conecte el dispositivo al menos una vez a internet para descargar los datos, y jale para recargar.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        self.refreshControl.endRefreshing()
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
        if segue.identifier == "AppsSegue" {
            if let viewController = segue.destinationViewController as? AppsViewController {
                viewController.category = categories?[tableView.indexPathForSelectedRow!.row]
            }
        }
        
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension CategoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (categories != nil) ? categories!.count : 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell")
        
        let category = categories?[indexPath.row]
        cell?.textLabel?.text = category?.valueForKey("name") as? String
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("AppsSegue", sender: nil)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension CategoriesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (categories != nil) ? categories!.count : 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CategoryCell", forIndexPath: indexPath)
        return cell
    }
}
