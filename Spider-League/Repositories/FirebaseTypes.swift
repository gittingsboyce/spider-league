import Foundation
import FirebaseFirestore
import Combine

// MARK: - Firebase Service Errors
enum FirebaseServiceError: Error, LocalizedError {
    case userNotFound
    case spiderNotFound
    case challengeNotFound
    case fightNotFound
    case insufficientPermissions
    case networkError
    case invalidData
    case quotaExceeded
    case unauthenticated
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .spiderNotFound:
            return "Spider not found"
        case .challengeNotFound:
            return "Challenge not found"
        case .fightNotFound:
            return "Fight not found"
        case .insufficientPermissions:
            return "Insufficient permissions to perform this action"
        case .networkError:
            return "Network error occurred"
        case .invalidData:
            return "Invalid data provided"
        case .quotaExceeded:
            return "Firebase quota exceeded"
        case .unauthenticated:
            return "User not authenticated"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Firebase Query Options
struct FirebaseQueryOptions {
    let limit: Int?
    let orderBy: String?
    let orderDirection: Bool? // true for descending, false for ascending
    let startAfter: DocumentSnapshot?
    
    init(limit: Int? = nil, orderBy: String? = nil, orderDirection: Bool? = nil, startAfter: DocumentSnapshot? = nil) {
        self.limit = limit
        self.orderBy = orderBy
        self.orderDirection = orderDirection
        self.startAfter = startAfter
    }
    
    static let `default` = FirebaseQueryOptions(limit: 50, orderBy: "createdAt", orderDirection: true) // true = descending
}

// MARK: - Firebase Write Result
struct FirebaseWriteResult<T> {
    let success: Bool
    let data: T?
    let error: FirebaseServiceError?
    let documentId: String?
    
    init(success: Bool, data: T? = nil, error: FirebaseServiceError? = nil, documentId: String? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.documentId = documentId
    }
    
    static func success(data: T, documentId: String) -> FirebaseWriteResult<T> {
        return FirebaseWriteResult(success: true, data: data, documentId: documentId)
    }
    
    static func failure(error: FirebaseServiceError) -> FirebaseWriteResult<T> {
        return FirebaseWriteResult(success: false, error: error)
    }
}

// MARK: - Firebase Write Operation
struct FirebaseWriteOperation<T> {
    enum OperationType {
        case create(T)
        case update(T)
        case delete(String)
    }
    
    let type: OperationType
    let collection: String
    let documentId: String?
    
    init(type: OperationType, collection: String, documentId: String? = nil) {
        self.type = type
        self.collection = collection
        self.documentId = documentId
    }
}

// MARK: - Firebase Update Operation
struct FirebaseUpdateOperation<T> {
    let documentId: String
    let collection: String
    let updates: [String: Any]
    
    init(documentId: String, collection: String, updates: [String: Any]) {
        self.documentId = documentId
        self.collection = collection
        self.updates = updates
    }
}

// MARK: - Firebase Listener Protocol
protocol FirebaseListenerProtocol {
    func addListener<T: Codable>(for documentId: String, in collection: String) -> AnyPublisher<T, Never>
    func addQueryListener<T: Codable>(for collection: String, query: Query) -> AnyPublisher<[T], Never>
    func removeListener(for documentId: String, in collection: String)
    func removeAllListeners()
}

// MARK: - Firebase Batch Operations
protocol FirebaseBatchServiceProtocol {
    func batchWrite<T>(_ operations: [FirebaseWriteOperation<T>]) async throws -> FirebaseWriteResult<[T]>
    func batchUpdate<T>(_ updates: [FirebaseUpdateOperation<T>]) async throws -> FirebaseWriteResult<[T]>
    func batchDelete(_ documentIds: [String]) async throws -> FirebaseWriteResult<Void>
}
