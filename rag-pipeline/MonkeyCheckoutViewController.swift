import UIKit

final class MonkeyCheckoutViewController: UIViewController {

    // MARK: - Injected
    private let cartItem: CartItemModel
    private let user: UserModel
    private let receiptId: String 
    
    // MARK: - UI
    private lazy var loader: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Initiating checkout..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var successImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.tintColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var failureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "xmark.octagon.fill"))
        imageView.tintColor = .systemRed
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Init
    init(cartItem: CartItemModel, user: UserModel, receiptId: String = UUID().uuidString) {
        self.cartItem = cartItem
        self.user = user
        self.receiptId = receiptId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checkout"
        view.backgroundColor = .systemBackground
        setupUI()
        simulatePaymentFlow()
    }

    private func setupUI() {
        view.addSubview(loader)
        view.addSubview(statusLabel)
        view.addSubview(successImageView)
        view.addSubview(failureImageView)

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: loader.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            successImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            successImageView.widthAnchor.constraint(equalToConstant: 60),
            successImageView.heightAnchor.constraint(equalToConstant: 60),

            failureImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            failureImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            failureImageView.widthAnchor.constraint(equalToConstant: 60),
            failureImageView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    // MARK: - Simulation Logic
    private func simulatePaymentFlow() {
        loader.startAnimating()
        statusLabel.text = "Contacting payment service..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loader.stopAnimating()

            let simulatedSuccess = Bool.random()
            if simulatedSuccess {
                self.showSuccessUI()
            } else {
                self.showFailureUI()
            }
        }
    }

    private func showSuccessUI() {
        successImageView.isHidden = false
        statusLabel.text = "✅ Payment Successful\nThank you, \(user.name)!"
        statusLabel.textColor = .systemGreen
    }

    private func showFailureUI() {
        failureImageView.isHidden = false
        statusLabel.text = "❌ Payment Failed\nPlease try again later."
        statusLabel.textColor = .systemRed
    }
}
