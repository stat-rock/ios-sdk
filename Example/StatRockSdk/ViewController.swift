//
//  ViewController.swift
//  StatRockSdk
//

import UIKit

class ViewController: UIViewController {

    @IBAction func inCustomTapped(_ sender: UIButton) {
        let vc = CustomViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func inPageTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "InPage", bundle: nil)
        let vc : InPageViewController = (storyboard.instantiateViewController (withIdentifier: "InPage") as? InPageViewController)!
        navigationController?.pushViewController(vc, animated: true)
    }
}
