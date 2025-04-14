//
//  ProductCardCell.swift
//  MonkeyMerchant
//
//  Created by Nirman Kalia on 13/04/25.
//

import Foundation
import UIKit
final class ProductCardCell: UITableViewCell {

    static let reuseId = "ProductCardCell"

    var onBuyTapped: (() -> Void)?

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let rootStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let rightStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let productImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.layer.cornerRadius = 8
        img.clipsToBounds = true
        img.widthAnchor.constraint(equalToConstant: 120).isActive = true
//        img.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return img
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGreen
        return label
    }()

    private let buyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Buy", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 6
        return button
    }()

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        self.contentView.backgroundColor = .secondarySystemBackground
        self.backgroundColor = .secondarySystemBackground
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)

        contentView.addSubview(cardView)
        cardView.addSubview(rootStackView)
        
        rootStackView.addArrangedSubview(productImageView)
        rootStackView.addArrangedSubview(rightStackView)
        
        rightStackView.addArrangedSubview(titleLabel)
        rightStackView.addArrangedSubview(descriptionLabel)
        rightStackView.addArrangedSubview(priceLabel)
        rightStackView.addArrangedSubview(buyButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            rootStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            rootStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            rootStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            rootStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            buyButton.heightAnchor.constraint(equalToConstant: 36),
            buyButton.widthAnchor.constraint(equalToConstant: 72)
        ])
    }

    func configure(with product: ProductModel) {
        productImageView.image = product.image
        titleLabel.text = product.title
        descriptionLabel.text = product.description
        priceLabel.text = "\(product.currency) \(String(format: "%.2f", product.price))"
    }

    @objc private func buyTapped() {
        onBuyTapped?()
    }
}
