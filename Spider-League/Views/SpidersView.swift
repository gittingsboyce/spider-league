import SwiftUI

// Import our custom components

// MARK: - Spiders View
struct SpidersView: View {
    
    // MARK: - Properties
    private let serviceContainer: ServiceContainerProtocol = ServiceContainer.shared
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
                SpiderRegistrationView { spider in
                    // Add the new spider to the collection
                    Task {
                        await addSpider(spider)
                    }
                }
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
                    title: "Ready to Fight",
                    value: "\(userSpiders.filter { $0.canBeUsedInFight }.count)",
                    icon: "sword.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
    }
    

    
    // MARK: - Actions
    private func loadSpiders() async {
        isLoading = true
        
        do {
            // Load spiders from Firebase
            let spiders = try await serviceContainer.spiderRepository.getUserSpiders(userId: getCurrentUserId())
            
            await MainActor.run {
                self.userSpiders = spiders
                self.isLoading = false
            }
        } catch {
            print("Failed to load spiders from Firebase: \(error)")
            await MainActor.run {
                self.userSpiders = []
                self.isLoading = false
            }
        }
    }
    
    private func addSpider(_ spider: Spider) async {
        do {
            // Save spider to Firebase first
            let savedSpider = try await serviceContainer.spiderRepository.createSpider(spider)
            
            // Add the saved spider to the local collection
            await MainActor.run {
                userSpiders.append(savedSpider)
            }
        } catch {
            print("Failed to save spider to Firebase: \(error)")
            // Still add to local collection for now
            await MainActor.run {
                userSpiders.append(spider)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentUserId() -> String {
        // TODO: Get from authentication service
        // For now, return a placeholder
        return "current_user_id"
    }
}

// MARK: - Spider Card
struct SpiderCard: View {
    let spider: Spider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Spider Image
                if !spider.imageUrl.isEmpty {
                    AsyncImage(url: URL(string: spider.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(.circular)
                            )
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "spider.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                        )
                }
                
                VStack(spacing: 8) {
                    Text(spider.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let description = spider.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
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
                        Text(spider.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = spider.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
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
