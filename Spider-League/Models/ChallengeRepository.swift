import Foundation
import FirebaseFirestore
import Combine

// MARK: - Challenge Repository
class ChallengeRepository: BaseRepository {
    
    // MARK: - Properties
    private let collection = Collection.challenges
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
}

// MARK: - Challenge CRUD Operations
extension ChallengeRepository {
    
    // MARK: - Create Challenge
    func createChallenge(_ challenge: Challenge) async throws -> Challenge {
        do {
            let documentId = try await createDocument(challenge, withId: challenge.id, in: collection)
            var createdChallenge = challenge
            // Note: The challenge.id is already set, so we don't need to update it
            return createdChallenge
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Challenge by ID
    func getChallenge(id: String) async throws -> Challenge? {
        do {
            return try await readDocument(Challenge.self, withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Challenge
    func updateChallenge(_ challenge: Challenge) async throws -> Challenge {
        do {
            try await updateDocument(challenge, withId: challenge.id, in: collection)
            return challenge
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete Challenge
    func deleteChallenge(id: String) async throws {
        do {
            try await deleteDocument(withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Challenge Query Operations
extension ChallengeRepository {
    
    // MARK: - Get User's Challenges (All)
    func getUserChallenges(userId: String) async throws -> [Challenge] {
        do {
            let options = FirebaseQueryOptions(
                orderBy: "createdAt",
                orderDirection: true // descending (newest first)
            )
            
            let allChallenges = try await queryDocuments(Challenge.self, in: collection, withOptions: options)
            
            // Filter for challenges where user is either challenger or challenged
            return allChallenges.filter { $0.challengerId == userId || $0.challengedId == userId }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Received Challenges
    func getUserReceivedChallenges(userId: String) async throws -> [Challenge] {
        do {
            return try await queryDocuments(Challenge.self, in: collection, where: "challengedId", isEqualTo: userId)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Sent Challenges
    func getUserSentChallenges(userId: String) async throws -> [Challenge] {
        do {
            return try await queryDocuments(Challenge.self, in: collection, where: "challengerId", isEqualTo: userId)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Active Challenges
    func getActiveChallenges(userId: String) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            return userChallenges.filter { $0.isPending }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Pending Challenges
    func getPendingChallenges(userId: String) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            return userChallenges.filter { $0.status == .pending }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Completed Challenges
    func getCompletedChallenges(userId: String) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            return userChallenges.filter { $0.status.isCompleted }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Challenges by Status
    func getChallengesByStatus(_ status: ChallengeStatus, userId: String) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            return userChallenges.filter { $0.status == status }
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Challenge Status Operations
extension ChallengeRepository {
    
    // MARK: - Accept Challenge
    func acceptChallenge(_ challenge: Challenge, challengedSpiderId: String) async throws -> Challenge {
        do {
            var updatedChallenge = challenge
            updatedChallenge.status = .accepted
            updatedChallenge.acceptedAt = Date()
            
            try await updateChallenge(updatedChallenge)
            return updatedChallenge
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Decline Challenge
    func declineChallenge(_ challenge: Challenge) async throws -> Challenge {
        do {
            var updatedChallenge = challenge
            updatedChallenge.status = .declined
            updatedChallenge.declinedAt = Date()
            
            try await updateChallenge(updatedChallenge)
            return updatedChallenge
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Expire Challenge
    func expireChallenge(_ challenge: Challenge) async throws -> Challenge {
        do {
            var updatedChallenge = challenge
            updatedChallenge.status = .expired
            
            try await updateChallenge(updatedChallenge)
            return updatedChallenge
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Challenge Status
    func updateChallengeStatus(challengeId: String, status: ChallengeStatus) async throws {
        do {
            var fields: [String: Any] = [
                "status": status.rawValue
            ]
            
            // Add timestamp based on status
            switch status {
            case .accepted:
                fields["acceptedAt"] = Timestamp(date: Date())
            case .declined:
                fields["declinedAt"] = Timestamp(date: Date())
            case .expired, .pending:
                break // No additional timestamp needed
            }
            
            try await updateDocumentFields(fields, withId: challengeId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Challenge Expiration Management
extension ChallengeRepository {
    
    // MARK: - Get Expired Challenges
    func getExpiredChallenges() async throws -> [Challenge] {
        do {
            let allChallenges = try await queryDocuments(Challenge.self, in: collection, withOptions: FirebaseQueryOptions.default)
            return allChallenges.filter { $0.isExpired && $0.status == .pending }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Check Challenge Expiration
    func checkChallengeExpiration(challengeId: String) async throws -> Bool {
        do {
            guard let challenge = try await getChallenge(id: challengeId) else {
                throw FirebaseServiceError.challengeNotFound
            }
            
            return challenge.isExpired
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Expiring Soon Challenges
    func getExpiringSoonChallenges(userId: String, withinHours hours: Int = 2) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            let now = Date()
            let threshold = Calendar.current.date(byAdding: .hour, value: hours, to: now) ?? now
            
            return userChallenges.filter { challenge in
                challenge.status == .pending && 
                challenge.expiresAt <= threshold &&
                challenge.expiresAt > now
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Auto-expire Challenges
    func autoExpireChallenges() async throws -> Int {
        do {
            let expiredChallenges = try await getExpiredChallenges()
            var expiredCount = 0
            
            for challenge in expiredChallenges {
                try await expireChallenge(challenge)
                expiredCount += 1
            }
            
            return expiredCount
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Challenge Validation Operations
extension ChallengeRepository {
    
    // MARK: - Validate Challenge Creation
    func validateChallengeCreation(challengerId: String, challengedId: String, challengerSpiderId: String) async throws -> Bool {
        do {
            // Check if users exist and are different
            guard challengerId != challengedId else {
                throw FirebaseServiceError.invalidData
            }
            
            // Check if challenger has the spider they want to use
            // Note: This would require access to SpiderRepository
            // For now, we'll assume the spider exists
            
            // Check if challenged user is ready to fight
            // Note: This would require access to UserRepository
            // For now, we'll assume they are ready
            
            // Check if there's already a pending challenge between these users
            let existingChallenges = try await queryDocuments(Challenge.self, in: collection, where: "challengerId", isEqualTo: challengerId)
            
            let hasPendingChallenge = existingChallenges.contains { challenge in
                challenge.challengedId == challengedId && 
                challenge.status == .pending &&
                !challenge.isExpired
            }
            
            if hasPendingChallenge {
                throw FirebaseServiceError.invalidData
            }
            
            return true
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Check Challenge Eligibility
    func checkChallengeEligibility(challengerId: String, challengedId: String) async throws -> (canChallenge: Bool, reason: String?) {
        do {
            // Check if users are the same
            if challengerId == challengedId {
                return (canChallenge: false, reason: "Cannot challenge yourself")
            }
            
            // Check if there's already a pending challenge
            let existingChallenges = try await queryDocuments(Challenge.self, in: collection, where: "challengerId", isEqualTo: challengerId)
            
            let hasPendingChallenge = existingChallenges.contains { challenge in
                challenge.challengedId == challengedId && 
                challenge.status == .pending &&
                !challenge.isExpired
            }
            
            if hasPendingChallenge {
                return (canChallenge: false, reason: "Already have a pending challenge with this user")
            }
            
            return (canChallenge: true, reason: nil)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Challenge Statistics Operations
extension ChallengeRepository {
    
    // MARK: - Get User Challenge Statistics
    func getUserChallengeStatistics(userId: String) async throws -> (totalChallenges: Int, sent: Int, received: Int, accepted: Int, declined: Int, expired: Int) {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            
            let sent = userChallenges.filter { $0.challengerId == userId }.count
            let received = userChallenges.filter { $0.challengedId == userId }.count
            let accepted = userChallenges.filter { $0.status == .accepted }.count
            let declined = userChallenges.filter { $0.status == .declined }.count
            let expired = userChallenges.filter { $0.status == .expired }.count
            
            return (
                totalChallenges: userChallenges.count,
                sent: sent,
                received: received,
                accepted: accepted,
                declined: declined,
                expired: expired
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Challenge Success Rate
    func getUserChallengeSuccessRate(userId: String) async throws -> Double {
        do {
            let stats = try await getUserChallengeStatistics(userId: userId)
            
            let totalSent = stats.sent
            let accepted = stats.accepted
            
            guard totalSent > 0 else { return 0.0 }
            
            return Double(accepted) / Double(totalSent) * 100.0
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Recent Challenge Activity
    func getRecentChallengeActivity(userId: String, limit: Int = 10) async throws -> [Challenge] {
        do {
            let userChallenges = try await getUserChallenges(userId: userId)
            
            return userChallenges
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(limit)
                .map { $0 }
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Real-time Listeners
extension ChallengeRepository {
    
    // MARK: - Listen for Challenge Changes
    func listenForChallengeChanges(challengeId: String) -> AnyPublisher<Challenge, Never> {
        return addDocumentListener(Challenge.self, withId: challengeId, in: collection)
    }
    
    // MARK: - Listen for User Challenges
    func listenForUserChallenges(userId: String) -> AnyPublisher<[Challenge], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("challengerId", isEqualTo: userId)
        
        let subject = PassthroughSubject<[Challenge], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to user challenges: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let challenges = try documents.compactMap { document in
                    try document.data(as: Challenge.self)
                }
                subject.send(challenges)
            } catch {
                print("Error decoding challenges: \(error)")
            }
        }
        
        let listenerKey = "user_challenges_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Listen for User Received Challenges
    func listenForUserReceivedChallenges(userId: String) -> AnyPublisher<[Challenge], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("challengedId", isEqualTo: userId)
            .whereField("status", isEqualTo: ChallengeStatus.pending.rawValue)
        
        let subject = PassthroughSubject<[Challenge], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to user received challenges: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let challenges = try documents.compactMap { document in
                    try document.data(as: Challenge.self)
                }
                
                // Filter for non-expired challenges
                let activeChallenges = challenges.filter { !$0.isExpired }
                subject.send(activeChallenges)
            } catch {
                print("Error decoding challenges: \(error)")
            }
        }
        
        let listenerKey = "user_received_challenges_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Listen for Pending Challenges
    func listenForPendingChallenges(userId: String) -> AnyPublisher<[Challenge], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("challengedId", isEqualTo: userId)
            .whereField("status", isEqualTo: ChallengeStatus.pending.rawValue)
        
        let subject = PassthroughSubject<[Challenge], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to pending challenges: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let challenges = try documents.compactMap { document in
                    try document.data(as: Challenge.self)
                }
                
                // Filter for non-expired challenges
                let activeChallenges = challenges.filter { !$0.isExpired }
                subject.send(activeChallenges)
            } catch {
                print("Error decoding challenges: \(error)")
            }
        }
        
        let listenerKey = "pending_challenges_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
}
