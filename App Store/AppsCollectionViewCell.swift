//
//  AppsCollectionViewCell.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit

class AppsCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var artist: UILabel!
    
    override func awakeFromNib() {
        contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }
}
