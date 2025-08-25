import Foundation
import Combine
import SwiftUI

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let serviceContainer: ServiceContainerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var isReadyToFight = false
    @Published var recentChallenges: [Challenge] = []
    @Published var recentFights: [Fight] = []
    @Published var readyToFightUsers: [SpiderLeagueUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var hasRecentActivity: Bool {
        !recentChallenges.isEmpty || !recentFights.isEmpty
    }
    
    var hasReadyOpponents: Bool {
        !readyToFightUsers.isEmpty
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
    
    /// Load all data for the home screen
    func loadHomeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load data concurrently
            async let challenges = loadRecentChallenges()
            async let fights = loadRecentFights()
            async let readyUsers = loadReadyToFightUsers()
            
            // Wait for all to complete
            let (challengesResult, fightsResult, readyUsersResult) = await (challenges, fights, readyUsers)
            
            // Update UI on main thread
            await MainActor.run {
                self.recentChallenges = challengesResult
                self.recentFights = fightsResult
                self.readyToFightUsers = readyUsersResult
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Toggle user's fight status
    func toggleFightStatus() async {
        do {
            guard let currentUser = try await serviceContainer.userRepository.getCurrentUser() else {
                throw FirebaseServiceError.userNotFound
            }
            
            let newStatus: UserStatus = currentUser.isReadyToFight ? .notReady : .ready
            try await serviceContainer.userRepository.updateUserStatus(userId: currentUser.id, status: newStatus)
            
            // Update local state
            await MainActor.run {
                self.isReadyToFight = newStatus == .ready
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update status: \(error.localizedDescription)"
            }
        }
    }
    
    /// Refresh all data
    func refreshData() async {
        await loadHomeData()
    }
    
    // MARK: - Private Methods
    
    private func loadRecentChallenges() async -> [Challenge] {
        do {
            let challenges = try await serviceContainer.challengeRepository
                .getUserChallenges(userId: getCurrentUserId())
            
            // Filter for recent challenges and sort by creation date
            return challenges
                .filter { !$0.isExpired }
                .sorted(by: { $0.createdAt > $1.createdAt })
                .prefix(5)
                .map { $0 }
                
        } catch {
            print("Failed to load recent challenges: \(error)")
            return []
        }
    }
    
    private func loadRecentFights() async -> [Fight] {
        do {
            let fights = try await serviceContainer.fightRepository
                .getUserFightHistory(userId: getCurrentUserId())
            
            // Sort by fight completion date and take most recent
            return fights
                .sorted(by: { $0.completedAt > $1.completedAt })
                .prefix(5)
                .map { $0 }
            
        } catch {
            print("Failed to load recent fights: \(error)")
            return []
        }
    }
    
    private func loadReadyToFightUsers() async -> [SpiderLeagueUser] {
        do {
            let users = try await serviceContainer.userRepository
                .getUsersByStatus(.ready)
            
            // Filter out current user and sort by last active
            return users
                .filter { $0.id != getCurrentUserId() }
                .sorted(by: { $0.lastActive > $1.lastActive })
                .prefix(10)
                .map { $0 }
                
        } catch {
            print("Failed to load ready users: \(error)")
            return []
        }
    }
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
    }
}


