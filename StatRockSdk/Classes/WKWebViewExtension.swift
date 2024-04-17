//
//  WKWebViewExtension.swift
//  StatRockSdk
//

import Foundation


import Foundation
import WebKit

extension WKWebView {
    
    func setScrollEnabled(enabled: Bool) {
        self.scrollView.isScrollEnabled = enabled
        self.scrollView.panGestureRecognizer.isEnabled = enabled
        self.scrollView.bounces = enabled
        self.scrollView.isPagingEnabled = enabled
        
        for subview in self.subviews {
            if let subview = subview as? UIScrollView {
                subview.isScrollEnabled = enabled
                subview.bounces = enabled
                subview.panGestureRecognizer.isEnabled = enabled
                subview.isPagingEnabled = enabled
            }
            
            for subScrollView in subview.subviews {
                if type(of: subScrollView) == NSClassFromString("WKContentView")!,
                   let gestureRecognizers = subScrollView.gestureRecognizers {
                    for gesture in gestureRecognizers {
                        subScrollView.removeGestureRecognizer(gesture)
                    }
                }
            }
        }
    }
}
