//
//  PaymentViewController.swift
//  MonkeyMerchant
//
//  Created by Nirman Kalia on 13/04/25.
//

import UIKit

struct CartItemModel {
    let productImage: UIImage?
    let title: String
    let description: String
    let price: Double
    let currency: String
    let deliveryEstimate: String
}

class MonkeyCartViewController: UIViewController {
    
    // MARK: - Injected Model
    private let cartItem: CartItemModel
    
    // MARK: - Init
    init(cartItem: CartItemModel) {
        self.cartItem = cartItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components
    private lazy var imageView: UIImageView = {
        let img = UIImageView(image: cartItem.productImage)
        img.contentMode = .scaleAspectFit
        img.layer.cornerRadius = 10
        img.clipsToBounds = true
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = cartItem.title
        label.font = .boldSystemFont(ofSize: 18)
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = cartItem.description
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.text = "\(cartItem.currency)\(String(format: "%.2f", cartItem.price))"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .systemGreen
        return label
    }()
    
    private lazy var deliveryLabel: UILabel = {
        let label = UILabel()
        label.text = cartItem.deliveryEstimate
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue to Payment", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            descriptionLabel,
            priceLabel,
            deliveryLabel,
            continueButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Your Order"
        view.backgroundColor = .systemBackground
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 180),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }
    
    // MARK: - Actions
    @objc private func continueTapped() {
        
        let checkoutVC = MonkeyCheckoutViewController(cartItem: cartItem, user: user)
        // Pass details from cartItem as needed to checkoutVC
        navigationController?.pushViewController(checkoutVC, animated: true)
    }
}
