import Foundation
import Combine
import SwiftUI

// MARK: - Challenges View Model
@MainActor
class ChallengesViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let serviceContainer: ServiceContainerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var receivedChallenges: [Challenge] = []
    @Published var sentChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab = 0
    
    // MARK: - Computed Properties
    var hasReceivedChallenges: Bool {
        !receivedChallenges.isEmpty
    }
    
    var hasSentChallenges: Bool {
        !sentChallenges.isEmpty
    }
    
    var pendingChallenges: [Challenge] {
        receivedChallenges.filter { $0.status == .pending && !$0.isExpired }
    }
    
    var expiredChallenges: [Challenge] {
        receivedChallenges.filter { $0.isExpired }
    }
    
    var activeChallenges: [Challenge] {
        receivedChallenges.filter { $0.status == .accepted }
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
    
    /// Load all challenges
    func loadChallenges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allChallenges = try await serviceContainer.challengeRepository
                .getUserChallenges(userId: getCurrentUserId())
            
            // Separate into received and sent challenges
            let userId = getCurrentUserId()
            let received = allChallenges.filter { $0.challengedId == userId }
            let sent = allChallenges.filter { $0.challengerId == userId }
            
            await MainActor.run {
                self.receivedChallenges = received
                self.sentChallenges = sent
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Refresh challenges
    func refreshChallenges() async {
        await loadChallenges()
    }
    
    /// Accept a challenge
    func acceptChallenge(_ challenge: Challenge, withSpiderId spiderId: String) async {
        do {
            try await serviceContainer.challengeRepository.acceptChallenge(challenge, challengedSpiderId: spiderId)
            
            // The binding will automatically update the challenge status
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to accept challenge: \(error.localizedDescription)"
            }
        }
    }
    
    /// Decline a challenge
    func declineChallenge(_ challenge: Challenge) async {
        do {
            try await serviceContainer.challengeRepository.declineChallenge(challenge)
            
            // The binding will automatically update the challenge status
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to decline challenge: \(error.localizedDescription)"
            }
        }
    }
    
    /// Send a new challenge
    func sendChallenge(to userId: String, spiderId: String, message: String? = nil) async {
        do {
            let challenge = Challenge(
                challengerId: getCurrentUserId(),
                challengedId: userId,
                challengerSpiderId: spiderId,
                message: message
            )
            
            try await serviceContainer.challengeRepository.createChallenge(challenge)
            
            // The binding will automatically add the new challenge
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send challenge: \(error.localizedDescription)"
            }
        }
    }
    
    /// Cancel a sent challenge
    func cancelChallenge(_ challenge: Challenge) async {
        do {
            try await serviceContainer.challengeRepository.deleteChallenge(id: challenge.id)
            
            // The binding will automatically remove the challenge
            // Show success message
            await MainActor.run {
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to cancel challenge: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get challenge statistics
    func getChallengeStatistics() -> ChallengeStatistics {
        let totalReceived = receivedChallenges.count
        let totalSent = sentChallenges.count
        let pendingCount = pendingChallenges.count
        let acceptedCount = activeChallenges.count
        let declinedCount = receivedChallenges.filter { $0.status == .declined }.count
        let expiredCount = expiredChallenges.count
        
        return ChallengeStatistics(
            totalReceived: totalReceived,
            totalSent: totalSent,
            pending: pendingCount,
            accepted: acceptedCount,
            declined: declinedCount,
            expired: expiredCount
        )
    }
    
    /// Check if user can send challenges
    var canSendChallenges: Bool {
        // TODO: Add logic to check if user has active spiders
        // and isn't on cooldown
        return true
    }
    
    /// Get challenges that need attention
    var challengesNeedingAttention: [Challenge] {
        receivedChallenges.filter { challenge in
            challenge.status == .pending && !challenge.isExpired
        }
    }
    
    /// Get expired challenges count
    var expiredChallengesCount: Int {
        expiredChallenges.count
    }
    
    // MARK: - Private Methods
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
    }
}

// MARK: - Challenge Statistics
struct ChallengeStatistics {
    let totalReceived: Int
    let totalSent: Int
    let pending: Int
    let accepted: Int
    let declined: Int
    let expired: Int
    
    var totalChallenges: Int {
        totalReceived + totalSent
    }
    
    var responseRate: Double {
        guard totalReceived > 0 else { return 0.0 }
        let responded = accepted + declined
        return (Double(responded) / Double(totalReceived)) * 100.0
    }
    
    var acceptanceRate: Double {
        guard totalReceived > 0 else { return 0.0 }
        return (Double(accepted) / Double(totalReceived)) * 100.0
    }
}
