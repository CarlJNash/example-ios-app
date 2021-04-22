//
//  PhotoListViewController.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 21/04/2021.
//

import UIKit

protocol PhotoListView: AnyObject {
    func reloadImageList()
}

class PhotoListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var presenter: PhotoListPresenter = {
        PhotoListPresenter(view: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startButtonTapped))
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    @objc private func startButtonTapped() {
        let currentTitle = navigationItem.rightBarButtonItem!.title
        navigationItem.rightBarButtonItem?.title = currentTitle == "Stop" ? "Start" : "Stop"
        presenter.startButtonTapped()
    }
    
}

extension PhotoListViewController: PhotoListView {
    
    func reloadImageList() {
        collectionView.reloadData()
    }
    
}

extension PhotoListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        presenter.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: PhotoCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
            fatalError()
        }
        
        let image = presenter.image(for: indexPath)
        cell.configureWith(image: image)
        return cell
    }
    
}

extension PhotoListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate the cell size based on the image to display and the collection view width
        let imageSize = presenter.visitedLocations[indexPath.item].image.image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let cellWidth = collectionView.contentSize.width
        let cellHeight = cellWidth / imageAspectRatio
        let newSize = CGSize(width: cellWidth, height: cellHeight)
        return newSize
    }
    
}
