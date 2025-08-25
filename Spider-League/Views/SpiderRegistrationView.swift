import SwiftUI
import UIKit

// MARK: - Spider Registration View
struct SpiderRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imagePicker = ImagePicker()
    
    // Form state
    @State private var spiderName = ""
    @State private var spiderDescription = ""
    @State private var showingImageSourceAlert = false

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
                    Button("Save") {
                        createSpider()
                    }
                    .disabled(spiderName.isEmpty || imagePicker.selectedImage == nil)
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
        }
    }
    
    // MARK: - Private Methods
    
    private func createSpider() {
        // Create a simple spider for now
        let spider = Spider(
            id: UUID().uuidString,
            userId: getCurrentUserId(),
            name: spiderName,
            description: spiderDescription.isEmpty ? nil : spiderDescription,
            imageUrl: "", // Placeholder
            imageMetadata: ImageMetadata(width: 0, height: 0, fileSize: 0),
            geminiAnalysis: nil,
            isActive: true,
            lastUsed: nil,
            createdAt: Date()
        )
        
        // Call callback
        onSpiderCreated(spider)
        
        // Dismiss view
        dismiss()
    }
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
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
