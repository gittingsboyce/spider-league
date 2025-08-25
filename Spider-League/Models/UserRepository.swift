import Foundation
import FirebaseFirestore
import Combine

// MARK: - User Repository
class UserRepository: BaseRepository {
    
    // MARK: - Properties
    private let collection = Collection.users
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
}

// MARK: - User CRUD Operations
extension UserRepository {
    
    // MARK: - Create User
    func createUser(_ user: SpiderLeagueUser) async throws -> SpiderLeagueUser {
        do {
            let documentId = try await createDocument(user, withId: user.id, in: collection)
            var createdUser = user
            // Note: The user.id is already set, so we don't need to update it
            return createdUser
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User by ID
    func getUser(id: String) async throws -> SpiderLeagueUser? {
        do {
            return try await readDocument(SpiderLeagueUser.self, withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update User
    func updateUser(_ user: SpiderLeagueUser) async throws -> SpiderLeagueUser {
        do {
            try await updateDocument(user, withId: user.id, in: collection)
            return user
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete User
    func deleteUser(id: String) async throws {
        do {
            try await deleteDocument(withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - User Query Operations
extension UserRepository {
    
    // MARK: - Get Users by Status and Town
    func getUsersByStatus(_ status: UserStatus, inTown town: String) async throws -> [SpiderLeagueUser] {
        do {
            let conditions: [(field: String, operator: QueryFilterOperator, value: Any)] = [
                ("status", .isEqualTo, status.rawValue),
                ("town", .isEqualTo, town)
            ]
            
            return try await queryDocuments(SpiderLeagueUser.self, in: collection, where: conditions)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Users by Status Only
    func getUsersByStatus(_ status: UserStatus) async throws -> [SpiderLeagueUser] {
        do {
            return try await queryDocuments(SpiderLeagueUser.self, in: collection, where: "status", isEqualTo: status.rawValue)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Users by Town
    func getUsersByTown(_ town: String) async throws -> [SpiderLeagueUser] {
        do {
            return try await queryDocuments(SpiderLeagueUser.self, in: collection, where: "town", isEqualTo: town)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Ready to Fight Users
    func getReadyToFightUsers() async throws -> [SpiderLeagueUser] {
        do {
            return try await getUsersByStatus(.ready)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Current User (from Firestore)
    func getCurrentUser() async throws -> SpiderLeagueUser? {
        // TODO: Get current user ID from AuthRepository
        // For now, return nil - this will be implemented when we connect auth
        return nil
    }
    
    // MARK: - Get Ready to Fight Users in Town
    func getReadyToFightUsers(inTown town: String) async throws -> [SpiderLeagueUser] {
        do {
            return try await getUsersByStatus(.ready, inTown: town)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - User Status Operations
extension UserRepository {
    
    // MARK: - Update User Status
    func updateUserStatus(userId: String, status: UserStatus) async throws {
        do {
            let fields: [String: Any] = [
                "status": status.rawValue,
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Set User Ready to Fight
    func setUserReadyToFight(userId: String) async throws {
        try await updateUserStatus(userId: userId, status: .ready)
    }
    
    // MARK: - Set User Not Ready
    func setUserNotReady(userId: String) async throws {
        try await updateUserStatus(userId: userId, status: .notReady)
    }
}

// MARK: - User Fight Record Operations
extension UserRepository {
    
    // MARK: - Update User Fight Record
    func updateUserFightRecord(userId: String, wins: Int, losses: Int) async throws {
        do {
            let fields: [String: Any] = [
                "wins": wins,
                "losses": losses,
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Increment User Wins
    func incrementUserWins(userId: String) async throws {
        do {
            let user = try await getUser(id: userId)
            guard let user = user else {
                throw FirebaseServiceError.userNotFound
            }
            
            let newWins = user.wins + 1
            try await updateUserFightRecord(userId: userId, wins: newWins, losses: user.losses)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Increment User Losses
    func incrementUserLosses(userId: String) async throws {
        do {
            let user = try await getUser(id: userId)
            guard let user = user else {
                throw FirebaseServiceError.userNotFound
            }
            
            let newLosses = user.losses + 1
            try await updateUserFightRecord(userId: userId, wins: user.wins, losses: newLosses)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Reset User Fight Record
    func resetUserFightRecord(userId: String) async throws {
        try await updateUserFightRecord(userId: userId, wins: 0, losses: 0)
    }
}

// MARK: - User Profile Operations
extension UserRepository {
    
    // MARK: - Update User Fight Name
    func updateUserFightName(userId: String, fightName: String) async throws {
        do {
            let fields: [String: Any] = [
                "fightName": fightName,
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update User Town
    func updateUserTown(userId: String, town: String) async throws {
        do {
            let fields: [String: Any] = [
                "town": town,
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update User Profile Image
    func updateUserProfileImage(userId: String, imageUrl: String) async throws {
        do {
            let fields: [String: Any] = [
                "profileImageUrl": imageUrl,
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update User Last Active
    func updateUserLastActive(userId: String) async throws {
        do {
            let fields: [String: Any] = [
                "lastActive": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: userId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - User Search Operations
extension UserRepository {
    
    // MARK: - Search Users by Fight Name
    func searchUsersByFightName(_ fightName: String) async throws -> [SpiderLeagueUser] {
        do {
            // Note: This is a simple exact match. For more advanced search, you'd need to implement
            // a search service or use Firebase's full-text search capabilities
            return try await queryDocuments(SpiderLeagueUser.self, in: collection, where: "fightName", isEqualTo: fightName)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Top Users by Wins
    func getTopUsersByWins(limit: Int = 10) async throws -> [SpiderLeagueUser] {
        do {
            let options = FirebaseQueryOptions(
                limit: limit,
                orderBy: "wins",
                orderDirection: true // descending
            )
            
            return try await queryDocuments(SpiderLeagueUser.self, in: collection, withOptions: options)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Top Users by Win Percentage
    func getTopUsersByWinPercentage(limit: Int = 10) async throws -> [SpiderLeagueUser] {
        do {
            // Get all users and sort by win percentage
            let allUsers = try await queryDocuments(SpiderLeagueUser.self, in: collection, withOptions: FirebaseQueryOptions.default)
            
            let sortedUsers = allUsers
                .filter { $0.totalFights >= 3 } // Only users with at least 3 fights
                .sorted { $0.winPercentage > $1.winPercentage }
                .prefix(limit)
            
            return Array(sortedUsers)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Real-time Listeners
extension UserRepository {
    
    // MARK: - Listen for User Changes
    func listenForUserChanges(userId: String) -> AnyPublisher<SpiderLeagueUser, Never> {
        return addDocumentListener(SpiderLeagueUser.self, withId: userId, in: collection)
    }
    
    // MARK: - Listen for Ready Users in Town
    func listenForReadyUsersInTown(_ town: String) -> AnyPublisher<[SpiderLeagueUser], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("status", isEqualTo: UserStatus.ready.rawValue)
            .whereField("town", isEqualTo: town)
        
        let subject = PassthroughSubject<[SpiderLeagueUser], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to ready users in town: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let users = try documents.compactMap { document in
                    try document.data(as: SpiderLeagueUser.self)
                }
                subject.send(users)
            } catch {
                print("Error decoding users: \(error)")
            }
        }
        
        let listenerKey = "ready_users_town_\(town)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
}
