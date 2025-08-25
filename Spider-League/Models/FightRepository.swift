import Foundation
import FirebaseFirestore
import Combine

// MARK: - Fight Repository
class FightRepository: BaseRepository {
    
    // MARK: - Properties
    private let collection = Collection.fights
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
}

// MARK: - Fight CRUD Operations
extension FightRepository {
    
    // MARK: - Create Fight
    func createFight(_ fight: Fight) async throws -> Fight {
        do {
            let documentId = try await createDocument(fight, withId: fight.id, in: collection)
            var createdFight = fight
            // Note: The fight.id is already set, so we don't need to update it
            return createdFight
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Fight by ID
    func getFight(id: String) async throws -> Fight? {
        do {
            return try await readDocument(Fight.self, withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Fight
    func updateFight(_ fight: Fight) async throws -> Fight {
        do {
            try await updateDocument(fight, withId: fight.id, in: collection)
            return fight
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete Fight
    func deleteFight(id: String) async throws {
        do {
            try await deleteDocument(withId: id, in: collection)
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Fight Query Operations
extension FightRepository {
    
    // MARK: - Get User's Fight History
    func getUserFightHistory(userId: String) async throws -> [Fight] {
        do {
            let options = FirebaseQueryOptions(
                orderBy: "completedAt",
                orderDirection: true // descending (newest first)
            )
            
            let allFights = try await queryDocuments(Fight.self, in: collection, withOptions: options)
            
            // Filter for fights where user participated
            return allFights.filter { $0.challengerId == userId || $0.challengedId == userId }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Wins
    func getUserWins(userId: String) async throws -> [Fight] {
        do {
            let userFights = try await getUserFightHistory(userId: userId)
            return userFights.filter { $0.winnerId == userId }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Losses
    func getUserLosses(userId: String) async throws -> [Fight] {
        do {
            let userFights = try await getUserFightHistory(userId: userId)
            return userFights.filter { $0.loserId == userId }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get User's Draws
    func getUserDraws(userId: String) async throws -> [Fight] {
        do {
            let userFights = try await getUserFightHistory(userId: userId)
            return userFights.filter { $0.isDraw }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Fights by Challenge
    func getFightsByChallenge(challengeId: String) async throws -> [Fight] {
        do {
            return try await queryDocuments(Fight.self, in: collection, where: "challengeId", isEqualTo: challengeId)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Fights by Date Range
    func getFightsByDateRange(startDate: Date, endDate: Date, userId: String? = nil) async throws -> [Fight] {
        do {
            var conditions: [(field: String, operator: QueryFilterOperator, value: Any)] = [
                ("completedAt", .isGreaterThanOrEqualTo, Timestamp(date: startDate)),
                ("completedAt", .isLessThanOrEqualTo, Timestamp(date: endDate))
            ]
            
            if let userId = userId {
                // Get fights where user participated
                let userFights = try await getUserFightHistory(userId: userId)
                return userFights.filter { fight in
                    fight.completedAt >= startDate && fight.completedAt <= endDate
                }
            } else {
                // Get all fights in date range
                return try await queryDocuments(Fight.self, in: collection, where: conditions)
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Recent Fights
    func getRecentFights(limit: Int = 20, userId: String? = nil) async throws -> [Fight] {
        do {
            let options = FirebaseQueryOptions(
                limit: limit,
                orderBy: "completedAt",
                orderDirection: true // descending (newest first)
            )
            
            if let userId = userId {
                let userFights = try await getUserFightHistory(userId: userId)
                return Array(userFights.prefix(limit))
            } else {
                return try await queryDocuments(Fight.self, in: collection, withOptions: options)
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Fights by Spider
    func getFightsBySpider(spiderId: String) async throws -> [Fight] {
        do {
            let allFights = try await queryDocuments(Fight.self, in: collection, withOptions: FirebaseQueryOptions.default)
            
            return allFights.filter { fight in
                fight.challengerSpiderId == spiderId || 
                fight.challengedSpiderId == spiderId ||
                fight.winnerSpiderId == spiderId || 
                fight.loserSpiderId == spiderId
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Fight Statistics Operations
extension FightRepository {
    
    // MARK: - Get User Fight Statistics
    func getUserFightStatistics(userId: String) async throws -> (totalFights: Int, wins: Int, losses: Int, draws: Int, winPercentage: Double, averageScore: Double) {
        do {
            let userFights = try await getUserFightHistory(userId: userId)
            
            let totalFights = userFights.count
            let wins = userFights.filter { $0.winnerId == userId }.count
            let losses = userFights.filter { $0.loserId == userId }.count
            let draws = userFights.filter { $0.isDraw }.count
            
            let winPercentage = totalFights > 0 ? (Double(wins) / Double(totalFights)) * 100.0 : 0.0
            
            // Calculate average score from user's spiders in fights
            let userSpiderScores = userFights.compactMap { fight -> Double? in
                if fight.challengerId == userId {
                    return fight.outcome.winnerScore > fight.outcome.loserScore ? fight.outcome.winnerScore : fight.outcome.loserScore
                } else if fight.challengedId == userId {
                    return fight.outcome.winnerScore > fight.outcome.loserScore ? fight.outcome.loserScore : fight.outcome.winnerScore
                }
                return nil
            }
            
            let averageScore = userSpiderScores.isEmpty ? 0.0 : userSpiderScores.reduce(0.0, +) / Double(userSpiderScores.count)
            
            return (
                totalFights: totalFights,
                wins: wins,
                losses: losses,
                draws: draws,
                winPercentage: winPercentage,
                averageScore: averageScore
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Fight Outcome Statistics
    func getFightOutcomeStatistics() async throws -> (totalFights: Int, draws: Int, averageScoreDifference: Double, closeFights: Int) {
        do {
            let allFights = try await queryDocuments(Fight.self, in: collection, withOptions: FirebaseQueryOptions.default)
            
            let totalFights = allFights.count
            let draws = allFights.filter { $0.isDraw }.count
            
            let scoreDifferences = allFights.compactMap { fight -> Double? in
                guard !fight.isDraw else { return nil }
                return fight.scoreDifference
            }
            
            let averageScoreDifference = scoreDifferences.isEmpty ? 0.0 : scoreDifferences.reduce(0.0, +) / Double(scoreDifferences.count)
            
            let closeFights = allFights.filter { $0.wasCloseFight }.count
            
            return (
                totalFights: totalFights,
                draws: draws,
                averageScoreDifference: averageScoreDifference,
                closeFights: closeFights
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Top Performers
    func getTopPerformers(limit: Int = 10) async throws -> [(userId: String, wins: Int, winPercentage: Double)] {
        do {
            // Get all users who have participated in fights
            let allFights = try await queryDocuments(Fight.self, in: collection, withOptions: FirebaseQueryOptions.default)
            
            var userStats: [String: (wins: Int, totalFights: Int)] = [:]
            
            for fight in allFights {
                if !fight.isDraw {
                    // Update challenger stats
                    let challengerId = fight.challengerId
                    let challengerStats = userStats[challengerId] ?? (wins: 0, totalFights: 0)
                    userStats[challengerId] = (
                        wins: challengerStats.wins + (fight.winnerId == challengerId ? 1 : 0),
                        totalFights: challengerStats.totalFights + 1
                    )
                    
                    // Update challenged stats
                    let challengedId = fight.challengedId
                    let challengedStats = userStats[challengedId] ?? (wins: 0, totalFights: 0)
                    userStats[challengedId] = (
                        wins: challengedStats.wins + (fight.winnerId == challengedId ? 1 : 0),
                        totalFights: challengedStats.totalFights + 1
                    )
                }
            }
            
            // Calculate win percentages and sort
            let topPerformers = userStats.compactMap { userId, stats -> (userId: String, wins: Int, winPercentage: Double)? in
                guard stats.totalFights >= 3 else { return nil } // Minimum 3 fights
                let winPercentage = (Double(stats.wins) / Double(stats.totalFights)) * 100.0
                return (userId: userId, wins: stats.wins, winPercentage: winPercentage)
            }
            .sorted { $0.winPercentage > $1.winPercentage }
            .prefix(limit)
            
            return Array(topPerformers)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Get Spider Performance Statistics
    func getSpiderPerformanceStatistics(spiderId: String) async throws -> (totalFights: Int, wins: Int, losses: Int, winPercentage: Double, averageScore: Double) {
        do {
            let spiderFights = try await getFightsBySpider(spiderId: spiderId)
            
            let totalFights = spiderFights.count
            let wins = spiderFights.filter { $0.winnerSpiderId == spiderId }.count
            let losses = spiderFights.filter { $0.loserSpiderId == spiderId }.count
            
            let winPercentage = totalFights > 0 ? (Double(wins) / Double(totalFights)) * 100.0 : 0.0
            
            // Calculate average score for this spider
            let spiderScores = spiderFights.compactMap { fight -> Double? in
                if fight.winnerSpiderId == spiderId {
                    return fight.outcome.winnerScore
                } else if fight.loserSpiderId == spiderId {
                    return fight.outcome.loserScore
                }
                return nil
            }
            
            let averageScore = spiderScores.isEmpty ? 0.0 : spiderScores.reduce(0.0, +) / Double(spiderScores.count)
            
            return (
                totalFights: totalFights,
                wins: wins,
                losses: losses,
                winPercentage: winPercentage,
                averageScore: averageScore
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Fight Analysis Operations
extension FightRepository {
    
    // MARK: - Analyze Fight Outcome
    func analyzeFightOutcome(fight: Fight) -> (wasExpected: Bool, surpriseFactor: Double, keyFactors: [String]) {
        let expectedWinner = fight.outcome.winProbability > 0.5 ? fight.challengerId : fight.challengedId
        let actualWinner = fight.winnerId
        
        let wasExpected = expectedWinner == actualWinner
        let surpriseFactor = abs(fight.outcome.winProbability - 0.5) * 2 // 0 = 50/50, 1 = completely one-sided
        
        var keyFactors: [String] = []
        
        if fight.wasCloseFight {
            keyFactors.append("Close fight - scores were very similar")
        }
        
        if surpriseFactor > 0.8 {
            keyFactors.append("Upset victory - unexpected outcome")
        }
        
        if fight.outcome.marginOfVictory > 50 {
            keyFactors.append("Dominant performance - large score difference")
        }
        
        if fight.isDraw {
            keyFactors.append("Perfect tie - identical scores")
        }
        
        return (wasExpected: wasExpected, surpriseFactor: surpriseFactor, keyFactors: keyFactors)
    }
    
    // MARK: - Get Fight Trends
    func getFightTrends(days: Int = 30) async throws -> (totalFights: Int, averageScore: Double, mostCommonSpecies: String?, averageFightDuration: TimeInterval?) {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            let recentFights = try await getFightsByDateRange(startDate: startDate, endDate: endDate)
            
            let totalFights = recentFights.count
            
            // Calculate average score (this would need spider data)
            let averageScore = 0.0 // Placeholder - would need spider repository access
            
            // Most common species (this would need spider data)
            let mostCommonSpecies: String? = nil // Placeholder - would need spider repository access
            
            // Average fight duration (if we had start time)
            let averageFightDuration: TimeInterval? = nil // Placeholder - would need start time tracking
            
            return (
                totalFights: totalFights,
                averageScore: averageScore,
                mostCommonSpecies: mostCommonSpecies,
                averageFightDuration: averageFightDuration
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Real-time Listeners
extension FightRepository {
    
    // MARK: - Listen for Fight Changes
    func listenForFightChanges(fightId: String) -> AnyPublisher<Fight, Never> {
        return addDocumentListener(Fight.self, withId: fightId, in: collection)
    }
    
    // MARK: - Listen for User's Fight History
    func listenForUserFightHistory(userId: String) -> AnyPublisher<[Fight], Never> {
        let query = db.collection(collection.rawValue)
            .order(by: "completedAt", descending: true)
        
        let subject = PassthroughSubject<[Fight], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to user fight history: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let allFights = try documents.compactMap { document in
                    try document.data(as: Fight.self)
                }
                
                // Filter for fights where user participated
                let userFights = allFights.filter { $0.challengerId == userId || $0.challengedId == userId }
                subject.send(userFights)
            } catch {
                print("Error decoding fights: \(error)")
            }
        }
        
        let listenerKey = "user_fight_history_\(userId)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Listen for Recent Fights
    func listenForRecentFights(limit: Int = 20) -> AnyPublisher<[Fight], Never> {
        let query = db.collection(collection.rawValue)
            .order(by: "completedAt", descending: true)
            .limit(to: limit)
        
        let subject = PassthroughSubject<[Fight], Never>()
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to recent fights: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            do {
                let fights = try documents.compactMap { document in
                    try document.data(as: Fight.self)
                }
                subject.send(fights)
            } catch {
                print("Error decoding fights: \(error)")
            }
        }
        
        let listenerKey = "recent_fights"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
}
