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
                id: "prod2",
                image: UIImage(named: "majnu"),
                title: "Modern Art",
                description: "Majnu Bhai Street Arts",
                price: 4999.0,
                currency: "₹",
                deliveryEstimate: "Delivery by Apr 20"
            ),
            ProductModel(
                id: "prod1",
                image: UIImage(named: "lsd"),
                title: "Paracetamol",
                description: "May or may not be parcetamol",
                price: 2999.0,
                currency: "₹",
                deliveryEstimate: "Yesterday"
            ),
            ProductModel(
                id: "prod2",
                image: UIImage(named: "neet-exam"),
                title: "NEET Papers 2026",
                description: "Sold by Deviprasad Printing",
                price: 499999.0,
                currency: "₹",
                deliveryEstimate: "Before Exams"
            ),
            ProductModel(
                id: "prod2",
                image: UIImage(named: "21din"),
                title: "Get Rich Quick Book",
                description: "Raju: Bestsellers",
                price: 499.0,
                currency: "₹",
                deliveryEstimate: "Before Exams"
            ),
            ProductModel(
                id: "prod5",
                image: UIImage(named: "unicorn"),
                title: "Original Unicorn",
                description: "HorshSheet",
                price: 99499.0,
                currency: "₹",
                deliveryEstimate: "Tommorow"
            ),
     
        ]
    }

    func product(at index: Int) -> ProductModel {
        return products[index]
    }

    var count: Int {
        return products.count
    }
}
