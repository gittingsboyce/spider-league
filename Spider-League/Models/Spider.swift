import Foundation
import FirebaseFirestore
import CoreLocation

struct Spider: Identifiable, Codable {
    let id: String
    let userId: String
    let species: String
    let deadlinessScore: Double
    let imageUrl: String
    let imageMetadata: ImageMetadata
    let geminiAnalysis: GeminiAnalysis
    let createdAt: Date
    var lastUsedInFight: Date?
    var isActive: Bool
    
    init(userId: String, species: String, deadlinessScore: Double, imageUrl: String, imageMetadata: ImageMetadata, geminiAnalysis: GeminiAnalysis) {
        self.id = UUID().uuidString
        self.userId = userId
        self.species = species
        self.deadlinessScore = deadlinessScore
        self.imageUrl = imageUrl
        self.imageMetadata = imageMetadata
        self.geminiAnalysis = geminiAnalysis
        self.createdAt = Date()
        self.lastUsedInFight = nil
        self.isActive = true
    }
    
    // Computed properties
    var canBeUsedInFight: Bool {
        return isActive && (lastUsedInFight == nil || Calendar.current.dateInterval(of: .day, for: Date())?.contains(lastUsedInFight!) == false)
    }
    
    var daysSinceLastFight: Int? {
        guard let lastFight = lastUsedInFight else { return nil }
        return Calendar.current.dateComponents([.day], from: lastFight, to: Date()).day
    }
}

// MARK: - Image Metadata
struct ImageMetadata: Codable {
    let width: Int
    let height: Int
    let fileSize: Int
    let takenAt: Date?
    let location: LocationData?
    
    init(width: Int, height: Int, fileSize: Int, takenAt: Date? = nil, location: LocationData? = nil) {
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.takenAt = takenAt
        self.location = location
    }
}

// MARK: - Location Data
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Gemini Analysis
struct GeminiAnalysis: Codable {
    let species: String
    let confidence: Double
    let analysisTimestamp: Date
    
    init(species: String, confidence: Double) {
        self.species = species
        self.confidence = confidence
        self.analysisTimestamp = Date()
    }
}

// MARK: - Firestore Codable Extensions
extension Spider {
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case species
        case deadlinessScore
        case imageUrl
        case imageMetadata
        case geminiAnalysis
        case createdAt
        case lastUsedInFight
        case isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        species = try container.decode(String.self, forKey: .species)
        deadlinessScore = try container.decode(Double.self, forKey: .deadlinessScore)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        imageMetadata = try container.decode(ImageMetadata.self, forKey: .imageMetadata)
        geminiAnalysis = try container.decode(GeminiAnalysis.self, forKey: .geminiAnalysis)
        
        // Handle Firestore Timestamps
        let createdAtTimestamp = try container.decode(Timestamp.self, forKey: .createdAt)
        createdAt = createdAtTimestamp.dateValue()
        
        if let lastUsedTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .lastUsedInFight) {
            lastUsedInFight = lastUsedTimestamp.dateValue()
        } else {
            lastUsedInFight = nil
        }
        
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(species, forKey: .species)
        try container.encode(deadlinessScore, forKey: .deadlinessScore)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(imageMetadata, forKey: .imageMetadata)
        try container.encode(geminiAnalysis, forKey: .geminiAnalysis)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        
        if let lastUsedInFight = lastUsedInFight {
            try container.encode(Timestamp(date: lastUsedInFight), forKey: .lastUsedInFight)
        }
        
        try container.encode(isActive, forKey: .isActive)
    }
}

// MARK: - Image Metadata Codable Extensions
extension ImageMetadata {
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case fileSize
        case takenAt
        case location
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        fileSize = try container.decode(Int.self, forKey: .fileSize)
        
        if let takenAtTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .takenAt) {
            takenAt = takenAtTimestamp.dateValue()
        } else {
            takenAt = nil
        }
        
        location = try container.decodeIfPresent(LocationData.self, forKey: .location)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(fileSize, forKey: .fileSize)
        
        if let takenAt = takenAt {
            try container.encode(Timestamp(date: takenAt), forKey: .takenAt)
        }
        
        try container.encodeIfPresent(location, forKey: .location)
    }
}

// MARK: - Gemini Analysis Codable Extensions
extension GeminiAnalysis {
    enum CodingKeys: String, CodingKey {
        case species
        case confidence
        case analysisTimestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        species = try container.decode(String.self, forKey: .species)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        let timestamp = try container.decode(Timestamp.self, forKey: .analysisTimestamp)
        analysisTimestamp = timestamp.dateValue()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(species, forKey: .species)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(Timestamp(date: analysisTimestamp), forKey: .analysisTimestamp)
    }
}
