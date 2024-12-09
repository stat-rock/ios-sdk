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
                    if view.isSticky(){
                        moveToSticky(container: view)
                    }else{
                        view.pause()
                    }
                } else {
                    if view.isSticky(){
                        moveOriginal(container: view)
                    }else{
                        view.resume()
                    }
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
    
    func moveToSticky(container: UIView) {
        if let window = UIApplication.shared.keyWindow,
           let rootView = window.rootViewController?.view {
            let list = container.allSubViewsOf(type: StatRockView.self)
            if !list.isEmpty{
                let view = list[0]
                view.removeFromSuperview()
                rootView.addSubview(view)
                view.sizeToFit()
                
                NSLayoutConstraint.deactivate(view.constraints)
                if let size = view.getStickySize(){
                    let screenWidth = UIScreen.main.bounds.width
                    if size.width > screenWidth{
                        NSLayoutConstraint.activate([
                            view.widthAnchor.constraint(equalTo: rootView.widthAnchor),
                            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9.0 / 16.0)
                        ])
                    }else{
                        var width = size.width
                        var height = size.height
                        
                        NSLayoutConstraint.activate([
                            view.widthAnchor.constraint(equalToConstant: width),
                            view.heightAnchor.constraint(equalToConstant: height)
                        ])
                    }
                }else{
                    NSLayoutConstraint.activate([
                        view.widthAnchor.constraint(equalTo: rootView.widthAnchor),
                        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9.0 / 16.0)
                    ])
                }
                
                applyStickyPosition(view, to: rootView, at: view.getStickyPosition())

                UIView.animate(withDuration: 0.3) {
                    view.layoutIfNeeded()
                }
            }
        }
    }
    
    func moveOriginal(container: UIView) {
        if let window = UIApplication.shared.keyWindow,
           let rootView = window.rootViewController?.view {
            let list = rootView.allSubViewsOf(type: StatRockView.self)
            if !list.isEmpty{
                let view = list[0]
                view.removeFromSuperview()
                container.addSubview(view)
                view.sizeToFit()
                
                NSLayoutConstraint.deactivate(view.constraints)
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    view.topAnchor.constraint(equalTo: container.topAnchor),
                    view.topAnchor.constraint(equalTo: container.bottomAnchor),
                    view.heightAnchor.constraint(equalTo: container.heightAnchor)
                ])
                UIView.animate(withDuration: 0.3) {
                    view.layoutIfNeeded()
                }
            }
        }
    }
    
    func applyStickyPosition(_ stickyView: UIView, to parentView: UIView, at position: String?) {
        let alignment = parseStickyPosition(position)
        var constraints = [NSLayoutConstraint]()
        switch alignment.vertical {
        case .top:
            constraints.append(stickyView.topAnchor.constraint(equalTo: parentView.topAnchor))
        case .bottom:
            constraints.append(stickyView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor))
        default:
            break
        }
        switch alignment.horizontal {
        case .leading:
            constraints.append(stickyView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor))
        case .trailing:
            constraints.append(stickyView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor))
        case .centerX:
            constraints.append(stickyView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor))
        default:
            break
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    func parseStickyPosition(_ position: String?) -> (vertical: NSLayoutConstraint.Attribute, horizontal: NSLayoutConstraint.Attribute) {
        guard let position = position?.uppercased(), !position.isEmpty else {
            return (.top, .trailing)
        }
        
        switch position {
        case "TR": // Top Right
            return (.top, .trailing)
        case "TL": // Top Left
            return (.top, .leading)
        case "TC": // Top Center
            return (.top, .centerX)
        case "BR": // Bottom Right
            return (.bottom, .trailing)
        case "BL": // Bottom Left
            return (.bottom, .leading)
        case "BC": // Bottom Center
            return (.bottom, .centerX)
        default:
            fatalError("Invalid sticky position: \(position)")
        }
    }
}
