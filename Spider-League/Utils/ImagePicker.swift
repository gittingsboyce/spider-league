import SwiftUI
import UIKit
import PhotosUI

// MARK: - Image Picker
class ImagePicker: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isImagePickerPresented = false
    
    private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // MARK: - Public Methods
    
    func presentCamera() {
        sourceType = .camera
        isImagePickerPresented = true
    }
    
    func presentPhotoLibrary() {
        sourceType = .photoLibrary
        isImagePickerPresented = true
    }
    
    func createImagePickerController() -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        return picker
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
