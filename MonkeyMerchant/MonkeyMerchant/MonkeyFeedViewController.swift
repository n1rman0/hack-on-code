//
//  ViewController.swift
//  MonkeyMerchant
//
//  Created by Nirman Kalia on 12/04/25.
//

import UIKit
import Razorpay

import UIKit

final class MonkeyFeedViewController: UIViewController {

    private let viewModel = MonkeyFeedViewModel()
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Monkey Marketplace"
        view.backgroundColor = .secondarySystemBackground
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .secondarySystemBackground
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductCardCell.self, forCellReuseIdentifier: ProductCardCell.reuseId)
        tableView.separatorStyle = .none
    }
}

// MARK: - UITableViewDataSource
extension MonkeyFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCardCell.reuseId, for: indexPath) as! ProductCardCell
        let product = viewModel.product(at: indexPath.row)

        cell.configure(with: product)
        cell.onBuyTapped = { [weak self] in
            guard let self = self else { return }

            let cartItem = CartItemModel(
                productImage: product.image,
                title: product.title,
                description: product.description,
                price: product.price,
                currency: product.currency,
                deliveryEstimate: product.deliveryEstimate
            )

            let cartVC = MonkeyCartViewController(cartItem: cartItem)
            self.navigationController?.pushViewController(cartVC, animated: true)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension MonkeyFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
