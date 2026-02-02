//
//  StartRockView.swift
//  StatRockSdk
//

import Foundation
import WebKit
import JavaScriptCore
import AppTrackingTransparency
import CoreLocation
import SystemConfiguration

public protocol StatRockDelegate {
    func onAdLoaded()
    func onAdStarted()
    func onAdStopped()
    func onAdError(errorType: AdErrorType, errorMessage: String?)
}

public enum StatRockType{
    case inPage
}

public class StatRockView : WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private static let HTTP_TIMEOUT_SECONDS: TimeInterval = 10
    private static let AD_LOAD_TIMEOUT_SECONDS: TimeInterval = 15
    
    private var placement:String!
    private var config:String!
    private var delegate:StatRockDelegate?
    private var changeConfig = false
    private var type: StatRockType?
    private var mapConfig: [String:Any]?
    private var adLoadStarted = false
    private var adLoadTimeoutTimer: Timer?
    
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
        self.delegate = delegate
        
        // Cancel any existing timeout
        cancelAdLoadTimeout()
        adLoadStarted = false
        
        if type == StatRockType.inPage{
            isHidden = true
        }
        
        // Check internet connection before making request
        if !isNetworkAvailable() {
            self.delegate?.onAdError(errorType: .noInternet, errorMessage: "No internet connection available")
            return
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
        
        // Configure URLSession with timeout
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = StatRockView.HTTP_TIMEOUT_SECONDS
        sessionConfig.timeoutIntervalForResource = StatRockView.HTTP_TIMEOUT_SECONDS
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.dataTask(with: url) {(data, response, error) in
            DispatchQueue.main.async() {[weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    // Handle timeout and network errors
                    let errorType: AdErrorType
                    let errorMessage: String
                    
                    if (error as NSError).code == NSURLErrorTimedOut {
                        errorType = .timeout
                        errorMessage = "Ad request timeout: \(error.localizedDescription)"
                    } else if (error as NSError).code == NSURLErrorNotConnectedToInternet ||
                              (error as NSError).code == NSURLErrorCannotFindHost ||
                              (error as NSError).code == NSURLErrorCannotConnectToHost {
                        errorType = .noInternet
                        errorMessage = "No internet connection: \(error.localizedDescription)"
                    } else {
                        errorType = .networkError
                        errorMessage = error.localizedDescription
                    }
                    
                    self.delegate?.onAdError(errorType: errorType, errorMessage: errorMessage)
                    return
                }
                
                guard let data = data else {
                    self.delegate?.onAdError(errorType: .networkError, errorMessage: "No data received")
                    return
                }
                
                let config = String(decoding: data, as: UTF8.self)
                self.placement = placement
                self.config = config
                do {
                    self.mapConfig = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    if var settings = self.mapConfig!["settings"] as? [String: Any]{
                        settings["_sdkECB"] = true
                        self.mapConfig?["settings"] = settings
                    }
                    if let mapConfig = self.mapConfig {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: mapConfig, options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                self.config = jsonString
                            }
                        } catch {
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
                self.changeConfig = true
                layoutSubviews()
                // Start timeout handler after WebView loads
                self.startAdLoadTimeout()
            }
        }
        task.resume()
    }
    
    public func isSticky()->Bool{
        if let mapConfig = self.mapConfig{
            if let settings = mapConfig["settings"] {
                let settings = settings as? [String:Any]
                if let advertising = settings?["advertising"] {
                    let advertising = advertising as? [String:Any]
                    if let sticky = advertising?["sticky"] as? Bool {
                        return sticky
                    }
                }
            }
        }
        return false
    }
    
    public func getStickySize()->CGSize?{
        if let mapConfig = self.mapConfig{
            if let settings = mapConfig["settings"] {
                let settings = settings as? [String:Any]
                if let advertising = settings?["advertising"] {
                    let advertising = advertising as? [String:Any]
                    if let sticky = advertising?["sticky"] {
                        let stickyWidth = advertising?["stickyWidth"] as! String
                        let stickyHeight = advertising?["stickyHeight"] as! String
                        return CGSize(width: CGFloat(Double(stickyWidth)!), height: CGFloat(Double(stickyHeight)!))
                    }
                }
            }
        }
        return nil
    }
    
    public func getStickyPosition()->String?{
        if let mapConfig = self.mapConfig{
            if let settings = mapConfig["settings"] {
                let settings = settings as? [String:Any]
                if let advertising = settings?["advertising"] {
                    let advertising = advertising as? [String:Any]
                    return advertising?["position"] as? String;
                }
            }
        }
        return nil
    }
    
    public func enoughPercentsForDeactivation(visibilityPercents: Int)->Bool {
        var percents = 30;
        if self.config != nil {
            if let mapConfig = self.mapConfig {
                if let settings = mapConfig["settings"] {
                    let settings = settings as? [String:Any]
                    if let advertising = settings?["advertising"] {
                        let advertising = advertising as? [String:Any]
                        if let playPercent = advertising?["playPercent"] {
                            percents = playPercent as! Int
                        }
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
            
            if let mapConfig = self.mapConfig{
                let player = mapConfig["player"] as! String
                let script = mapConfig["script"] as! String
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
                    self.adLoadStarted = true
                    self.cancelAdLoadTimeout()
                    self.delegate?.onAdLoaded()
                case "AdStarted":
                    self.adLoadStarted = true
                    self.cancelAdLoadTimeout()
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
                    self.cancelAdLoadTimeout()
                    // Convert string to enum for compatibility with JavaScript bridge
                    let errorMessage = messageBody["message"] as? String
                    let errorType = AdErrorType.fromString(errorMessage)
                    self.delegate?.onAdError(errorType: errorType, errorMessage: messageBody["error"] as? String)
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
    
    private func isNetworkAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
    
    private func startAdLoadTimeout() {
        cancelAdLoadTimeout()
        adLoadStarted = false
        
        adLoadTimeoutTimer = Timer.scheduledTimer(withTimeInterval: StatRockView.AD_LOAD_TIMEOUT_SECONDS, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.adLoadStarted {
                print("Ad load timeout: no response from ad network")
                self.delegate?.onAdError(errorType: .timeout, errorMessage: "Ad load timeout: no response from ad network")
            }
        }
    }
    
    private func cancelAdLoadTimeout() {
        adLoadTimeoutTimer?.invalidate()
        adLoadTimeoutTimer = nil
    }
}

