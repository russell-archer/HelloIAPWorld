//
//  IAPHelper.swift
//  HelloIAPWorld
//
//  Created by Russell Archer on 16/11/2020.
//

import UIKit
import StoreKit

public typealias ProductId = String

/// IAPHelper coordinates in-app purchases. Make sure to initiate IAPHelper early in the app's lifecycle so that
/// notifications from the App Store are not missed. For example, reference `IAPHelper.shared` in
/// `application(_:didFinishLaunchingWithOptions:)` in AppDelegate.
///
public class IAPHelper: NSObject  {
    
    /// Singleton access. Use IAPHelper.shared to access all IAPHelper properties and methods.
    public static let shared: IAPHelper = IAPHelper()
    
    /// True if a purchase is in progress (excluding a deferred purchase).
    public var isPurchasing = false

    /// List of localized product info retrieved from the App Store and available for purchase.
    public var products: [SKProduct]?
    
    /// Set of purchased products. In a real-world app this list would be presisted and compared against the IAP data in the App Store receipt.
    public var purchasedProductIdentifiers = Set<ProductId>()
    
    /// Duplicate list of ProductIds stored in the .storekit configuration file.
    public var configuredProductIdentifiers: Set<ProductId> = [
        "com.rarcher.flowers-large",
        "com.rarcher.flowers-small",
        "com.rarcher.roses-large",
        "com.rarcher.chocolates.small"]

    internal var productsRequest: SKProductsRequest?  // Request object used to request products from the App Store
    internal var requestProductsCompletion: ((IAPNotification) -> Void)? = nil  // Completion handler when requesting products from the app store
    internal var purchaseCompletion: ((IAPNotification?) -> Void)? = nil  // Completion handler when purchasing a product from the App Store
    
    /// Private initializer prevents more than a single instance of this class being created. See the public static 'shared' property.
    /// It's vital that this helper be initialized as soon as possible in the app's lifecycle. For example, see the
    /// application(_:didFinishLaunchingWithOptions:) method.
    private override init() {
        super.init()
        
        // Add ourselves to the payment queue so we get App Store notifications
        SKPaymentQueue.default().add(self)
    }
    
    /// Call this method to remove IAPHelper as an observer of the StoreKit payment queue.
    /// This should be done from the AppDelgate applicationWillTerminate(_:) method.
    public func removeFromPaymentQueue() {
        SKPaymentQueue.default().remove(self)
    }
    
    /// Request from the App Store the collection of products that we've configured for sale in App Store Connect.
    /// - Parameter completion:     A closure that will be called when the results are returned from the App Store.
    /// - Parameter notification:   An IAPNotification with a value of .configurationNoProductIds,
    ///                             .requestProductsSuccess or .requestProductsFailed
    public func requestProductsFromAppStore(completion: @escaping (_ notification: IAPNotification) -> Void) {
        
        requestProductsCompletion = completion  // Save the completion handler so it can be used in productsRequest(_:didReceive:)
        
        // Request a list of products from the App Store. We use this request to present localized
        // prices and other information to the user. The results are returned asynchronously
        // to the SKProductsRequestDelegate methods productsRequest(_:didReceive:) or
        // request(_:didFailWithError:).
        productsRequest?.cancel()  // Cancel any existing pending requests
        productsRequest = SKProductsRequest(productIdentifiers: configuredProductIdentifiers)
        productsRequest!.delegate = self  // Will notify through productsRequest(_:didReceive:)
        productsRequest!.start()
    }
    
    /// Start the process to purchase a product. When we add the payment to the default payment queue
    /// StoreKit will present the required UI to the user and start processing the payment. When that
    /// transaction is complete or if a failure occurs, the payment queue sends the SKPaymentTransaction
    /// object that encapsulates the request to all transaction observers. See the
    /// paymentQueue(_:updatedTransactions) for how these events get handled.
    /// - Parameter product:        An SKProduct object that describes the product to purchase.
    /// - Parameter completion:     Completion block that will be called when the purchase has completed, failed or been cancelled.
    /// - Parameter notification:   An IAPNotification with a value of .purchaseCompleted, .purchaseCancelled or .purchaseFailed
    public func buyProduct(_ product: SKProduct, completion: @escaping (_ notification: IAPNotification?) -> Void) {
        guard !isPurchasing else {
            // Don't allow another purchase to start until the current one completes
            completion(.purchaseAbortPurchaseInProgress)
            return
        }

        purchaseCompletion = completion  // Save the completion block for later use
        isPurchasing = true
        
        let payment = SKPayment(product: product)  // Wrap the SKProduct in an SKPayment object
        SKPaymentQueue.default().add(payment)
    }
    
    /// The Apple ID of some users (e.g. children) may not have permission to make purchases from the app store.
    /// - Returns: Returns true if the user is allowed to authorize payment, false if they do not have permission.
    public class func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }
    
    /// Returns an SKProduct given a ProductId.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns an SKProduct object containing localized information about the product, or nil if no product is found.
    public func getStoreProductFrom(id: ProductId) -> SKProduct? {
        guard products != nil else { return nil }
        
        let selectedProducts = products!.filter { product in product.productIdentifier == id }
        guard selectedProducts.count > 0 else { return nil }
        
        return selectedProducts.first
    }
    
    /// Returns a product's title given a ProductId.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns a product's title, or nil if no product is found.
    public func getProductTitleFrom(id: ProductId) -> String? {
        guard let p = getStoreProductFrom(id: id) else { return nil }
        return p.localizedTitle
    }
    
    /// Get a localized price for a product.
    /// - Parameter product: SKProduct for which you want the local price.
    /// - Returns:           Returns a localized price String for a product.
    public class func getLocalizedPriceFor(product: SKProduct) -> String? {
        let priceFormatter = NumberFormatter()
        priceFormatter.formatterBehavior = .behavior10_4
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }
    
    /// Returns true if the product identified by the ProductId has been purchased.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns true if the product has previously been purchased, false otherwise.
    public func isProductPurchased(id: ProductId) -> Bool { purchasedProductIdentifiers.contains(id) }
}

// MARK:- SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    /// This delegate allows us to receive notifications from the App Store when payments are successful, fail, are restored, etc.
    /// - Parameters:
    ///   - queue:          The payment queue object.
    ///   - transactions:   Transaction information.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:    purchaseCompleted(transaction: transaction)
            case .failed:       purchaseFailed(transaction: transaction)
            case .purchasing:   fallthrough  // Ignored in this demo
            case .restored:     fallthrough  // Ignored in this demo
            case .deferred:     return       // Ignored in this demo
            default:            return
            }
        }
    }

    private func purchaseCompleted(transaction: SKPaymentTransaction) {
        // The purchase (or restore) was successful. Allow the user access to the product
        // Note that we do not present a confirmation alert to the user as StoreKit will have already done this.
        isPurchasing = false

        // Save the purchased ProductId
        purchasedProductIdentifiers.insert(transaction.payment.productIdentifier)
        
        // Call the completion handler
        DispatchQueue.main.async { self.purchaseCompletion?(.purchaseCompleted(productId: transaction.payment.productIdentifier)) }

        // It's important we remove the completed transaction from the queue. If this isn't done
        // then when the app restarts the payment queue will attempt to process the same transaction
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func purchaseFailed(transaction: SKPaymentTransaction) {
        // The purchase failed. Don't allow the user access to the product

        isPurchasing = false
        let identifier = transaction.payment.productIdentifier
        DispatchQueue.main.async { self.purchaseCompletion?(.purchaseFailed(productId: identifier)) }
        
        // Always call SKPaymentQueue.default().finishTransaction() for a failure
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

// MARK:- SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

    /// Receives a list of localized product info from the App Store.
    /// - Parameters:
    ///   - request:    The request object.
    ///   - response:   The response from the App Store.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard !response.products.isEmpty else {
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsNoProducts) }
            return
        }
        
        guard response.invalidProductIdentifiers.isEmpty else {
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsInvalidProducts) }  // Call the completion handler
            return
        }

        // Update our [SKProduct] set of all available products
        products = response.products
        DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsSuccess) }  // Call the completion handler
        
        // When this method returns StoreKit will immediately call the SKRequestDelegate method
        // requestDidFinish(_:) where we will destroy the productsRequest object
    }
}

// MARK:- SKRequestDelegate

extension IAPHelper: SKRequestDelegate {
    
    /// This method is called for both SKProductsRequest (request product info) and
    /// SKRequest (request receipt refresh).
    public func requestDidFinish(_ request: SKRequest) {

        if productsRequest != nil {
            productsRequest = nil  // Destroy the request object
            
            // Call the completion handler. The request for product info completed. See also productsRequest(_:didReceive:)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsDidFinish) }
        }
    }
    
    /// Called by the App Store if a request fails.
    /// This method is called for both SKProductsRequest (request product info) and SKRequest (request receipt refresh).
    /// - Parameters:
    ///   - request:    The request object.
    ///   - error:      The error returned by the App Store.
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        
        if productsRequest != nil {
            productsRequest = nil  // Destroy the request object
            
            // Call the completion handler. The request for product info failed
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsFailed) }
        }
    }
}

