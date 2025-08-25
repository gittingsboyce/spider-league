import Foundation
import FirebaseFirestore

struct Fight: Identifiable, Codable {
    let id: String
    let challengeId: String
    let challengerId: String
    let challengedId: String
    let challengerSpiderId: String
    let challengedSpiderId: String
    let winnerId: String
    let loserId: String
    let winnerSpiderId: String
    let loserSpiderId: String
    let outcome: FightOutcome
    let completedAt: Date
    let isDraw: Bool
    let rematchTriggered: Bool
    
    init(challengeId: String, challengerId: String, challengedId: String, challengerSpiderId: String, challengedSpiderId: String, outcome: FightOutcome) {
        self.id = UUID().uuidString
        self.challengeId = challengeId
        self.challengerId = challengerId
        self.challengedId = challengedId
        self.challengerSpiderId = challengerSpiderId
        self.challengedSpiderId = challengedSpiderId
        
        // Determine winner and loser based on outcome
        if outcome.isDraw {
            self.winnerId = ""
            self.loserId = ""
            self.winnerSpiderId = ""
            self.loserSpiderId = ""
        } else {
            if outcome.winnerScore > outcome.loserScore {
                self.winnerId = challengerId
                self.loserId = challengedId
                self.winnerSpiderId = challengerSpiderId
                self.loserSpiderId = challengedSpiderId
            } else {
                self.winnerId = challengedId
                self.loserId = challengerId
                self.winnerSpiderId = challengedSpiderId
                self.loserSpiderId = challengerSpiderId
            }
        }
        
        self.outcome = outcome
        self.completedAt = Date()
        self.isDraw = outcome.isDraw
        self.rematchTriggered = false
    }
    
    // Computed properties
    var isChallengerWinner: Bool {
        return winnerId == challengerId
    }
    
    var isChallengedWinner: Bool {
        return winnerId == challengedId
    }
    
    var winnerScore: Double {
        return outcome.winnerScore
    }
    
    var loserScore: Double {
        return outcome.loserScore
    }
    
    var scoreDifference: Double {
        return abs(winnerScore - loserScore)
    }
    
    var wasCloseFight: Bool {
        return scoreDifference < 10.0 // Define what constitutes a "close" fight
    }
    
    var formattedCompletedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
}

// MARK: - Fight Outcome
struct FightOutcome: Codable {
    let winnerScore: Double
    let loserScore: Double
    let winProbability: Double
    let modifiers: [String: Any]
    
    var isDraw: Bool {
        return winnerScore == loserScore
    }
    
    var marginOfVictory: Double {
        return winnerScore - loserScore
    }
    
    var victoryPercentage: Double {
        guard winnerScore + loserScore > 0 else { return 0.0 }
        return (winnerScore / (winnerScore + loserScore)) * 100.0
    }
    
    init(winnerScore: Double, loserScore: Double, winProbability: Double, modifiers: [String: Any] = [:]) {
        self.winnerScore = winnerScore
        self.loserScore = loserScore
        self.winProbability = winProbability
        self.modifiers = modifiers
    }
}

// MARK: - Firestore Codable Extensions
extension Fight {
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId
        case challengerId
        case challengedId
        case challengerSpiderId
        case challengedSpiderId
        case winnerId
        case loserId
        case winnerSpiderId
        case loserSpiderId
        case outcome
        case completedAt
        case isDraw
        case rematchTriggered
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        challengeId = try container.decode(String.self, forKey: .challengeId)
        challengerId = try container.decode(String.self, forKey: .challengerId)
        challengedId = try container.decode(String.self, forKey: .challengedId)
        challengerSpiderId = try container.decode(String.self, forKey: .challengerSpiderId)
        challengedSpiderId = try container.decode(String.self, forKey: .challengedSpiderId)
        winnerId = try container.decode(String.self, forKey: .winnerId)
        loserId = try container.decode(String.self, forKey: .loserId)
        winnerSpiderId = try container.decode(String.self, forKey: .winnerSpiderId)
        loserSpiderId = try container.decode(String.self, forKey: .loserSpiderId)
        outcome = try container.decode(FightOutcome.self, forKey: .outcome)
        
        // Handle Firestore Timestamp
        let completedAtTimestamp = try container.decode(Timestamp.self, forKey: .completedAt)
        completedAt = completedAtTimestamp.dateValue()
        
        isDraw = try container.decode(Bool.self, forKey: .isDraw)
        rematchTriggered = try container.decode(Bool.self, forKey: .rematchTriggered)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(challengeId, forKey: .challengeId)
        try container.encode(challengerId, forKey: .challengerId)
        try container.encode(challengedId, forKey: .challengedId)
        try container.encode(challengerSpiderId, forKey: .challengerSpiderId)
        try container.encode(challengedSpiderId, forKey: .challengedSpiderId)
        try container.encode(winnerId, forKey: .winnerId)
        try container.encode(loserId, forKey: .loserId)
        try container.encode(winnerSpiderId, forKey: .winnerSpiderId)
        try container.encode(loserSpiderId, forKey: .loserSpiderId)
        try container.encode(outcome, forKey: .outcome)
        try container.encode(Timestamp(date: completedAt), forKey: .completedAt)
        try container.encode(isDraw, forKey: .isDraw)
        try container.encode(rematchTriggered, forKey: .rematchTriggered)
    }
}

// MARK: - Fight Outcome Codable Extensions
extension FightOutcome {
    enum CodingKeys: String, CodingKey {
        case winnerScore
        case loserScore
        case winProbability
        case modifiers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        winnerScore = try container.decode(Double.self, forKey: .winnerScore)
        loserScore = try container.decode(Double.self, forKey: .loserScore)
        winProbability = try container.decode(Double.self, forKey: .winProbability)
        
        // Handle modifiers as a dictionary
        if let modifiersData = try container.decodeIfPresent(Data.self, forKey: .modifiers) {
            modifiers = try JSONSerialization.jsonObject(with: modifiersData) as? [String: Any] ?? [:]
        } else {
            modifiers = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(winnerScore, forKey: .winnerScore)
        try container.encode(loserScore, forKey: .loserScore)
        try container.encode(winProbability, forKey: .winProbability)
        
        // Convert modifiers to Data for storage
        if !modifiers.isEmpty {
            let modifiersData = try JSONSerialization.data(withJSONObject: modifiers)
            try container.encode(modifiersData, forKey: .modifiers)
        }
    }
}
