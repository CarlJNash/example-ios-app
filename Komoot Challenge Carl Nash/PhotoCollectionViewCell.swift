//
//  PhotoCollectionViewCell.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func configureWith(image: UIImage) {
        imageView.image = image
    }
    
}
