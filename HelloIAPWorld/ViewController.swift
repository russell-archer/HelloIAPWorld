//
//  ViewController.swift
//  HelloIAPWorld
//
//  Created by Russell Archer on 16/11/2020.
//

import UIKit

class ViewController: UIViewController {

    private var tableView = UITableView(frame: .zero)
    private let iap = IAPHelper.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureProducts()
    }

    private func configureTableView() {
        view.addSubview(tableView)
       
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
       
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)  // Removes empty cells
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseId)
    }
    
    private func configureProducts() {
        // Ask the App Store for a list of localized products
        iap.requestProductsFromAppStore { notification in
            
            print(notification)
            if notification == .requestProductsDidFinish { self.tableView.reloadData() }
        }
    }
}

// MARK:- UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    internal func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var purchased = false
        if let p = iap.products?[indexPath.row], iap.isProductPurchased(id: p.productIdentifier) { purchased = true }
        
        return purchased ? ProductCell.cellHeightPurchased : ProductCell.cellHeightUnPurchased
    }
        
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        iap.products == nil ? 0 : iap.products!.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        configureProductCell(for: indexPath)
    }
    
    private func configureProductCell(for indexPath: IndexPath) -> ProductCell {
        guard let products = iap.products else { return ProductCell() }
        
        let product = products[indexPath.row]
        var price =  IAPHelper.getLocalizedPriceFor(product: product)
        if price == nil { price = "Price unknown" }
        
        let productInfo = IAPProductInfo(id: product.productIdentifier,
                                         imageName: product.productIdentifier,
                                         localizedTitle: product.localizedTitle,
                                         localizedDescription: product.localizedDescription,
                                         localizedPrice: price!,
                                         purchased: iap.isProductPurchased(id: product.productIdentifier))
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseId) as! ProductCell
        cell.delegate = self
        cell.productInfo = productInfo
        
        return cell
    }
}

// MARK:- ProductCellDelegate

extension ViewController: ProductCellDelegate {
    
    internal func requestBuyProduct(productId: ProductId) {
        guard let product = iap.getStoreProductFrom(id: productId) else { return }
        
        // Start the process to purchase the product
        iap.buyProduct(product) { notification in
            switch notification {
            case .purchaseAbortPurchaseInProgress: print("Purchase aborted because another purchase is being processed")
            case .purchaseCompleted(productId: let pid): print("Purchase completed for product \(pid)")
            case .purchaseCancelled(productId: let pid): print("Purchase cancelled for product \(pid)")
            case .purchaseFailed(productId: let pid): print("Purchase failed for product \(pid)")
            default: break
            }
            
            self.tableView.reloadData()  // Reload data for a success, cancel or failure
        }
    }
}


