//
//  ViewController.swift
//  hackyeah
//
//  Created by Dominik Kapusta on 28/10/2017.
//  Copyright © 2017 Base. All rights reserved.
//

import UIKit

import CoreLocation

class Cell: UICollectionViewCell {
}

class ViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dataSource = self
        collectionView?.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 81, height: 111)
        layout.sectionInset = UIEdgeInsetsMake(100, 50, 50, 50)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        collectionView?.collectionViewLayout = layout
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView?.reloadData()
    }

    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let identifier: String = {
            switch indexPath.row {
            case 0:
                return "bc1"
            case 1:
                return "bc2"
            case 2:
                return "bc3"
            default:
                return ""
            }
        }()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        return cell
    }
}

