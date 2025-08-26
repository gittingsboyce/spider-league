import SwiftUI
import UIKit

// MARK: - Spider Registration View
struct SpiderRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imagePicker = ImagePicker()
    
    // Services
    private let serviceContainer = ServiceContainer.shared
    
    // Form state
    @State private var spiderName = ""
    @State private var spiderDescription = ""
    @State private var showingImageSourceAlert = false
    @State private var isUploading = false
    @State private var errorMessage = ""

    // Callback for when spider is created
    let onSpiderCreated: (Spider) -> Void
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Spider Details Section
                Section("Spider Details") {
                    TextField("Spider Name", text: $spiderName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (optional)", text: $spiderDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                                // Image Section
                Section("Spider Photo") {
                    VStack(spacing: 16) {
                        if let selectedImage = imagePicker.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("Tap to add photo")
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                        
                        Button(action: { showingImageSourceAlert = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(imagePicker.selectedImage == nil ? "Add Photo" : "Change Photo")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Register Spider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createSpider) {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(spiderName.isEmpty || imagePicker.selectedImage == nil || isUploading)
                }
            }
            .alert("Add Photo", isPresented: $showingImageSourceAlert) {
                Button("Camera") {
                    imagePicker.presentCamera()
                }
                Button("Photo Library") {
                    imagePicker.presentPhotoLibrary()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose how you want to add a photo of your spider")
            }
            .sheet(isPresented: $imagePicker.isImagePickerPresented) {
                ImagePickerSheet(imagePicker: imagePicker)
            }
            .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
                Button("OK") {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createSpider() {
        Task {
            do {
                // Show loading state
                await MainActor.run {
                    isUploading = true
                }
                
                guard let selectedImage = imagePicker.selectedImage else {
                    await MainActor.run {
                        isUploading = false
                        errorMessage = "No image selected"
                    }
                    return
                }
                
                // Upload image to Firebase Storage
                let imageUploadService = ImageUploadService()
                let imageUrl = try await imageUploadService.uploadSpiderImage(
                    selectedImage,
                    spiderId: UUID().uuidString,
                    quality: 0.8
                )
                
                // Create image metadata
                let imageMetadata = ImageMetadata(
                    width: Int(selectedImage.size.width),
                    height: Int(selectedImage.size.height),
                    fileSize: Int(imageUploadService.getImageSizeInMB(selectedImage) * 1024 * 1024)
                )
                
                // Get current user ID
                guard let userId = await getCurrentUserId() else {
                    await MainActor.run {
                        isUploading = false
                        errorMessage = "Failed to get current user"
                    }
                    return
                }
                
                // Create spider with real image data
                let spider = Spider(
                    id: UUID().uuidString,
                    userId: userId,
                    name: spiderName,
                    description: spiderDescription.isEmpty ? nil : spiderDescription,
                    imageUrl: imageUrl,
                    imageMetadata: imageMetadata,
                    geminiAnalysis: nil,
                    isActive: true,
                    lastUsed: nil,
                    createdAt: Date()
                )
                
                // Call callback on main thread
                await MainActor.run {
                    onSpiderCreated(spider)
                    isUploading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getCurrentUserId() async -> String? {
        do {
            let currentUser = try await serviceContainer.userRepository.getCurrentUser()
            return currentUser?.id
        } catch {
            print("Failed to get current user: \(error)")
            return nil
        }
    }
}

// MARK: - Image Picker Sheet
struct ImagePickerSheet: UIViewControllerRepresentable {
    @ObservedObject var imagePicker: ImagePicker
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        return imagePicker.createImagePickerController()
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
struct SpiderRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        SpiderRegistrationView { spider in
            print("Spider created: \(spider.name)")
        }
    }
}
