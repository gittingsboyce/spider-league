import Foundation
import FirebaseFirestore

struct Challenge: Identifiable, Codable {
    let id: String
    let challengerId: String
    let challengedId: String
    let challengerSpiderId: String
    var status: ChallengeStatus
    let expiresAt: Date
    let createdAt: Date
    var acceptedAt: Date?
    var declinedAt: Date?
    let message: String?
    
    init(challengerId: String, challengedId: String, challengerSpiderId: String, message: String? = nil) {
        self.id = UUID().uuidString
        self.challengerId = challengerId
        self.challengedId = challengedId
        self.challengerSpiderId = challengerSpiderId
        self.status = .pending
        self.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        self.createdAt = Date()
        self.acceptedAt = nil
        self.declinedAt = nil
        self.message = message
    }
    
    // Computed properties
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var isPending: Bool {
        return status == .pending && !isExpired
    }
    
    var canBeAccepted: Bool {
        return status == .pending && !isExpired
    }
    
    var canBeDeclined: Bool {
        return status == .pending && !isExpired
    }
    
    var hoursUntilExpiry: Int {
        return Int(timeUntilExpiry / 3600)
    }
    
    var minutesUntilExpiry: Int {
        return Int((timeUntilExpiry.truncatingRemainder(dividingBy: 3600)) / 60)
    }
    
    var formattedTimeUntilExpiry: String {
        if hoursUntilExpiry > 0 {
            return "\(hoursUntilExpiry)h \(minutesUntilExpiry)m"
        } else {
            return "\(minutesUntilExpiry)m"
        }
    }
}

// MARK: - Challenge Status Enum
enum ChallengeStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
    
    var displayText: String {
        return rawValue
    }
    
    var isActive: Bool {
        return self == .pending
    }
    
    var isCompleted: Bool {
        return self == .accepted || self == .declined || self == .expired
    }
}

// MARK: - Firestore Codable Extensions
extension Challenge {
    enum CodingKeys: String, CodingKey {
        case id
        case challengerId
        case challengedId
        case challengerSpiderId
        case status
        case expiresAt
        case createdAt
        case acceptedAt
        case declinedAt
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        challengerId = try container.decode(String.self, forKey: .challengerId)
        challengedId = try container.decode(String.self, forKey: .challengedId)
        challengerSpiderId = try container.decode(String.self, forKey: .challengerSpiderId)
        status = try container.decode(ChallengeStatus.self, forKey: .status)
        
        // Handle Firestore Timestamps
        let expiresAtTimestamp = try container.decode(Timestamp.self, forKey: .expiresAt)
        expiresAt = expiresAtTimestamp.dateValue()
        
        let createdAtTimestamp = try container.decode(Timestamp.self, forKey: .createdAt)
        createdAt = createdAtTimestamp.dateValue()
        
        if let acceptedAtTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .acceptedAt) {
            acceptedAt = acceptedAtTimestamp.dateValue()
        } else {
            acceptedAt = nil
        }
        
        if let declinedAtTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .declinedAt) {
            declinedAt = declinedAtTimestamp.dateValue()
        } else {
            declinedAt = nil
        }
        
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(challengerId, forKey: .challengerId)
        try container.encode(challengedId, forKey: .challengedId)
        try container.encode(challengerSpiderId, forKey: .challengerSpiderId)
        try container.encode(status, forKey: .status)
        try container.encode(Timestamp(date: expiresAt), forKey: .expiresAt)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        
        if let acceptedAt = acceptedAt {
            try container.encode(Timestamp(date: acceptedAt), forKey: .acceptedAt)
        }
        
        if let declinedAt = declinedAt {
            try container.encode(Timestamp(date: declinedAt), forKey: .declinedAt)
        }
        
        try container.encodeIfPresent(message, forKey: .message)
    }
}
