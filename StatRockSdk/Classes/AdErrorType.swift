//
//  AdErrorType.swift
//  StatRockSdk
//
//  Created on 29.01.2025.
//

import Foundation

public enum AdErrorType: String {
    case noInternet = "no internet"
    case timeout = "timeout"
    case networkError = "Network error"
    case noAd = "no ad"
    case unknown = "unknown"
    
    /// Converts string value to AdErrorType enum.
    /// Used for compatibility with JavaScript bridge.
    ///
    /// - Parameter value: string value to convert
    /// - Returns: AdErrorType enum or unknown if value doesn't match
    public static func fromString(_ value: String?) -> AdErrorType {
        guard let value = value else {
            return .unknown
        }
        return AdErrorType(rawValue: value) ?? .unknown
    }
}
