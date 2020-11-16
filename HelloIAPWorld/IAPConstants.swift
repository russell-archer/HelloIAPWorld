//
//  IAPConstants.swift
//  HelloIAPWorld
//
//  Created by Russell Archer on 16/11/2020.
//

import Foundation

/// Constants used in support of IAP operations.
public struct IAPConstants {

    /// The appropriate certificate to use for DEBUG and RELEASE builds.
    /// - Returns: Returns the appropriate certificate to use for
    /// DEBUG and RELEASE builds.
    public static func Certificate() -> String {
        #if DEBUG
        // This is issued by StoreKit for local testing
        return "StoreKitTestCertificate"
        #else
        // For release with the real App Store
        return "AppleIncRootCertificate"
        #endif
    }
}
