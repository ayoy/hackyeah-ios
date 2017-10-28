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

extension BeaconData {
    var cellIdentifier: String {
        if self == .BC1 {
            return "bc1"
        }
        if self == .BC2 {
            return "bc2"
        }
        if self == .BC3 {
            return "bc3"
        }
        return ""
    }
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
        
        BeaconService.shared.beaconsInRangeDidChange = { beacons in
            DispatchQueue.main.async {
                self.beacons = beacons
                self.collectionView?.reloadData()
            }
        }
    }
    
    private var beacons: [BeaconData] = []
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if APIClient.shared.isUserLoggedIn {
            BeaconService.shared.startMonitoringForBeacons()
        } else {
            performSegue(withIdentifier: "showLogin", sender: nil)
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            APIClient.shared.logOut { (success) in
                self.performSegue(withIdentifier: "showLogin", sender: nil)
                BeaconService.shared.stopMonitoringForBeacons()
            }
        }
    }

    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return beacons.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let beacon = beacons[indexPath.row]
        let identifier = beacon.cellIdentifier

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier,
                                                      for: indexPath)
        return cell
    }
}

