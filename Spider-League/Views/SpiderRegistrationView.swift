import SwiftUI

// MARK: - Spider Registration View
struct SpiderRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var spiderName = ""
    @State private var spiderDescription = ""
    
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
                
                // Placeholder for image functionality
                Section("Spider Photo") {
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Image functionality coming soon")
                                        .foregroundColor(.gray)
                                }
                            )
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
                    .disabled(spiderName.isEmpty)
                }
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

// MARK: - Preview
struct SpiderRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        SpiderRegistrationView { spider in
            print("Spider created: \(spider.name)")
        }
    }
}
