import Foundation
import FirebaseFirestore
import Combine

// MARK: - Firebase Service Protocol
protocol FirebaseServiceProtocol {
    
    // MARK: - User Operations
    func createUser(_ user: SpiderLeagueUser) async throws -> SpiderLeagueUser
    func getUser(id: String) async throws -> SpiderLeagueUser?
    func getCurrentUser() async throws -> SpiderLeagueUser?
    func updateUser(_ user: SpiderLeagueUser) async throws -> SpiderLeagueUser
    func deleteUser(id: String) async throws
    func getUsersByStatus(_ status: UserStatus, inTown town: String) async throws -> [SpiderLeagueUser]
    func updateUserStatus(userId: String, status: UserStatus) async throws
    func updateUserFightRecord(userId: String, wins: Int, losses: Int) async throws
    func searchUsersByFightName(_ fightName: String) async throws -> [SpiderLeagueUser]
    func getTopUsersByWins(limit: Int) async throws -> [SpiderLeagueUser]
    func getTopUsersByWinPercentage(limit: Int) async throws -> [SpiderLeagueUser]
    
    // MARK: - Spider Operations
    func createSpider(_ spider: Spider) async throws -> Spider
    func getSpider(id: String) async throws -> Spider?
    func updateSpider(_ spider: Spider) async throws -> Spider
    func deleteSpider(id: String) async throws
    func getUserSpiders(userId: String) async throws -> [Spider]
    func getSpiderById(id: String) async throws -> Spider?
    func updateSpiderLastUsed(spiderId: String) async throws
    func updateSpiderImageMetadata(spiderId: String, metadata: ImageMetadata) async throws
    func checkUserSpiderCooldown(userId: String) async throws -> Bool
    func getSpiderBySpecies(species: String) async throws -> [Spider]
    
    // MARK: - Challenge Operations
    func createChallenge(_ challenge: Challenge) async throws -> Challenge
    func getChallenge(id: String) async throws -> Challenge?
    func updateChallenge(_ challenge: Challenge) async throws -> Challenge
    func deleteChallenge(id: String) async throws
    func getUserChallenges(userId: String) async throws -> [Challenge]
    func getUserReceivedChallenges(userId: String) async throws -> [Challenge]
    func getUserSentChallenges(userId: String) async throws -> [Challenge]
    func acceptChallenge(_ challenge: Challenge, challengedSpiderId: String) async throws -> Challenge
    func declineChallenge(_ challenge: Challenge) async throws -> Challenge
    func updateChallengeStatus(challengeId: String, status: ChallengeStatus) async throws
    func expireChallenge(_ challenge: Challenge) async throws -> Challenge
    func getExpiredChallenges() async throws -> [Challenge]
    
    // MARK: - Fight Operations
    func createFight(_ fight: Fight) async throws -> Fight
    func getFight(id: String) async throws -> Fight?
    func getUserFightHistory(userId: String) async throws -> [Fight]
    func getUserWins(userId: String) async throws -> [Fight]
    func getUserLosses(userId: String) async throws -> [Fight]
    func getFightsByChallenge(challengeId: String) async throws -> [Fight]
    
    // MARK: - Utility Operations
    func isConnected() -> Bool
    func listenForUserChanges(userId: String) -> AnyPublisher<SpiderLeagueUser, Never>
    func listenForSpiderChanges(spiderId: String) -> AnyPublisher<Spider, Never>
    func listenForChallengeChanges(challengeId: String) -> AnyPublisher<Challenge, Never>
    func listenForUserChallenges(userId: String) -> AnyPublisher<[Challenge], Never>
}


