//
//  StartRockView.swift
//  StatRockSdk
//

import Foundation
import WebKit
import JavaScriptCore
import AppTrackingTransparency
import CoreLocation

public protocol StatRockDelegate {
    func onAdLoaded()
    func onAdStarted()
    func onAdStopped()
    func onAdError(msg: String?)
}

public enum StatRockType{
    case inPage
}

public class StatRockView : WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var placement:String!
    private var config:String!
    private var delegate:StatRockDelegate?
    private var changeConfig = false
    private var type: StatRockType?
    
    public init() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        config.allowsInlineMediaPlayback = true
        config.userContentController = contentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypes.init(rawValue: 0)
        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = false
        } else {
        }
        super.init(frame: .zero, configuration: config)
        contentController.add(self, name: "toggleMessageHandler")
        
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize(){
        isOpaque = false
        backgroundColor = .clear
        navigationDelegate = self
        uiDelegate = self
        isUserInteractionEnabled = true
        allowsLinkPreview = true
        scrollView.backgroundColor = .clear
        setScrollEnabled(enabled: false)
    }
    
    public func load(placement: String, type: StatRockType? = nil, delegate: StatRockDelegate? = nil){
        self.type = type
        
        if type == StatRockType.inPage{
            isHidden = true
        }
        
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        var dnt = true
        if #available(iOS 14, *) {
            dnt = ATTrackingManager.trackingAuthorizationStatus != .denied
        }
        let deviceMake = UIDevice.current.model
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let appName = Bundle.applicationName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        
        let locManager = CLLocationManager()
        var lat = 0.0
        var lon = 0.0
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways{
            lat = locManager.location?.coordinate.latitude ?? 0.0
            lon = locManager.location?.coordinate.latitude ?? 0.0
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "serving.stat-rock.com"
        urlComponents.path = "/v1/placements/\(placement)/code/mobile/1"
        urlComponents.queryItems = [URLQueryItem(name: "DEVICE_ID", value: deviceId),
                                    URLQueryItem(name: "DNT", value: String(dnt)),
                                    URLQueryItem(name: "DEVICE_MAKE", value: deviceMake),
                                    URLQueryItem(name: "APP_BUNDLE", value: bundleId),
                                    URLQueryItem(name: "APP_NAME", value: appName),
                                    URLQueryItem(name: "APP_VERSION", value: appVersion),
                                    URLQueryItem(name: "LAT", value: String(lat)),
                                    URLQueryItem(name: "LON", value: String(lon))]
        let url = urlComponents.url!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            let config = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async() {[weak self] in
                guard let self = self else { return }
                self.placement = placement
                self.config = config
                self.delegate = delegate
                self.changeConfig = true
                layoutSubviews()
            }
        }
        task.resume()
    }
    
    public func enoughPercentsForDeactivation(visibilityPercents: Int)->Bool {
        var percents = 30;
        if let config = try? JSONSerialization.jsonObject(with: self.config.data(using: .utf8)!, options: []) {
            let map = config as? [String:Any]
            
            if let settings = map?["settings"] {
                let settings = settings as? [String:Any]
                if let advertising = settings?["advertising"] {
                    let advertising = advertising as? [String:Any]
                    if let playPercent = advertising?["playPercent"] {
                        percents = playPercent as! Int
                    }
                }
            }
        }
        
        return visibilityPercents <= percents;
    }
    
    public func getVisibilityPercents(scroll: UIView?)->Int{
        if let scroll = scroll{
            let visibleRect = CGRectIntersection(frame, scroll.bounds)
            return (100 * Int(CGRectGetHeight(visibleRect))) / Int(frame.height)
        }
        return 0
    }
    
    public func pause(){
        evaluateJavaScript("pause()")
    }
    
    public func resume(){
        evaluateJavaScript("resume()")
    }
    
    public override func layoutSubviews(){
        super.layoutSubviews()
        
        if let _ = placement, changeConfig {
            changeConfig = false
            
            if let config = try? JSONSerialization.jsonObject(with: self.config.data(using: .utf8)!, options: []) {
                let map = config as? [String:Any]
                let player = map?["player"] as! String
                let script = map?["script"] as! String
                let body = self.getVideoJSMarkup(player: player, script: script, config: self.config)
                loadHTMLString(body, baseURL:nil)
            }
        }
    }
    
    private func getVideoJSMarkup(player: String, script: String, config: String) -> String {
        return """
                    <!DOCTYPE html>
                    <html>
                    <head><title></title>
                        <meta name="viewport" content="initial-scale=1, user-scalable=no"/>
                        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>\n
                        <style type=\"text/css\">\n
                        html, body {\n
                        width: 100%;\n
                        height: 100%;\n
                        margin: 0px;\n
                        padding: 0px;\n
                        background-color: transparent;\n
                        }\n
                        </style>
                    </head>
                    <body>
                    <script src=\"\(player)\"></script>
                    <script src=\"\(script)\"></script>
                    <div style=\"\"></div>
                    <script>/*<!--*/init(\(config), 'fullscreen')/*-->*/</script>
                    </body>
                    </html>\n
                """
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
    
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "toggleMessageHandler", let messageBody = message.body as? [String:Any] {
            if let event = messageBody["event"] as? String {
                switch(event){
                case "AdLoaded":
                    self.delegate?.onAdLoaded()
                case "AdStarted":
                    if type == StatRockType.inPage{
                        isHidden = false
                    }
                    self.delegate?.onAdStarted()
                case "AdStopped":
                    if type == StatRockType.inPage{
                        isHidden = true
                    }
                    self.delegate?.onAdStopped()
                case "AdError":
                    self.delegate?.onAdError(msg: messageBody["message"] as? String)
                default:
                    break
                }
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("Webview did finish")
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        return
    }
}

