//
//  StatRockViewContainer.swift
//  StatRockSdk
//
//  Created by jobs on 24.07.2024.
//

import Foundation

public class StatRockViewContainer: UIView{
    private var statRock: StatRockView!
    private var delegate: StatRockDelegate?
    private var type: StatRockType?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize(){
        statRock = StatRockView()
        statRock.translatesAutoresizingMaskIntoConstraints = false
        statRock.sizeToFit()
        addSubview(statRock)
        
        NSLayoutConstraint.activate([
            statRock.leadingAnchor.constraint(equalTo: leadingAnchor),
            statRock.trailingAnchor.constraint(equalTo: trailingAnchor),
            statRock.topAnchor.constraint(equalTo: topAnchor),
            statRock.topAnchor.constraint(equalTo: bottomAnchor),
            statRock.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
    
    public func load(placement: String, type: StatRockType? = nil, delegate: StatRockDelegate? = nil){
        self.delegate = delegate
        self.type = type
        if type == StatRockType.inPage{
            isHidden = true
        }
        statRock.load(placement: placement, type: type, delegate: self)
    }
    
    public func enoughPercentsForDeactivation(visibilityPercents: Int)->Bool {
        statRock.enoughPercentsForDeactivation(visibilityPercents: visibilityPercents)
    }
    
    public func getVisibilityPercents(scroll: UIView?)->Int{
        if let scroll = scroll{
            let visibleRect = CGRectIntersection(frame, scroll.bounds)
            return (100 * Int(CGRectGetHeight(visibleRect))) / Int(frame.height)
        }
        return 0
    }
    
    public func isSticky()->Bool{
        return statRock.isSticky()
    }
    
    public func getStickySize()->CGSize?{
        return statRock.getStickySize()
    }
    
    public func getStickyPosition()->String?{
        return statRock.getStickyPosition()
    }
    
    public func pause(){
        statRock.pause()
    }
    
    public func resume(){
        statRock.resume()
    }
}

extension StatRockViewContainer: StatRockDelegate{
    public func onAdLoaded() {
        delegate?.onAdLoaded()
    }
    
    public func onAdStarted() {
        if type == StatRockType.inPage{
            isHidden = false
        }
        delegate?.onAdStarted()
    }
    
    public func onAdStopped() {
        if type == StatRockType.inPage{
            isHidden = true
        }
        delegate?.onAdStopped()
    }
    
    public func onAdError(errorType: AdErrorType, errorMessage: String?) {
        delegate?.onAdError(errorType: errorType, errorMessage: errorMessage)
    }
}
