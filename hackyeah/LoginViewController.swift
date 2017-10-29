//
//  LoginViewController.swift
//  hackyeah
//
//  Created by Dominik Kapusta on 28/10/2017.
//  Copyright © 2017 Base. All rights reserved.
//

import UIKit

extension UIColor {
    static let team1 = UIColor(red: 127/255, green: 219/255, blue: 255/255, alpha: 1)
    static let team2 = UIColor(red: 255/255, green: 65/255, blue: 54/255, alpha: 1)
    static let team1bg = UIColor(red: 172/255, green: 229/255, blue: 251/255, alpha: 1)
    static let team2bg = UIColor(red: 255/255, green: 186/255, blue: 182/255, alpha: 1)
}

class LoginViewController: UIViewController {
    @IBOutlet private weak var team1Button: UIButton!
    @IBOutlet private weak var team2Button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        team1Button.backgroundColor = UIColor.team1
        team2Button.backgroundColor = UIColor.team2
        team1Button.layer.cornerRadius = 8
        team2Button.layer.cornerRadius = 8
    }
    
    @IBAction func logIn(_ sender: UIButton) {
        let teamID: Int64 = sender == team1Button ? 1 : 2
        APIClient.shared.logIn(teamID: teamID, userID: 1) { (success) in
            dismiss(animated: true, completion: nil)
        }
    }
}
