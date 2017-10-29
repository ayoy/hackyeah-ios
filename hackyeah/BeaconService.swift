//
//  BeaconService.swift
//  hackyeah
//
//  Created by Dominik Kapusta on 28/10/2017.
//  Copyright © 2017 Base. All rights reserved.
//

import UIKit
import CoreLocation
import AudioToolbox

struct BeaconData: Hashable, Equatable {
    let identifier: String
    private var _timestamp: Date? = nil
    var timestamp: Date {
        get {
            return _timestamp ?? Date()
        }
        set {
            _timestamp = newValue
        }
    }
    
    mutating func updateTimestamp(_ timestamp: Date) {
        self.timestamp = timestamp
    }
    
    static let BC1 = BeaconData(identifier: "7ff1752bc73be3237a6fdc8b4b15c02a")
    static let BC2 = BeaconData(identifier: "de7f8aa2183f82116423bcb664df7a21")
    static let BC3 = BeaconData(identifier: "ef99356ca428da700526f00ba8be7e1f")

    static let knownBeacons: Set<BeaconData> = [.BC1, .BC2, .BC3]

    private init(identifier: String, timestamp: Date? = nil) {
        self.identifier = identifier
        _timestamp = timestamp
    }
    
    static func beaconWithIdentifier(_ identifier: String) -> BeaconData? {
        switch identifier {
        case BeaconData.BC1.identifier:
            return .BC1
        case BeaconData.BC2.identifier:
            return .BC2
        case BeaconData.BC3.identifier:
            return .BC3
        default:
            return nil
        }
    }
    
    var isKnown: Bool {
        return BeaconData.knownBeacons.contains(self)
    }
    
    var hashValue: Int {
        return identifier.hashValue
    }
    
    static func ==(lhs: BeaconData, rhs: BeaconData) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

class BeaconService: NSObject, CLLocationManagerDelegate, ESTMonitoringV2ManagerDelegate {
    
    static let shared = BeaconService()
    
    var beaconsInRangeDidChange: (([BeaconData]) -> Void)? = nil

    private lazy var monitoringManagers: [ESTMonitoringV2Manager] = {
        var managers: [ESTMonitoringV2Manager] = [ESTMonitoringV2Manager(desiredMeanTriggerDistance: 2, delegate: self),
                                                  ESTMonitoringV2Manager(desiredMeanTriggerDistance: 2, delegate: self),
                                                  ESTMonitoringV2Manager(desiredMeanTriggerDistance: 2, delegate: self)]
        return managers
    }()

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()
    
    var isLocationServicesAuthorized: Bool {
        return CLLocationManager.authorizationStatus() != .denied
    }
    
    private(set) var isMonitoringForBeacons: Bool = false
    private var beaconsInRange: Set<BeaconData> = []
    private var lastKnownLocation: CLLocation? = nil

    func startMonitoringForBeacons() {
        NSLog("startMonitoringForBeacons")
        if !isMonitoringForBeacons {
            monitoringManagers[0].startMonitoring(forIdentifiers: [BeaconData.BC1.identifier])
            monitoringManagers[1].startMonitoring(forIdentifiers: [BeaconData.BC2.identifier])
            monitoringManagers[2].startMonitoring(forIdentifiers: [BeaconData.BC3.identifier])

            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            isMonitoringForBeacons = true
            NSLog("Started monitoring for beacons")
        }
    }
    
    func stopMonitoringForBeacons() {
        NSLog("stopMonitoringForBeacons")
        if isMonitoringForBeacons {
            monitoringManagers.forEach { $0.stopMonitoring() }

            locationManager.stopUpdatingLocation()
            isMonitoringForBeacons = false
            NSLog("Stopped monitoring for beacons")
            beaconsInRange.removeAll()
        }
    }
    
    // MARK: - ESTMonitoringV2ManagerDelegate
    
    func monitoringManagerDidStart(_ manager: ESTMonitoringV2Manager) {
        NSLog(#function)
    }
    
    func monitoringManager(_ manager: ESTMonitoringV2Manager, didFailWithError error: Error) {
    }

    lazy var inSound: SystemSoundID = {
        var sound: SystemSoundID = 0
        if let soundURL = Bundle.main.url(forResource: "in", withExtension: "wav") {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
        }
        return sound
    }()

    lazy var outSound: SystemSoundID = {
        var sound: SystemSoundID = 0
        if let soundURL = Bundle.main.url(forResource: "out", withExtension: "wav") {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
        }
        return sound
    }()

    func monitoringManager(_ manager: ESTMonitoringV2Manager,
                           didDetermineInitialState state: ESTMonitoringState,
                           forBeaconWithIdentifier identifier: String)
    {
        NSLog(#function)
        if let beaconData = BeaconData.beaconWithIdentifier(identifier), state == .insideZone {
            beaconsInRange.insert(beaconData)
            beaconsInRangeDidChange?(beaconsInRange.sorted { $0.timestamp < $1.timestamp })

            AudioServicesPlaySystemSound(inSound)

            if let location = lastKnownLocation {
                APIClient.shared.update(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude,
                                        beacons: Array(beaconsInRange))
            } else {
                locationManager.requestLocation()
            }
        }
    }
    
    func monitoringManager(_ manager: ESTMonitoringV2Manager, didEnterDesiredRangeOfBeaconWithIdentifier identifier: String)
    {
        NSLog(#function)
        if let beaconData = BeaconData.beaconWithIdentifier(identifier) {
            beaconsInRange.insert(beaconData)
            beaconsInRangeDidChange?(beaconsInRange.sorted { $0.timestamp < $1.timestamp })
            
            AudioServicesPlaySystemSound(inSound)
            
            if let location = lastKnownLocation {
                APIClient.shared.update(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude,
                                        beacons: Array(beaconsInRange))
            } else {
                locationManager.requestLocation()
            }
        }
    }
    
    func monitoringManager(_ manager: ESTMonitoringV2Manager, didExitDesiredRangeOfBeaconWithIdentifier identifier: String)
    {
        NSLog(#function)
        if let beaconData = BeaconData.beaconWithIdentifier(identifier) {
            beaconsInRange.remove(beaconData)
            beaconsInRangeDidChange?(beaconsInRange.sorted { $0.timestamp < $1.timestamp })

            AudioServicesPlaySystemSound(outSound)
            
            if let location = lastKnownLocation {
                APIClient.shared.update(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude,
                                        beacons: Array(beaconsInRange))
            } else {
                locationManager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {

            var lastKnownLocationDidChange = false
            if lastKnownLocation == nil {
                lastKnownLocationDidChange = true
                lastKnownLocation = location
            } else if let lastLocation = lastKnownLocation, location.distance(from: lastLocation) >= 3 {
                lastKnownLocationDidChange = true
                lastKnownLocation = location
            }

            if lastKnownLocationDidChange {
                APIClient.shared.update(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude,
                                        beacons: Array(beaconsInRange))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("\(#function) \(error)")
    }
}
