import Foundation
import FirebaseFirestore

struct SpiderLeagueUser: Identifiable, Codable {
    let id: String
    let email: String
    let fightName: String
    var wins: Int
    var losses: Int
    var status: UserStatus
    var town: String
    let createdAt: Date
    var lastActive: Date
    var profileImageUrl: String?
    let isEmailVerified: Bool
    
    init(id: String, email: String, fightName: String, town: String) {
        self.id = id
        self.email = email
        self.fightName = fightName
        self.wins = 0
        self.losses = 0
        self.status = .notReady
        self.town = town
        self.createdAt = Date()
        self.lastActive = Date()
        self.profileImageUrl = nil
        self.isEmailVerified = false
    }
    
    // Computed properties
    var totalFights: Int {
        return wins + losses
    }
    
    var winPercentage: Double {
        guard totalFights > 0 else { return 0.0 }
        return Double(wins) / Double(totalFights) * 100.0
    }
    
    var isReadyToFight: Bool {
        return status == .ready
    }
    
    var daysSinceCreation: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    var daysSinceLastActive: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
    }
}

// MARK: - User Status Enum
enum UserStatus: String, Codable, CaseIterable {
    case ready = "Ready to Fight"
    case notReady = "Not Ready"
    
    var displayText: String {
        return rawValue
    }
}

// MARK: - Firestore Codable Extensions
extension SpiderLeagueUser {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fightName
        case wins
        case losses
        case status
        case town
        case createdAt
        case lastActive
        case profileImageUrl
        case isEmailVerified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fightName = try container.decode(String.self, forKey: .fightName)
        wins = try container.decode(Int.self, forKey: .wins)
        losses = try container.decode(Int.self, forKey: .losses)
        status = try container.decode(UserStatus.self, forKey: .status)
        town = try container.decode(String.self, forKey: .town)
        
        // Handle Firestore Timestamps
        let createdAtTimestamp = try container.decode(Timestamp.self, forKey: .createdAt)
        createdAt = createdAtTimestamp.dateValue()
        
        let lastActiveTimestamp = try container.decode(Timestamp.self, forKey: .lastActive)
        lastActive = lastActiveTimestamp.dateValue()
        
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        isEmailVerified = try container.decode(Bool.self, forKey: .isEmailVerified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(fightName, forKey: .fightName)
        try container.encode(wins, forKey: .wins)
        try container.encode(losses, forKey: .losses)
        try container.encode(status, forKey: .status)
        try container.encode(town, forKey: .town)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: lastActive), forKey: .lastActive)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(isEmailVerified, forKey: .isEmailVerified)
    }
}
