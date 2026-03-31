import StoreKit
import Observation

@Observable
final class PurchaseManager {
    static let productID = "pacepal_premium"

    private(set) var product: Product?
    private(set) var isPremium   = false
    private(set) var isLoading   = true
    private(set) var isPurchasing = false
    private(set) var isRestoring  = false
    private(set) var purchaseError: String?

    private var updateListener: Task<Void, Never>?

    init() {
        updateListener = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result { await tx.finish() }
                await self?.refreshStatus()
            }
        }
        Task { await bootstrap() }
    }

    deinit { updateListener?.cancel() }

    // MARK: - Public

    /// Formatted price string from App Store (e.g. "$49.00", "MX$49.00")
    var displayPrice: String { product?.displayPrice ?? "—" }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await refreshStatus()
                }
            case .userCancelled:
                break
            default:
                purchaseError = "No se pudo completar la compra."
            }
        } catch {
            purchaseError = "Ocurrió un error. Inténtalo de nuevo."
        }
    }

    func restore() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshStatus()
            if !isPremium {
                purchaseError = "No encontramos una suscripción activa."
            }
        } catch {
            purchaseError = "No se pudo restaurar la compra."
        }
    }

    func refreshStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == Self.productID,
                  tx.revocationDate == nil else { continue }
            active = true
        }
        isPremium = active
    }

    // MARK: - Private

    private func bootstrap() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProduct() }
            group.addTask { await self.refreshStatus() }
        }
        isLoading = false
    }

    private func loadProduct() async {
        guard let p = try? await Product.products(for: [Self.productID]).first else { return }
        product = p
    }
}
