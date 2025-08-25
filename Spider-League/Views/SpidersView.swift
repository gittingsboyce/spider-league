import SwiftUI

// MARK: - Spiders View
struct SpidersView: View {
    
    // MARK: - Properties
    @State private var userSpiders: [Spider] = []
    @State private var isLoading = false
    @State private var showingAddSpider = false
    @State private var selectedSpider: Spider?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading spiders...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if userSpiders.isEmpty {
                    emptyStateView
                } else {
                    spiderCollectionView
                }
            }
            .navigationTitle("My Spiders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSpider = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await loadSpiders()
            }
            .sheet(isPresented: $showingAddSpider) {
                AddSpiderView()
            }
            .sheet(item: $selectedSpider) { spider in
                SpiderDetailView(spider: spider)
            }
        }
        .onAppear {
            Task {
                await loadSpiders()
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "spider")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Spiders Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Register your first spider to start battling in the Spider League!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                showingAddSpider = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Register Your First Spider")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Spider Collection View
    private var spiderCollectionView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Statistics Section
                statisticsSection
                
                // Spiders Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(userSpiders) { spider in
                        SpiderCard(spider: spider) {
                            selectedSpider = spider
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Collection Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Spiders",
                    value: "\(userSpiders.count)",
                    icon: "spider.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active",
                    value: "\(userSpiders.filter { $0.isActive }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Score",
                    value: String(format: "%.1f", averageDeadlinessScore),
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    private var averageDeadlinessScore: Double {
        guard !userSpiders.isEmpty else { return 0.0 }
        let total = userSpiders.reduce(0.0) { $0 + $1.deadlinessScore }
        return total / Double(userSpiders.count)
    }
    
    // MARK: - Actions
    private func loadSpiders() async {
        isLoading = true
        // TODO: Load spiders from SpiderRepository
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        // Mock data for now
        userSpiders = [
            Spider(
                userId: "user1",
                species: "Black Widow",
                deadlinessScore: 85.0,
                imageUrl: "",
                imageMetadata: ImageMetadata(width: 800, height: 600, fileSize: 1024),
                geminiAnalysis: GeminiAnalysis(species: "Black Widow", confidence: 0.95)
            ),
            Spider(
                userId: "user1",
                species: "Brown Recluse",
                deadlinessScore: 75.0,
                imageUrl: "",
                imageMetadata: ImageMetadata(width: 800, height: 600, fileSize: 1024),
                geminiAnalysis: GeminiAnalysis(species: "Brown Recluse", confidence: 0.92)
            )
        ]
        
        isLoading = false
    }
}

// MARK: - Spider Card
struct SpiderCard: View {
    let spider: Spider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Spider Image Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "spider.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                    )
                
                VStack(spacing: 8) {
                    Text(spider.species)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("Score:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f", spider.deadlinessScore))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    // Status Indicator
                    HStack {
                        Circle()
                            .fill(spider.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(spider.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Add Spider View (Placeholder)
struct AddSpiderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Register New Spider")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Take a photo of a spider to register it in your collection")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Take Photo") {
                    // TODO: Implement camera functionality
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Spider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Spider Detail View (Placeholder)
struct SpiderDetailView: View {
    let spider: Spider
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Spider Image
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "spider.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)
                        )
                    
                    VStack(spacing: 16) {
                        Text(spider.species)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Deadliness Score: \(String(format: "%.0f", spider.deadlinessScore))")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        // Additional details would go here
                        Text("Registered: \(spider.createdAt, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Spider Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct SpidersView_Previews: PreviewProvider {
    static var previews: some View {
        SpidersView()
    }
}
