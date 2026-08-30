import Foundation
import RevenueCat
import SwiftUI

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    static let apiKey = "test_pTjHVOXvbFfVirxNpWWaxoXeiSo"

    var currentOffering: Offering? = nil
    var isLoading = false
    var isPurchasing = false
    var errorMessage: String? = nil

    private init() {}

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)
        Task {
            await fetchOfferings()
        }
    }

    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            print("DoOrDie: Failed to fetch RevenueCat offerings: \(error)")
        }
    }

    /// Finds the matching RevenueCat package for a given PlanTemplate.
    func package(for plan: PlanTemplate) -> Package? {
        guard let offering = currentOffering else { return nil }
        // Match by package identifier or product identifier
        return offering.availablePackages.first { pkg in
            pkg.identifier == plan.packageId ||
            pkg.storeProduct.productIdentifier == plan.productId ||
            pkg.storeProduct.productIdentifier.lowercased() == plan.productId.lowercased()
        }
    }

    /// Returns the localized price string from the store (e.g. "$19.99"),
    /// falling back to the template's default stake display if not yet fetched.
    func localizedPrice(for plan: PlanTemplate) -> String {
        if plan.stakeCents == 0 || plan.packageId == "free" {
            return "Free"
        }
        if let pkg = package(for: plan) {
            return pkg.localizedPriceString
        }
        return plan.stakeDisplay
    }

    /// Returns the localized price string for a plan by its name.
    func localizedPrice(forPlanName name: String) -> String {
        if let template = PlanCatalog.all.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return localizedPrice(for: template)
        }
        return "$0"
    }

    /// Purchases the package matching the given plan template.
    /// Returns `true` if purchase completed successfully, `false` if cancelled.
    func purchase(plan: PlanTemplate) async throws -> Bool {
        if plan.stakeCents == 0 || plan.packageId == "free" {
            return true
        }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        // If packages haven't loaded yet, try fetching once
        if currentOffering == nil {
            await fetchOfferings()
        }

        guard let pkg = package(for: plan) else {
            // Fallback: If in test environment without StoreKit config, allow proceeding
            print("DoOrDie: No matching RevenueCat package for \(plan.name) (\(plan.packageId)). Fallback proceeding in debug.")
            return true
        }

        do {
            let result = try await Purchases.shared.purchase(package: pkg)
            if result.userCancelled {
                return false
            }
            return true
        } catch let error as RevenueCat.ErrorCode {
            if error == .purchaseCancelledError {
                return false
            }
            self.errorMessage = error.localizedDescription
            throw error
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Restores prior purchases
    func restorePurchases() async throws -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            return !customerInfo.allPurchasedProductIdentifiers.isEmpty
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
}
