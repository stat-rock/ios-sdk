//
//  ViewController.swift
//  StatRockSdk
//

import UIKit
import StatRockSdk

class ViewController: UIViewController, StatRockDelegate {
    var playerViewS:StatRockView?
    var playerViewD:StatRockView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        playerViewS = StatRockView()
        playerViewS?.frame = CGRect(x: 16, y: 50, width: 200, height: 100)
        
        playerViewD = StatRockView()
        playerViewD?.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playerViewS!)
        view.addSubview(playerViewD!)
        
        NSLayoutConstraint.activate([
            playerViewD!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerViewD!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playerViewD!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 128),
            playerViewD!.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        playerViewS?.load(placement: "Hr5pC_SLH6PV", delegate: self)
        playerViewD?.load(placement: "Hr5pC_SLH6PV", delegate: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func onAdLoaded() {
        print("onAdLoaded")
    }
    
    func onAdStarted() {
        print("onAdStarted")
    }
    
    func onAdStopped() {
        print("onAdStopped ")
    }
    
    func onAdError(msg: String?) {
        print("onAdError \(msg ?? "")")
    }
}
