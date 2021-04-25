//
//  PhotoListViewController.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 21/04/2021.
//

import UIKit

/// This is the view for allowing the user to start/stop their trip and for displaying a list of photos based on their route.
/// As the user moves their GPS location is tracked, with updates every 100 metres. Once a new location is received the app calls the Flickr Photos Search API and passes in this location to search for photos taken within 5km. A photo is then downloaded and displayed in this view, with the latest image at the top of the list.
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
        presenter.startButtonTapped()
        updateStartButtonTitle()
    }
    
    func updateStartButtonTitle() {
        navigationItem.rightBarButtonItem?.title = presenter.startButtonTitle
    }
    
}

extension PhotoListViewController: PhotoListView {
    
    func reloadUI() {
        collectionView.reloadData()
        updateStartButtonTitle()
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
