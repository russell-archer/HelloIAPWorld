//
//  IAPNotification.swift
//  HelloIAPWorld
//
//  Created by Russell Archer on 16/11/2020.
//

import Foundation

/// Notifications issued by IAPHelper
public enum IAPNotification: Error, Equatable {
    
    case purchaseAbortPurchaseInProgress
    case purchaseCompleted(productId: ProductId)
    case purchaseFailed(productId: ProductId)
    case purchaseCancelled(productId: ProductId)
    case requestProductsSuccess
    case requestProductsDidFinish
    case requestProductsFailed
    case requestProductsNoProducts
    case requestProductsInvalidProducts
    case requestReceiptRefreshSuccess
    case requestReceiptRefreshFailed
    
    /// A short description of the notification.
    /// - Returns: Returns a short description of the notification.
    public func shortDescription() -> String {
        switch self {
 
        case .purchaseAbortPurchaseInProgress:  return "Purchase aborted because another purchase is already in progress"
        case .purchaseCompleted:                return "Purchase completed"
        case .purchaseFailed:                   return "Purchase failed"
        case .purchaseCancelled:                return "Purchase cancelled"
        case .requestProductsSuccess:           return "Products retrieved from App Store"
        case .requestProductsDidFinish:         return "The request for products finished"
        case .requestProductsFailed:            return "The request for products failed"
        case .requestProductsNoProducts:        return "The App Store returned an empty list of products"
        case .requestProductsInvalidProducts:   return "The App Store returned a list of invalid (unrecognized) products"
        case .requestReceiptRefreshSuccess:     return "The request for a receipt refresh completed successfully"
        case .requestReceiptRefreshFailed:      return "The request for a receipt refresh failed"
        }
    }
}

