//
//  Untitled.swift
//  MonkeyMerchant
//
//  Created by Nirman Kalia on 13/04/25.
//

import Foundation
import UIKit

import UIKit

struct ProductModel {
    let id: String
    let image: UIImage?
    let title: String
    let description: String
    let price: Double
    let currency: String
    let deliveryEstimate: String
}

final class MonkeyFeedViewModel {
    var products: [ProductModel] = []

    init() {
        loadDummyProducts()
    }

    private func loadDummyProducts() {
        products = [
            ProductModel(
                id: "prod1",
                image: UIImage(named: "airpod"),
                title: "Monkey Wireless Earbuds",
                description: "High-quality Bluetooth earbuds with noise cancellation.",
                price: 2999.0,
                currency: "₹",
                deliveryEstimate: "Delivery by Apr 18"
            ),
            ProductModel(
                id: "prod2",
                image: UIImage(named: "watch"),
                title: "Monkey Smartwatch",
                description: "Track your fitness and stay connected.",
                price: 4999.0,
                currency: "₹",
                deliveryEstimate: "Delivery by Apr 20"
            )
        ]
    }

    func product(at index: Int) -> ProductModel {
        return products[index]
    }

    var count: Int {
        return products.count
    }
}
