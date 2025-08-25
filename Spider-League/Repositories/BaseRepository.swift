import Foundation
import FirebaseFirestore
import Combine

// MARK: - Base Repository
class BaseRepository {
    
    // MARK: - Properties
    let db = Firestore.firestore()
    internal var listeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Collection Names
    enum Collection: String {
        case users = "users"
        case spiders = "spiders"
        case challenges = "challenges"
        case fights = "fights"
    }
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Deinitialization
    deinit {
        removeAllListeners()
    }
}

// MARK: - Basic CRUD Operations
extension BaseRepository {
    
    // MARK: - Create Document
    func createDocument<T: Codable>(_ data: T, in collection: Collection) async throws -> String {
        do {
            let documentRef = try await db.collection(collection.rawValue).addDocument(from: data)
            return documentRef.documentID
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Create Document with ID
    func createDocument<T: Codable>(_ data: T, withId id: String, in collection: Collection) async throws {
        do {
            try await db.collection(collection.rawValue).document(id).setData(from: data)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Read Document
    func readDocument<T: Codable>(_ type: T.Type, withId id: String, in collection: Collection) async throws -> T? {
        do {
            let document = try await db.collection(collection.rawValue).document(id).getDocument()
            
            if document.exists {
                return try document.data(as: type)
            } else {
                return nil
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Document
    func updateDocument<T: Codable>(_ data: T, withId id: String, in collection: Collection) async throws {
        do {
            try await db.collection(collection.rawValue).document(id).setData(from: data, merge: true)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Update Document Fields
    func updateDocumentFields(_ fields: [String: Any], withId id: String, in collection: Collection) async throws {
        do {
            try await db.collection(collection.rawValue).document(id).updateData(fields)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete Document
    func deleteDocument(withId id: String, in collection: Collection) async throws {
        do {
            try await db.collection(collection.rawValue).document(id).delete()
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Query Operations
extension BaseRepository {
    
    // MARK: - Query Documents
    func queryDocuments<T: Codable>(_ type: T.Type, in collection: Collection, where field: String, isEqualTo value: Any) async throws -> [T] {
        do {
            let querySnapshot = try await db.collection(collection.rawValue)
                .whereField(field, isEqualTo: value)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: type)
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Query Documents with Multiple Conditions
    func queryDocuments<T: Codable>(_ type: T.Type, in collection: Collection, where conditions: [(field: String, operator: QueryFilterOperator, value: Any)]) async throws -> [T] {
        do {
            var query: Query = db.collection(collection.rawValue)
            
            for condition in conditions {
                query = query.whereField(condition.field, condition.operator, condition.value)
            }
            
            let querySnapshot = try await query.getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: type)
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Query Documents with Options
    func queryDocuments<T: Codable>(_ type: T.Type, in collection: Collection, withOptions options: FirebaseQueryOptions) async throws -> [T] {
        do {
            var query: Query = db.collection(collection.rawValue)
            
            // Apply ordering
            if let orderBy = options.orderBy {
                if let direction = options.orderDirection {
                    query = query.order(by: orderBy, descending: direction)
                } else {
                    query = query.order(by: orderBy)
                }
            }
            
            // Apply limit
            if let limit = options.limit {
                query = query.limit(to: limit)
            }
            
            // Apply start after
            if let startAfter = options.startAfter {
                query = query.start(after: [startAfter])
            }
            
            let querySnapshot = try await query.getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: type)
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }
}

// MARK: - Real-time Listeners
extension BaseRepository {
    
    // MARK: - Add Document Listener
    func addDocumentListener<T: Codable>(_ type: T.Type, withId id: String, in collection: Collection) -> AnyPublisher<T, Never> {
        let subject = PassthroughSubject<T, Never>()
        
        let listener = db.collection(collection.rawValue).document(id)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error listening to document: \(error)")
                    return
                }
                
                guard let document = documentSnapshot else {
                    print("Document not found")
                    return
                }
                
                do {
                    let data = try document.data(as: type)
                    subject.send(data)
                } catch {
                    print("Error decoding document: \(error)")
                }
            }
        
        let listenerKey = "\(collection.rawValue)_\(id)"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Add Query Listener
    func addQueryListener<T: Codable>(_ type: T.Type, in collection: Collection, where field: String, isEqualTo value: Any) -> AnyPublisher<[T], Never> {
        let subject = PassthroughSubject<[T], Never>()
        
        let listener = db.collection(collection.rawValue)
            .whereField(field, isEqualTo: value)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening to query: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                do {
                    let data = try documents.compactMap { document in
                        try document.data(as: type)
                    }
                    subject.send(data)
                } catch {
                    print("Error decoding documents: \(error)")
                }
            }
        
        let listenerKey = "\(collection.rawValue)_query_\(field)_\(String(describing: value))"
        listeners[listenerKey] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Remove Listener
    func removeListener(for documentId: String, in collection: Collection) {
        let listenerKey = "\(collection.rawValue)_\(documentId)"
        listeners[listenerKey]?.remove()
        listeners.removeValue(forKey: listenerKey)
    }
    
    // MARK: - Remove All Listeners
    func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: - Batch Operations
extension BaseRepository {
    
    // MARK: - Batch Write
    func batchWrite<T: Encodable>(_ operations: [FirebaseWriteOperation<T>]) async throws -> FirebaseWriteResult<[T]> {
        do {
            let batch = db.batch()
            var results: [T] = []
            
            for operation in operations {
                let collectionRef = db.collection(operation.collection)
                
                switch operation.type {
                case .create(let data):
                    let docRef = operation.documentId != nil ? 
                        collectionRef.document(operation.documentId!) : 
                        collectionRef.document()
                    
                    try batch.setData(from: data, forDocument: docRef)
                    
                    if let documentId = operation.documentId {
                        results.append(data)
                    }
                    
                case .update(let data):
                    guard let documentId = operation.documentId else {
                        throw FirebaseServiceError.invalidData
                    }
                    
                    try batch.setData(from: data, forDocument: collectionRef.document(documentId), merge: true)
                    results.append(data)
                    
                case .delete(let documentId):
                    batch.deleteDocument(collectionRef.document(documentId))
                }
            }
            
            try await batch.commit()
            
            return FirebaseWriteResult.success(data: results, documentId: "")
        } catch {
            return FirebaseWriteResult.failure(error: mapFirebaseError(error))
        }
    }
}

// MARK: - Error Mapping
extension BaseRepository {
    
    func mapFirebaseError(_ error: Error) -> FirebaseServiceError {
        if let firestoreError = error as? FirestoreErrorCode {
            switch firestoreError.code {
            case .notFound:
                return .userNotFound
            case .permissionDenied:
                return .insufficientPermissions
            case .unauthenticated:
                return .unauthenticated
            case .resourceExhausted:
                return .quotaExceeded
            case .unavailable:
                return .networkError
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}

// MARK: - Query Filter Operators
enum QueryFilterOperator {
    case isEqualTo
    case isLessThan
    case isLessThanOrEqualTo
    case isGreaterThan
    case isGreaterThanOrEqualTo
    case arrayContains
    case arrayContainsAny
    case `in`
    case notIn
    
    var firestoreOperator: String {
        switch self {
        case .isEqualTo: return "=="
        case .isLessThan: return "<"
        case .isLessThanOrEqualTo: return "<="
        case .isGreaterThan: return ">"
        case .isGreaterThanOrEqualTo: return ">="
        case .arrayContains: return "array-contains"
        case .arrayContainsAny: return "array-contains-any"
        case .in: return "in"
        case .notIn: return "not-in"
        }
    }
}

// MARK: - Query Extension
extension Query {
    func whereField(_ field: String, _ op: QueryFilterOperator, _ value: Any) -> Query {
        switch op {
        case .isEqualTo:
            return whereField(field, isEqualTo: value)
        case .isLessThan:
            return whereField(field, isLessThan: value)
        case .isLessThanOrEqualTo:
            return whereField(field, isLessThanOrEqualTo: value)
        case .isGreaterThan:
            return whereField(field, isGreaterThan: value)
        case .isGreaterThanOrEqualTo:
            return whereField(field, isGreaterThanOrEqualTo: value)
        case .arrayContains:
            return whereField(field, arrayContains: value)
        case .arrayContainsAny:
            return whereField(field, arrayContainsAny: value as! [Any])
        case .in:
            return whereField(field, in: value as! [Any])
        case .notIn:
            return whereField(field, notIn: value as! [Any])
        }
    }
}
