//
//  PhotoCollectionViewCell.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    func configureWith(_ location: VisitedLocation) {
        imageView.image = location.image
        titleLabel.text = location.photo.title
    }
    
}
