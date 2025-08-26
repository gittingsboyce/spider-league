import Foundation
import FirebaseStorage
import UIKit

// MARK: - Image Upload Service
class ImageUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    
    // MARK: - Public Methods
    
    /// Upload spider image to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - spiderId: Unique identifier for the spider
    ///   - quality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Download URL string
    func uploadSpiderImage(_ image: UIImage, spiderId: String, quality: CGFloat = 0.8) async throws -> String {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
            errorMessage = nil
        }
        
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: quality) else {
                throw ImageUploadError.imageConversionFailed
            }
            
            // Create storage reference
            let imageName = "spiders/\(spiderId)/\(UUID().uuidString).jpg"
            let imageRef = storage.reference().child(imageName)
            
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.cacheControl = "public, max-age=31536000" // 1 year cache
            
            // Upload with progress tracking
            let uploadTask = imageRef.putData(imageData, metadata: metadata)
            
            // Monitor upload progress
            uploadTask.observe(.progress) { snapshot in
                let progress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            
            // Wait for upload to complete using a continuation
            try await withCheckedThrowingContinuation { continuation in
                uploadTask.observe(.success) { _ in
                    continuation.resume()
                }
                
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ImageUploadError.uploadFailed)
                    }
                }
            }
            
            // Get download URL after upload is complete
            let downloadURL = try await imageRef.downloadURL()
            
            await MainActor.run {
                isUploading = false
                uploadProgress = 1.0
            }
            
            return downloadURL.absoluteString
            
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Delete spider image from Firebase Storage
    /// - Parameter imageUrl: Full URL of the image to delete
    func deleteSpiderImage(_ imageUrl: String) async throws {
        do {
            // Extract path from URL
            guard let url = URL(string: imageUrl),
                  let path = url.pathComponents.dropFirst(2).joined(separator: "/").removingPercentEncoding else {
                throw ImageUploadError.invalidImageUrl
            }
            
            let imageRef = storage.reference().child(path)
            try await imageRef.delete()
            
        } catch {
            throw ImageUploadError.deletionFailed(error)
        }
    }
    
    /// Get image size in MB
    func getImageSizeInMB(_ image: UIImage, quality: CGFloat = 0.8) -> Double {
        guard let data = image.jpegData(compressionQuality: quality) else { return 0.0 }
        return Double(data.count) / (1024 * 1024)
    }
    
    /// Validate image before upload
    func validateImage(_ image: UIImage) -> ImageValidationResult {
        let sizeInMB = getImageSizeInMB(image)
        
        // Check file size (max 10MB)
        if sizeInMB > 10.0 {
            return .failure(.fileTooLarge(sizeInMB))
        }
        
        // Check dimensions (min 100x100, max 4000x4000)
        let width = image.size.width
        let height = image.size.height
        
        if width < 100 || height < 100 {
            return .failure(.dimensionsTooSmall(width: Int(width), height: Int(height)))
        }
        
        if width > 4000 || height > 4000 {
            return .failure(.dimensionsTooLarge(width: Int(width), height: Int(height)))
        }
        
        return .success
    }
}

// MARK: - Image Upload Error
enum ImageUploadError: LocalizedError {
    case imageConversionFailed
    case invalidImageUrl
    case deletionFailed(Error)
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .invalidImageUrl:
            return "Invalid image URL"
        case .deletionFailed(let error):
            return "Failed to delete image: \(error.localizedDescription)"
        case .uploadFailed:
            return "Failed to upload image to storage"
        }
    }
}

// MARK: - Image Validation Result
enum ImageValidationResult {
    case success
    case failure(ImageValidationError)
}

// MARK: - Image Validation Error
enum ImageValidationError: LocalizedError {
    case fileTooLarge(Double)
    case dimensionsTooSmall(width: Int, height: Int)
    case dimensionsTooLarge(width: Int, height: Int)
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge(let size):
            return "Image file is too large (\(String(format: "%.1f", size))MB). Maximum size is 10MB."
        case .dimensionsTooSmall(let width, let height):
            return "Image dimensions are too small (\(width)x\(height)). Minimum size is 100x100 pixels."
        case .dimensionsTooLarge(let width, let height):
            return "Image dimensions are too large (\(width)x\(height)). Maximum size is 4000x4000 pixels."
        }
    }
}
