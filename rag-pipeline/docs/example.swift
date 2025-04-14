import UIKit
import Razorpay

// This is a simple example of how to use the Razorpay SDK to create a checkout flow.
// Understand it to derive an customised solution for the input.
// MARK: - Models

struct CartItemModel {
    let productImage: UIImage?
    let title: String
    let description: String
    let price: Double
    let currency: String
    let deliveryEstimate: String
}

struct UserModel {
    let customerId: String
    let name: String
    let email: String
    let contact: String
}

struct PaymentRequest {
    let orderId: String
    let amount: Int
    let currency: String
    let keyId: String
    let contact: String
    let email: String
    let name: String
    let description: String
    let imageURL: String
}

// MARK: - Razorpay SDK Wrapper

protocol PaymentResultDelegate: AnyObject {
    func paymentDidSucceed(paymentId: String)
    func paymentDidFail(errorCode: Int32, description: String)
}

final class RazorpayPaymentService: NSObject {

    private var razorpay: RazorpayCheckout?
    private weak var presentingController: UIViewController?
    private weak var delegate: PaymentResultDelegate?

    func startPayment(from controller: UIViewController,
                      request: PaymentRequest,
                      delegate: PaymentResultDelegate) {
        self.presentingController = controller
        self.delegate = delegate

        razorpay = RazorpayCheckout.initWithKey(request.keyId, andDelegate: self)

        let options: [String: Any] = [
            "key": request.keyId,
            "amount": request.amount,
            "currency": request.currency,
            "description": request.description,
            "order_id": request.orderId,
            "image": request.imageURL,
            "name": request.name,
            "prefill": [
                "contact": request.contact,
                "email": request.email
            ],
            "theme": [
                "color": "#F37254"
            ]
        ]

        razorpay?.open(options, displayController: controller)
    }
}

extension RazorpayPaymentService: RazorpayPaymentCompletionProtocol {
    func onPaymentSuccess(_ payment_id: String) {
        delegate?.paymentDidSucceed(paymentId: payment_id)
    }

    func onPaymentError(_ code: Int32, description str: String) {
        delegate?.paymentDidFail(errorCode: code, description: str)
    }
}

// MARK: - Checkout ViewController

final class MonkeyCheckoutViewController: UIViewController {

    // MARK: - Injected
    private let cartItem: CartItemModel
    private let user: UserModel
    private let receiptId: String
    private let paymentService = RazorpayPaymentService()

    // MARK: - Configurable Placeholders (Replace during integration)
    private let merchantOrderAPIURL = "<https://your-merchant.com/api/create_order>" // 🔁 Replace this
    private let merchantAuthHeader = "Bearer <YOUR_AUTH_TOKEN>" // 🔁 Replace this
    private let razorpayKeyId = "<RAZORPAY_KEY_ID>" // 🔁 Replace this
    private let logoURL = "<YOUR_LOGO_URL>" // 🔁 Optional

    // MARK: - UI Components
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
        startTurboPaymentFlow()
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

    // MARK: - Payment Flow
    private func startTurboPaymentFlow() {
        loader.startAnimating()
        statusLabel.text = "Creating order..."

        let amountInPaise = Int(cartItem.price * 100)

        createMerchantOrder(
            customerId: user.customerId,
            amount: amountInPaise,
            receipt: receiptId
        ) { [weak self] orderId in
            guard let self = self else { return }

            let request = PaymentRequest(
                orderId: orderId,
                amount: amountInPaise,
                currency: "INR",
                keyId: self.razorpayKeyId,
                contact: self.user.contact,
                email: self.user.email,
                name: self.user.name,
                description: self.cartItem.title,
                imageURL: self.logoURL
            )

            self.statusLabel.text = "Starting payment..."
            self.paymentService.startPayment(from: self, request: request, delegate: self)
        }
    }
    // Order Id will be created by the merchant backend developer need's to coordinate with there backend meam while it can be mocked to run in the meantime.
    private func createMerchantOrder(
        customerId: String,
        amount: Int,
        receipt: String,
        onSuccess: @escaping (_ orderId: String) -> Void
    ) {
        guard let url = URL(string: merchantOrderAPIURL) else {
            updateUIWithFailure("Invalid Merchant API URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(merchantAuthHeader, forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "amount": amount,
            "currency": "INR",
            "customer_id": customerId,
            "receipt": receipt
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.updateUIWithFailure("Order failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let orderId = json["id"] as? String else {
                DispatchQueue.main.async {
                    self.updateUIWithFailure("Failed to parse order ID")
                }
                return
            }

            DispatchQueue.main.async {
                onSuccess(orderId)
            }
        }.resume()
    }

    // MARK: - Feedback UI
    private func updateUIWithFailure(_ message: String) {
        loader.stopAnimating()
        failureImageView.isHidden = false
        statusLabel.text = "❌ \(message)"
        statusLabel.textColor = .systemRed
    }

    private func updateUIWithSuccess(_ paymentId: String) {
        loader.stopAnimating()
        successImageView.isHidden = false
        statusLabel.text = "✅ Payment Successful\nID: \(paymentId)"
        statusLabel.textColor = .systemGreen
    }
}

// MARK: - Razorpay Delegate
extension MonkeyCheckoutViewController: PaymentResultDelegate {
    func paymentDidSucceed(paymentId: String) {
        updateUIWithSuccess(paymentId)
    }

    func paymentDidFail(errorCode: Int32, description: String) {
        updateUIWithFailure("Payment failed [\(errorCode)]: \(description)")
    }
}
