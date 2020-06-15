extension Notification.Name {
    static let didRestorePurchase = Notification.Name("didRestorePurchase")
    static let didBuyProduct = Notification.Name("didBuyProduct")
}
enum IAPProducts: String {
    case forever = "forever"
    case annual = "oneyear"
    case monthly = "monthly"
}

import StoreKit
class IAPManager: NSObject {
    static let shared = IAPManager()
    private override init() {}
    var products: [SKProduct] = []
    var paymentQueue = SKPaymentQueue.default()
    public func setupPurchase(callback: @escaping(Bool) -> ()) {
        if SKPaymentQueue.canMakePayments() {
            paymentQueue.add(self)
            callback(true); return
        }
        callback(false)
    }
    public func getProducts() {
        let identifiers: Set = [
            IAPProducts.forever.rawValue,
            IAPProducts.monthly.rawValue,
            IAPProducts.annual.rawValue]
        let productRequest = SKProductsRequest(productIdentifiers: identifiers)
        productRequest.delegate = self
        productRequest.start()
    }
    public func purchase(productWith identidier: String) {
        guard let product = products.filter({ $0.productIdentifier == identidier }).first else { return }
        let payment = SKPayment(product: product)
        paymentQueue.add(payment)
    }
    fileprivate func postRestoreNotification() {
        NotificationCenter.default.post(name: NSNotification.Name.didRestorePurchase, object: nil)
    }
    fileprivate func postPurchaseNotification() {
        NotificationCenter.default.post(name: NSNotification.Name.didBuyProduct, object: nil)
    }
}
extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .failed: fail(transaction: transaction)
            case .restored:
                postRestoreNotification()
                cleanQueue(transaction: transaction)
                UserDefaults.standard.set(true, forKey: "appPurchased")
            case .purchased:
                postPurchaseNotification()
                UserDefaults.standard.set(true, forKey: "isAppPurchased")
                cleanQueue(transaction: transaction)
            default: break
            }
        }
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction error: \(transactionError.localizedDescription)")
            }
        }
        paymentQueue.finishTransaction(transaction)
    }
    private func cleanQueue(transaction: SKPaymentTransaction) {
        paymentQueue.finishTransaction(transaction)
    }
}
extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        products.forEach { print($0.localizedTitle) }
    }
}
