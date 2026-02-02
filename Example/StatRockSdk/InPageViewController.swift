//
//  InPageViewController.swift
//  StatRockSdk_Example
//
//  Created by jobs on 23.07.2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import StatRockSdk

class InPageViewController: UIViewController{
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var statRockView: StatRockViewContainer!
    @IBOutlet weak var htmlText: UITextView!
    
    private var scrollDelegate = StatRockScrollViewDelegate()
    private var loading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "In Page"
        scrollView.delegate = self
        
        htmlText.attributedText = htmlText.text.attributedHtmlString
    }
    
    private func load() {
        if statRockView.getVisibilityPercents(scroll: scrollView) == 100, !loading{
            loading = true
            statRockView.load(placement: "Hr5pC_SLH6PV", type: StatRockType.inPage, delegate: self)
        }
    }
}

extension InPageViewController: UIScrollViewDelegate{
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        load()
        scrollDelegate.scrollViewDidScroll(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollDelegate.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
}

extension InPageViewController: StatRockDelegate{
    func onAdLoaded() {
        print("onAdLoaded")
    }
    
    func onAdStarted() {
        print("onAdStarted")
    }
    
    func onAdStopped() {
        print("onAdStopped ")
    }
    
    func onAdError(errorType: AdErrorType, errorMessage: String?) {
        print("onAdError type: \(errorType.rawValue), message: \(errorMessage ?? "")")
    }
}

extension String {
    
    var utfData: Data {
        return Data(utf8)
    }
    
    var attributedHtmlString: NSAttributedString? {
        do {
            let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 19),
                          NSAttributedStringKey.foregroundColor: UIColor.black]

            let attr = try NSMutableAttributedString(data: utfData, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            attr.addAttributes(attributes, range: NSRange(location: 0, length: attr.length))
            return attr
        } catch {
            return nil
        }
    }
}
