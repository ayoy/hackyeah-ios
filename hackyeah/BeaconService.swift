//
//  BeaconService.swift
//  hackyeah
//
//  Created by Dominik Kapusta on 28/10/2017.
//  Copyright © 2017 Base. All rights reserved.
//

import UIKit
import CoreLocation

struct BeaconData: Hashable, Equatable {
    let proximityUUID: UUID
    let major: NSNumber
    let minor: NSNumber
    
    static let BC1 = BeaconData(proximityUUID: BeaconService.beaconUUID, major: 27533, minor: 34855)
    static let BC2 = BeaconData(proximityUUID: BeaconService.beaconUUID, major: 53282, minor: 21623)
    static let BC3 = BeaconData(proximityUUID: BeaconService.beaconUUID, major: 35794, minor: 15677)

    static let knownBeacons: [BeaconData] = [.BC1, .BC2, .BC3]

    init(proximityUUID: UUID, major: NSNumber, minor: NSNumber) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
    }
    
    init(beacon: CLBeacon) {
        self.init(proximityUUID: beacon.proximityUUID, major: beacon.major, minor: beacon.minor)
    }
    
    var hashValue: Int {
        return proximityUUID.hashValue ^ major.hashValue ^ minor.hashValue
    }
    
    static func ==(lhs: BeaconData, rhs: BeaconData) -> Bool {
        return lhs.proximityUUID == rhs.proximityUUID && lhs.major == rhs.major && lhs.minor == rhs.minor
    }
}

class BeaconService: NSObject, CLLocationManagerDelegate {
    
    static let beaconUUID: UUID = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    
    static let shared = BeaconService()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()
    
    var isLocationServicesAuthorized: Bool {
        return CLLocationManager.authorizationStatus() != .denied
    }
    
    private(set) var isMonitoringForBeacons: Bool = false
    
    func startMonitoringForBeacons() {
        NSLog("startMonitoringForBeacons")
        if !isMonitoringForBeacons {
            locationManager.requestAlwaysAuthorization()
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startMonitoring(for: beaconRegion)
            isMonitoringForBeacons = true
            NSLog("Started monitoring for beacons")
        }
    }
    
    func stopMonitoringForBeacons() {
        NSLog("stopMonitoringForBeacons")
        if isMonitoringForBeacons {
            locationManager.stopMonitoringSignificantLocationChanges()
            locationManager.stopRangingBeacons(in: beaconRegion)
            locationManager.stopMonitoring(for: beaconRegion)
            isMonitoringForBeacons = false
            NSLog("Stopped monitoring for beacons")
        }
    }
    
    let beaconRegionIdentifier = "beaconRegionIdentifier"
    
    lazy var beaconRegion: CLBeaconRegion = {
        let uuid =  UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let region = CLBeaconRegion(proximityUUID: uuid, identifier: beaconRegionIdentifier)
        region.notifyEntryStateOnDisplay = true
        return region
    }()
    
    private var beaconsInRange: Set<BeaconData> = []
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print(#function)
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            manager.startRangingBeacons(in: beaconRegion)
            NSLog("Now ranging beacons with UUID: \(BeaconService.beaconUUID)")
        default:
            manager.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print(#function)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
//        print(#function)
        let newBeaconsInRange: [BeaconData] = beacons.flatMap { beacon in
            let beaconData = BeaconData(beacon: beacon)
            if !beaconsInRange.contains(beaconData) {
                NSLog("found new beacon, major: \(beacon.major), minor: \(beacon.minor)")
                return beaconData
            }
            return nil
        }
        beaconsInRange.formUnion(newBeaconsInRange)
    }
}
