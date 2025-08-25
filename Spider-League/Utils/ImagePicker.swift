import SwiftUI
import UIKit
import PhotosUI

// MARK: - Image Picker Service
class ImagePicker: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isImagePickerPresented = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera
    
    // Image picker controller
    private var imagePickerController: UIImagePickerController?
    
    // MARK: - Public Methods
    
    /// Present camera picker
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        sourceType = .camera
        isImagePickerPresented = true
    }
    
    /// Present photo library picker
    func presentPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("Photo library not available")
            return
        }
        
        sourceType = .photoLibrary
        isImagePickerPresented = true
    }
    
    /// Create and configure image picker controller
    func createImagePickerController() -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image"]
        
        // Set camera quality
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }
        
        return picker
    }
    
    /// Clear selected image
    func clearSelectedImage() {
        selectedImage = nil
    }
    
    /// Get image data for upload
    func getImageData(quality: CGFloat = 0.8) -> Data? {
        return selectedImage?.jpegData(compressionQuality: quality)
    }
    
    /// Get image metadata
    func getImageMetadata() -> ImageMetadata? {
        guard let image = selectedImage else { return nil }
        
        return ImageMetadata(
            width: Int(image.size.width),
            height: Int(image.size.height),
            fileSize: getImageData()?.count ?? 0,
            takenAt: Date(),
            location: nil // TODO: Add location support later
        )
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        isImagePickerPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isImagePickerPresented = false
    }
}
