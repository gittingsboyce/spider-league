import Foundation
import Combine
import SwiftUI

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let serviceContainer: ServiceContainerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var user: SpiderLeagueUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingEditProfile = false
    @Published var showingSettings = false
    
    // MARK: - Computed Properties
    var hasUser: Bool {
        user != nil
    }
    
    var userDisplayName: String {
        user?.fightName ?? "Unknown Fighter"
    }
    
    var userEmail: String {
        user?.email ?? "No email"
    }
    
    var userTown: String {
        user?.town ?? "No location"
    }
    
    var userStatus: UserStatus {
        user?.status ?? .notReady
    }
    
    var isReadyToFight: Bool {
        user?.isReadyToFight ?? false
    }
    
    var fightRecord: FightRecord {
        let wins = user?.wins ?? 0
        let losses = user?.losses ?? 0
        let totalFights = wins + losses
        let winPercentage = totalFights > 0 ? (Double(wins) / Double(totalFights)) * 100.0 : 0.0
        
        return FightRecord(
            wins: wins,
            losses: losses,
            totalFights: totalFights,
            winPercentage: winPercentage
        )
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
    
    /// Load user profile
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUser = try await serviceContainer.userRepository
                .getCurrentUser()
            
            await MainActor.run {
                self.user = currentUser
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Refresh profile data
    func refreshProfile() async {
        await loadProfile()
    }
    
    /// Toggle user's fight status
    func toggleFightStatus() async {
        guard let currentUser = user else {
            errorMessage = "No user profile found"
            return
        }
        
        do {
            let newStatus: UserStatus = currentUser.isReadyToFight ? .notReady : .ready
            try await serviceContainer.userRepository.updateUserStatus(
                userId: currentUser.id,
                status: newStatus
            )
            
            // The binding will automatically update the user status
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update status: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update user's fight name
    func updateFightName(_ newName: String) async {
        guard let currentUser = user else {
            errorMessage = "No user profile found"
            return
        }
        
        do {
            try await serviceContainer.userRepository.updateUserFightName(
                userId: currentUser.id,
                fightName: newName
            )
            
            // The binding will automatically update the user
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update fight name: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update user's town
    func updateTown(_ newTown: String) async {
        guard let currentUser = user else {
            errorMessage = "No user profile found"
            return
        }
        
        do {
            try await serviceContainer.userRepository.updateUserTown(
                userId: currentUser.id,
                town: newTown
            )
            
            // The binding will automatically update the user
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update town: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update profile image
    func updateProfileImage(_ imageUrl: String) async {
        guard let currentUser = user else {
            errorMessage = "No user profile found"
            return
        }
        
        do {
            try await serviceContainer.userRepository.updateUserProfileImage(
                userId: currentUser.id,
                imageUrl: imageUrl
            )
            
            // The binding will automatically update the user
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update profile image: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get user statistics
    func getUserStatistics() -> UserStatistics {
        let record = fightRecord
        let daysSinceCreation = user?.daysSinceCreation ?? 0
        let lastActiveDays = user?.daysSinceLastActive ?? 0
        
        return UserStatistics(
            fightRecord: record,
            daysSinceCreation: daysSinceCreation,
            lastActiveDays: lastActiveDays,
            isEmailVerified: user?.isEmailVerified ?? false,
            status: userStatus
        )
    }
    
    /// Show edit profile sheet
    func showEditProfile() {
        showingEditProfile = true
    }
    
    /// Hide edit profile sheet
    func hideEditProfile() {
        showingEditProfile = false
    }
    
    /// Show settings sheet
    func showSettings() {
        showingSettings = true
    }
    
    /// Hide settings sheet
    func hideSettings() {
        showingSettings = false
    }
    
    /// Sign out user
    func signOut() async {
        // TODO: Implement sign out logic
        // This would typically involve:
        // 1. Signing out from Firebase Auth
        // 2. Clearing local data
        // 3. Navigating to login screen
        
        await MainActor.run {
            self.errorMessage = "Sign out functionality not yet implemented"
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
    }
}

// MARK: - Fight Record
struct FightRecord {
    let wins: Int
    let losses: Int
    let totalFights: Int
    let winPercentage: Double
    
    var hasFights: Bool {
        totalFights > 0
    }
    
    var isWinning: Bool {
        winPercentage > 50.0
    }
    
    var winLossRatio: Double {
        guard losses > 0 else { return Double(wins) }
        return Double(wins) / Double(losses)
    }
}

// MARK: - User Statistics
struct UserStatistics {
    let fightRecord: FightRecord
    let daysSinceCreation: Int
    let lastActiveDays: Int
    let isEmailVerified: Bool
    let status: UserStatus
    
    var isNewUser: Bool {
        daysSinceCreation < 7
    }
    
    var isActiveUser: Bool {
        lastActiveDays < 3
    }
    
    var accountAge: String {
        if daysSinceCreation < 1 {
            return "Less than a day"
        } else if daysSinceCreation < 7 {
            return "\(daysSinceCreation) days"
        } else if daysSinceCreation < 30 {
            let weeks = daysSinceCreation / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = daysSinceCreation / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
}
