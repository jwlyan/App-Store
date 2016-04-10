//
//  DataManager.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON
import SystemConfiguration

/*struct AppCategory {
 let id: Int
 let name: String
 }
 
 extension AppCategory: Equatable {}
 
 func ==(lhs: AppCategory, rhs: AppCategory) -> Bool {
 let areEqual = lhs.id == rhs.id &&
 lhs.name == rhs.name
 
 return areEqual
 }
 
 struct App {
 let name: String
 let urlImage: NSURL
 let category: AppCategory
 }*/

class DataManager {
    static let sharedManager = DataManager()
    let urlString = "https://itunes.apple.com/us/rss/topfreeapplications/limit=20/json"
    
    func getCategories() -> [NSManagedObject]? {
        let fetchCategoriesRequest = NSFetchRequest(entityName: "Category")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchCategoriesRequest.sortDescriptors = [sortDescriptor]
        
        //In this case categories are loaded fully, usually pagination or a better approach is needed.
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchCategoriesRequest)
            return results as? [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func getAppsForCategory(category: NSManagedObject) -> [NSManagedObject]? {
        if let apps = category.valueForKey("apps") as? NSSet {
            return apps.allObjects as? [NSManagedObject]
        }
        return nil
    }
    
    
    
    var localImages: [String: String]? = nil
    
    private init() {
        /*NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: nil, queue: nil) { notification in
            if let updated = notification.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
                print("updated: \(updated)")
            }
            
            if let deleted = notification.userInfo?[NSDeletedObjectsKey] where deleted.count > 0 {
                print("deleted: \(deleted)")
            }
            
            if let inserted = notification.userInfo?[NSInsertedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
        }*/
    }
    
    deinit {
        //NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func syncData(completion: (() -> ())?) {
        
        Alamofire.request(.GET, urlString).responseJSON { response in
            guard response.result.error == nil else {
                print("Error calling service")
                print(response.result.error!)
                return
            }
            
            if let value: AnyObject = response.result.value {
                let info = JSON(value)
                
                //Load local images
                if self.localImages == nil {
                    self.localImages = [String: String]()
                    let fetchImagesRequest = NSFetchRequest(entityName: "Image")
                    
                    do {
                        let results = try self.managedObjectContext.executeFetchRequest(fetchImagesRequest)
                        let images = results as! [NSManagedObject]
                        for image in images {
                            self.localImages![image.valueForKey("id") as! String] = (image.valueForKey("url") as! String)
                        }
                        
                    } catch let error as NSError {
                        print("Could not fetch \(error), \(error.userInfo)")
                    }
                }
                
                
                //In this case because of the small data and no need to sync local changes it's fine to delete all first.
                self.deleteAllData("Image")
                self.deleteAllData("Category")
                self.deleteAllData("App")
                
                var serverImages = [String: String]()

                for appInfo in info["feed"]["entry"].arrayValue {
                    
                    let categoryID = appInfo["category"]["attributes"]["im:id"].intValue
                    
                    let fetchRequest = NSFetchRequest(entityName: "Category")
                    let predicate = NSPredicate(format: "id == \(categoryID)")
                    fetchRequest.predicate = predicate
                    
                    var category: NSManagedObject? = nil
                    do {
                        let results = try self.managedObjectContext.executeFetchRequest(fetchRequest)
                        let fetchedCategories = results as! [NSManagedObject]
                        if fetchedCategories.count > 0 {
                            category = fetchedCategories[0]
                        }
                    } catch let error as NSError {
                        print("Could not fetch \(error), \(error.userInfo)")
                        return
                    }
                    
                    if category == nil {
                        let categoryEntity = NSEntityDescription.entityForName("Category",
                            inManagedObjectContext: self.managedObjectContext)
                        category = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: self.managedObjectContext)
                        category!.setValue(categoryID, forKey:"id")
                        category!.setValue(appInfo["category"]["attributes"]["label"].stringValue, forKey: "name")
                    }
                    
                    let appEntity = NSEntityDescription.entityForName("App", inManagedObjectContext: self.managedObjectContext)
                    let app = NSManagedObject(entity: appEntity!, insertIntoManagedObjectContext: self.managedObjectContext)
                    let name = appInfo["im:name"]["label"].stringValue
                    app.setValue(name, forKey: "name")
                    app.setValue(appInfo["im:artist"]["label"].stringValue, forKey: "artist")
                    app.setValue(appInfo["summary"]["label"].stringValue, forKey: "summary")
                    app.setValue(category!, forKey: "category")
                    
                    category!.mutableSetValueForKey("apps").addObject(app)
                    
                    
                    let imageEntity = NSEntityDescription.entityForName("Image",
                        inManagedObjectContext: self.managedObjectContext)
                    let image = NSManagedObject(entity: imageEntity!, insertIntoManagedObjectContext: self.managedObjectContext)
                    image.setValue(name, forKey:"id")
                    image.setValue(appInfo["im:image"][2]["label"].stringValue, forKey: "url")
                    image.setValue(app, forKey: "app")
                    
                    app.setValue(image, forKey: "image")
                    
                    //There is not need to create an image id because app names are unique.
                    serverImages[name] = appInfo["im:image"][2]["label"].stringValue
                }
                
                self.syncImages(serverImages)
                
                
                
                do {
                    try self.managedObjectContext.save()
                } catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                    return
                }
                
                //self.loadData {
                completion?()
                //}
                
                
                
                /*var categories = [AppCategory]()
                 var apps = [App]()
                 for appInfo in info["feed"]["entry"].arrayValue {
                 
                 let category = AppCategory(
                 id: appInfo["category"]["attributes"]["im:id"].intValue,
                 name: appInfo["category"]["attributes"]["label"].stringValue)
                 
                 if !categories.contains(category) {
                 categories.append(category)
                 }
                 
                 let app = App(name: appInfo[0]["im:name"]["label"].stringValue,
                 urlImage: NSURL(fileURLWithPath: appInfo[0]["im:image"][0]["label"].stringValue),
                 category: category)
                 apps.append(app)
                 }
                 print(categories)
                 //print(apps)*/
                
                
                
                
                
            }
        }

    }
    
    /*func loadData(completion: (() ->())?) {
        let fetchCategoriesRequest = NSFetchRequest(entityName: "Category")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchCategoriesRequest.sortDescriptors = [sortDescriptor]
        
        //In this case categories are loaded fully, usually pagination or a better approach is needed.
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchCategoriesRequest)
            self.categories = results as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            completion?()
            return
        }
        
        
        let fetchAppsRequest = NSFetchRequest(entityName: "App")
        fetchAppsRequest.sortDescriptors = [sortDescriptor]
        
        //In this case apps are loaded fully, usually pagination or a better approach is needed.
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchAppsRequest)
            self.apps = results as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            completion?()
            return
        }
        
        completion?()

    }*/
    
    func deleteAllData(entity: String)
    {
        let fetchRequest = NSFetchRequest(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedObjectContext.executeFetchRequest(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedObjectContext.deleteObject(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error: \(error) \(error.userInfo)")
        }
    }
    
    func syncImages(newImages: [String: String]) {
        
        //Get what images files need to be saved and removed. What remains in self.localImages are to be removed.
        let imagesToSave = newImages.filter { (key, value) -> Bool in
            if let localValue = self.localImages![key] where localValue == value {
                self.localImages!.removeValueForKey(key)
                return false
            }
            return true
        }
        
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let imageDirectory = documentsDirectory + "/Images"
        
        //Create Images directory in Documents/
        if !NSFileManager.defaultManager().fileExistsAtPath(imageDirectory) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(imageDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print("Could not create Images directory with error: \(error.localizedDescription)");
                return
            }
        }
        
        for (key, _) in self.localImages! {
            let imagePath = imageDirectory + "/\(key).png"
            if NSFileManager.defaultManager().fileExistsAtPath(imagePath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(imagePath)
                } catch let error as NSError {
                    print("Could not delete file, \(error.userInfo)")
                    return
                }
            }
        }
        self.localImages = newImages
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            for (key, value) in imagesToSave {
                let imagePath = imageDirectory + "/\(key).png"
                let urlImage = NSURL(string: value)
                let imageData = NSData(contentsOfURL: urlImage!)
                let image = UIImage(data: imageData!)
                UIImageJPEGRepresentation(image!, 1.0)?.writeToFile(imagePath, atomically: true)
            }
        }
    }
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.grability.PruebaCoreData" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("App-Store", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}