//
//  AppViewController.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit
import CoreData

class AppViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet var summary: UITextView!

    var app: NSManagedObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        imageView.image = UIImage(data: imageData!)
        
        name.text = app?.valueForKey("name") as? String
        artist.text = app?.valueForKey("artist") as? String
        summary.text = app?.valueForKey("summary") as? String
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
