import Foundation
import Combine
import SwiftUI

// MARK: - Spiders View Model
@MainActor
class SpidersViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let serviceContainer: ServiceContainerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var userSpiders: [Spider] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddSpider = false
    @Published var selectedSpider: Spider?
    
    // MARK: - Computed Properties
    var totalSpiders: Int {
        userSpiders.count
    }
    
    var activeSpiders: Int {
        userSpiders.filter { $0.isActive }.count
    }
    
    var averageDeadlinessScore: Double {
        guard !userSpiders.isEmpty else { return 0.0 }
        let total = userSpiders.reduce(0.0) { $0 + ($1.deadlinessScore ?? 0.0) }
        return total / Double(userSpiders.count)
    }
    
    var hasSpiders: Bool {
        !userSpiders.isEmpty
    }
    
    // MARK: - Initializer
    init(serviceContainer: ServiceContainerProtocol = ServiceContainer.shared) {
        self.serviceContainer = serviceContainer
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // For now, we'll load data on demand
        // TODO: Implement real-time listeners when we add them to repositories
    }
    
    // MARK: - Public Methods
    
    /// Load user's spider collection
    func loadSpiders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let spiders = try await serviceContainer.spiderRepository
                .getUserSpiders(userId: getCurrentUserId())
            
            await MainActor.run {
                self.userSpiders = spiders
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load spiders: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Refresh spider collection
    func refreshSpiders() async {
        await loadSpiders()
    }
    
    /// Show add spider sheet
    func showAddSpider() {
        showingAddSpider = true
    }
    
    /// Hide add spider sheet
    func hideAddSpider() {
        showingAddSpider = false
    }
    
    /// Select a spider for detailed view
    func selectSpider(_ spider: Spider) {
        selectedSpider = spider
    }
    
    /// Clear selected spider
    func clearSelectedSpider() {
        selectedSpider = nil
    }
    
    /// Delete a spider
    func deleteSpider(_ spider: Spider) async {
        do {
            try await serviceContainer.spiderRepository.deleteSpider(id: spider.id)
            
            // Remove from local array
            await MainActor.run {
                self.userSpiders.removeAll { $0.id == spider.id }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete spider: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update spider status (active/inactive)
    func updateSpiderStatus(_ spider: Spider, isActive: Bool) async {
        do {
            // Create a new spider object with updated isActive status
            var updatedSpider = spider
            updatedSpider.isActive = isActive
            
            try await serviceContainer.spiderRepository.updateSpider(updatedSpider)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update spider status: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get spider statistics
    func getSpiderStatistics() -> SpiderStatistics {
        let totalScore = userSpiders.reduce(0.0) { $0 + ($1.deadlinessScore ?? 0.0) }
        let highestScore = userSpiders.compactMap { $0.deadlinessScore }.max() ?? 0.0
        let lowestScore = userSpiders.compactMap { $0.deadlinessScore }.min() ?? 0.0
        
        return SpiderStatistics(
            totalSpiders: totalSpiders,
            activeSpiders: activeSpiders,
            averageScore: averageDeadlinessScore,
            highestScore: highestScore,
            lowestScore: lowestScore,
            totalScore: totalScore
        )
    }
    
    /// Check if spider can be used in fights
    func canUseSpiderInFight(_ spider: Spider) -> Bool {
        return spider.canBeUsedInFight
    }
    
    /// Get spiders available for fighting
    var availableFightSpiders: [Spider] {
        userSpiders.filter { canUseSpiderInFight($0) }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
    }
}

// MARK: - Spider Statistics
struct SpiderStatistics {
    let totalSpiders: Int
    let activeSpiders: Int
    let averageScore: Double
    let highestScore: Double
    let lowestScore: Double
    let totalScore: Double
    
    var hasSpiders: Bool {
        totalSpiders > 0
    }
    
    var activePercentage: Double {
        guard totalSpiders > 0 else { return 0.0 }
        return (Double(activeSpiders) / Double(totalSpiders)) * 100.0
    }
}
