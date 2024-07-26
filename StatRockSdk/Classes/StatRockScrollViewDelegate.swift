//
//  StatRockScrollViewDelegate.swift
//  StatRockSdk
//
//  Created by jobs on 23.07.2024.
//

import Foundation

public class StatRockScrollViewDelegate: NSObject, UIScrollViewDelegate{
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        findAndFire(scrollView: scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        findAndFire(scrollView: scrollView)
    }
    
    private func findAndFire(scrollView: UIScrollView) {
        let containers = scrollView.allSubViewsOf(type: StatRockViewContainer.self)
        if !containers.isEmpty {
            for view in containers{
                let percent = view.getVisibilityPercents(scroll: scrollView)
                if view.enoughPercentsForDeactivation(visibilityPercents: percent) {
                    view.pause()
                } else {
                    view.resume()
                }
            }
        }else{
            let views = scrollView.allSubViewsOf(type: StatRockView.self)
            if !views.isEmpty {
                for view in containers{
                    let percent = view.getVisibilityPercents(scroll: scrollView)
                    if view.enoughPercentsForDeactivation(visibilityPercents: percent) {
                        view.pause()
                    } else {
                        view.resume()
                    }
                }
            }
        }
    }
}
