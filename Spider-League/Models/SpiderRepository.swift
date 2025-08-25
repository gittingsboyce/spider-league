import Foundation
import FirebaseFirestore
import Combine

// MARK: - Spider Repository
class SpiderRepository: BaseRepository {
    
    // MARK: - Properties
    private let collection = Collection.spiders
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
}

// MARK: - Spider CRUD Operations
extension SpiderRepository {
    
    // MARK: - Create Spider
    func createSpider(_ spider: Spider) async throws -> Spider {
        do {
            let documentId = try await createDocument(spider, withId: spider.id, in: collection)
            var createdSpider = spider
            // Note: The spider.id is already set, so we don't need to update it
            return createdSpider
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spider by ID
    func getSpider(id: String) async throws -> Spider? {
        do {
            return try await readDocument(Spider.self, withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Spider
    func updateSpider(_ spider: Spider) async throws -> Spider {
        do {
            try await updateDocument(spider, withId: spider.id, in: collection)
            return spider
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete Spider
    func deleteSpider(id: String) async throws {
        do {
            try await deleteDocument(withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Spider Query Operations
extension SpiderRepository {
    
    // MARK: - Get User's Spiders
    func getUserSpiders(userId: String) async throws -> [Spider] {
        do {
            let options = FirebaseQueryOptions(
                orderBy: "createdAt",
                orderDirection: false // ascending (oldest first)
            )
            
            return try await queryDocuments(Spider.self, in: collection, withOptions: options)
                .filter { $0.userId == userId }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spider by ID (alias for consistency)
    func getSpiderById(id: String) async throws -> Spider? {
        return try await getSpider(id: id)
    }
    
    // MARK: - Get Spiders by Species
    func getSpiderBySpecies(species: String) async throws -> [Spider] {
        do {
            return try await queryDocuments(Spider.self, in: collection, where: "species", isEqualTo: species)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Active Spiders
    func getActiveSpiders(userId: String) async throws -> [Spider] {
        do {
            let userSpiders = try await getUserSpiders(userId: userId)
            return userSpiders.filter { $0.isActive }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spiders Available for Fight
    func getSpidersAvailableForFight(userId: String) async throws -> [Spider] {
        do {
            let userSpiders = try await getUserSpiders(userId: userId)
            return userSpiders.filter { $0.canBeUsedInFight }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spiders by Deadliness Range
    func getSpidersByDeadlinessRange(minScore: Double, maxScore: Double, userId: String? = nil) async throws -> [Spider] {
        do {
            var conditions: [(field: String, operator: QueryFilterOperator, value: Any)] = [
                ("deadlinessScore", .isGreaterThanOrEqualTo, minScore),
                ("deadlinessScore", .isLessThanOrEqualTo, maxScore)
            ]
            
            if let userId = userId {
                conditions.append(("userId", .isEqualTo, userId))
            }
            
            return try await queryDocuments(Spider.self, in: collection, where: conditions)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Spider Usage Operations
extension SpiderRepository {
    
    // MARK: - Update Spider Last Used in Fight
    func updateSpiderLastUsed(spiderId: String) async throws {
        do {
            let fields: [String: Any] = [
                "lastUsedInFight": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Mark Spider as Inactive
    func markSpiderInactive(spiderId: String) async throws {
        do {
            let fields: [String: Any] = [
                "isActive": false
            ]
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Mark Spider as Active
    func markSpiderActive(spiderId: String) async throws {
        do {
            let fields: [String: Any] = [
                "isActive": true
            ]
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Spider Cooldown Operations
extension SpiderRepository {
    
    // MARK: - Check User Spider Cooldown
    func checkUserSpiderCooldown(userId: String) async throws -> Bool {
        do {
            let userSpiders = try await getUserSpiders(userId: userId)
            
            // Check if user has any spiders that can be used in a fight
            let availableSpiders = userSpiders.filter { $0.canBeUsedInFight }
            
            return !availableSpiders.isEmpty
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Next Available Spider Time
    func getUserNextAvailableSpiderTime(userId: String) async throws -> Date? {
        do {
            let userSpiders = try await getUserSpiders(userId: userId)
            
            // Find the most recently used spider
            let recentlyUsedSpiders = userSpiders
                .filter { $0.lastUsedInFight != nil }
                .sorted { $0.lastUsedInFight! > $1.lastUsedInFight! }
            
            guard let mostRecentSpider = recentlyUsedSpiders.first,
                  let lastUsed = mostRecentSpider.lastUsedInFight else {
                return nil // No spiders have been used yet
            }
            
            // Calculate next available time (24 hours after last use)
            let calendar = Calendar.current
            let nextAvailable = calendar.date(byAdding: .hour, value: 24, to: lastUsed) ?? lastUsed
            
            return nextAvailable
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Cooldown Status
    func getUserSpiderCooldownStatus(userId: String) async throws -> (canUseSpider: Bool, nextAvailableTime: Date?, timeRemaining: TimeInterval?) {
        do {
            let canUseSpider = try await checkUserSpiderCooldown(userId: userId)
            let nextAvailableTime = try await getUserNextAvailableSpiderTime(userId: userId)
            
            var timeRemaining: TimeInterval?
            if let nextAvailable = nextAvailableTime {
                timeRemaining = nextAvailable.timeIntervalSince(Date())
                if timeRemaining! < 0 {
                    timeRemaining = 0
                }
            }
            
            return (canUseSpider: canUseSpider, nextAvailableTime: nextAvailableTime, timeRemaining: timeRemaining)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Spider Analysis Operations
extension SpiderRepository {
    
    // MARK: - Update Spider Gemini Analysis
    func updateSpiderGeminiAnalysis(spiderId: String, species: String, confidence: Double) async throws {
        do {
            let fields: [String: Any] = [
                "geminiAnalysis.species": species,
                "geminiAnalysis.confidence": confidence,
                "geminiAnalysis.analysisTimestamp": Timestamp(date: Date())
            ]
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Spider Deadliness Score
    func updateSpiderDeadlinessScore(spiderId: String, score: Double) async throws {
        do {
            let fields: [String: Any] = [
                "deadlinessScore": score
            ]
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Spider Image Metadata
    func updateSpiderImageMetadata(spiderId: String, metadata: ImageMetadata) async throws {
        do {
            var fields: [String: Any] = [
                "imageMetadata.width": metadata.width,
                "imageMetadata.height": metadata.height,
                "imageMetadata.fileSize": metadata.fileSize
            ]
            
            if let takenAt = metadata.takenAt {
                fields["imageMetadata.takenAt"] = Timestamp(date: takenAt)
            }
            
            if let location = metadata.location {
                fields["imageMetadata.location.latitude"] = location.latitude
                fields["imageMetadata.location.longitude"] = location.longitude
            }
            
            try await updateDocumentFields(fields, withId: spiderId, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Spider Statistics Operations
extension SpiderRepository {
    
    // MARK: - Get User's Spider Statistics
    func getUserSpiderStatistics(userId: String) async throws -> (totalSpiders: Int, activeSpiders: Int, averageDeadliness: Double, strongestSpider: Spider?) {
        do {
            let userSpiders = try await getUserSpiders(userId: userId)
            
            let totalSpiders = userSpiders.count
            let activeSpiders = userSpiders.filter { $0.isActive }.count
            
            let averageDeadliness = userSpiders.isEmpty ? 0.0 : 
                userSpiders.reduce(0.0) { $0 + ($1.deadlinessScore ?? 0.0) } / Double(userSpiders.count)
            
            let strongestSpider = userSpiders.compactMap { $0.deadlinessScore }.max().flatMap { maxScore in
                userSpiders.first { ($0.deadlinessScore ?? 0.0) == maxScore }
            }
            
            return (totalSpiders: totalSpiders, activeSpiders: activeSpiders, averageDeadliness: averageDeadliness, strongestSpider: strongestSpider)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Top Spiders by Deadliness
    func getTopSpidersByDeadliness(limit: Int = 10, userId: String? = nil) async throws -> [Spider] {
        do {
            let options = FirebaseQueryOptions(
                limit: limit,
                orderBy: "deadlinessScore",
                orderDirection: true // descending
            )
            
            var spiders = try await queryDocuments(Spider.self, in: collection, withOptions: options)
            
            if let userId = userId {
                spiders = spiders.filter { $0.userId == userId }
            }
            
            return spiders
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spiders by Creation Date Range
    func getSpidersByCreationDateRange(startDate: Date, endDate: Date, userId: String? = nil) async throws -> [Spider] {
        do {
            var conditions: [(field: String, operator: QueryFilterOperator, value: Any)] = [
                ("createdAt", .isGreaterThanOrEqualTo, Timestamp(date: startDate)),
                ("createdAt", .isLessThanOrEqualTo, Timestamp(date: endDate))
            ]
            
            if let userId = userId {
                conditions.append(("userId", .isEqualTo, userId))
            }
            
            return try await queryDocuments(Spider.self, in: collection, where: conditions)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Real-time Listeners
extension SpiderRepository {
    
    // MARK: - Listen for Spider Changes
    func listenForSpiderChanges(spiderId: String) -> AnyPublisher<Spider, Never> {
        return addDocumentListener(Spider.self, withId: spiderId, in: collection)
    }
    
    // MARK: - Listen for User's Spiders
    func listenForUserSpiders(userId: String) -> AnyPublisher<[Spider], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
        
        let subject = PassthroughSubject<[Spider], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to user spiders: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let spiders = try documents.compactMap { document in
                    try document.data(as: Spider.self)
                }
                subject.send(spiders)
            } catch {
                print("Error decoding spiders: \(error)")
            }
        }
        
        let listenerKey = "user_spiders_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Listen for Available Fight Spiders
    func listenForAvailableFightSpiders(userId: String) -> AnyPublisher<[Spider], Never> {
        let query = db.collection(collection.rawValue)
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
        
        let subject = PassthroughSubject<[Spider], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to available fight spiders: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let spiders = try documents.compactMap { document in
                    try document.data(as: Spider.self)
                }
                
                // Filter for spiders that can be used in fights
                let availableSpiders = spiders.filter { $0.canBeUsedInFight }
                subject.send(availableSpiders)
            } catch {
                print("Error decoding spiders: \(error)")
            }
        }
        
        let listenerKey = "available_fight_spiders_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
}
