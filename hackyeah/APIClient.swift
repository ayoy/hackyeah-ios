//
//  APIClient.swift
//  hackyeah
//
//  Created by Dominik Kapusta on 28/10/2017.
//  Copyright © 2017 Base. All rights reserved.
//

import UIKit

extension BeaconData {
    var name: String? {
        switch self {
        case .BC1:
            return "bc1"
        case .BC2:
            return "bc2"
        case .BC3:
            return "bc3"
        default:
            return nil
        }
    }
}

class APIClient: NSObject {
    
    static let shared = APIClient()
    
    var isUserLoggedIn: Bool {
        return currentTeamID != nil && currentUserID != nil
    }
    
    private(set) var currentTeamID: Int64? = nil
    private(set) var currentUserID: Int64? = nil
    
    func logIn(teamID: Int64, userID: Int64, completionHandler: ((Bool) -> Void)) {
        currentTeamID = teamID
        currentUserID = userID
        completionHandler(true)
    }
    
    func update(latitude: Double, longitude: Double, beacons: [BeaconData]) {
        guard let userID = currentUserID, let teamID = currentTeamID else { return }
        let urlString = "https://yjpcjabyax.localtunnel.me//api/ctf/pos/\(teamID)/\(userID)"
        var request: URLRequest = URLRequest(url: URL(string: urlString)!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let dict: [String:Any] = ["lat": latitude, "lon": longitude, "beacons": beacons.flatMap({$0.name})]
        request.httpMethod = "POST"
        
        do {
        
            request.httpBody = try JSONSerialization.data(withJSONObject: dict, options: [])
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let responseData = data {
                    let responseJSON = try! JSONSerialization.jsonObject(with: responseData, options: [])
                    NSLog("response: \(responseJSON)")
                }
            }
            NSLog("\(urlString): \(request.httpBody!)")
            task.resume()

        } catch (let error) {
            NSLog("JSON serialization error: \(error)")
        }
        
    }
}
