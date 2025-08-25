import SwiftUI

// MARK: - Home View
struct HomeView: View {
    
    // MARK: - Properties
    @State private var isReadyToFight = false
    @State private var recentChallenges: [Challenge] = []
    @State private var recentFights: [Fight] = []
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Status Section
                    statusSection
                    
                    // Quick Actions Section
                    quickActionsSection
                    
                    // Recent Activity Section
                    recentActivitySection
                    
                    // Ready to Fight Users Section
                    readyToFightSection
                }
                .padding()
            }
            .navigationTitle("Spider League")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Logo/Title
            HStack {
                Image(systemName: "spider.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading) {
                    Text("Spider League")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Ready to battle?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Welcome Message
            Text("Welcome back, Fighter!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    toggleFightStatus()
                }) {
                    Text(isReadyToFight ? "Not Ready" : "Ready to Fight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isReadyToFight ? Color.red : Color.green)
                        .cornerRadius(20)
                }
            }
            
            // Status Details
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(isReadyToFight ? "Ready to Fight" : "Not Ready")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isReadyToFight ? .green : .red)
                }
                
                Spacer()
                
                Image(systemName: isReadyToFight ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isReadyToFight ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Register New Spider
                QuickActionButton(
                    title: "Register Spider",
                    subtitle: "Add new fighter",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // TODO: Navigate to spider registration
                }
                
                // Find Opponents
                QuickActionButton(
                    title: "Find Opponents",
                    subtitle: "Ready to fight",
                    icon: "magnifyingglass",
                    color: .orange
                ) {
                    // TODO: Navigate to opponent search
                }
                
                // View Challenges
                QuickActionButton(
                    title: "View Challenges",
                    subtitle: "Pending fights",
                    icon: "sword.and.shield",
                    color: .purple
                ) {
                    // TODO: Navigate to challenges
                }
                
                // Fight History
                QuickActionButton(
                    title: "Fight History",
                    subtitle: "Past battles",
                    icon: "clock.arrow.circlepath",
                    color: .green
                ) {
                    // TODO: Navigate to fight history
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full activity view
                }
                .font(.subheadline)
                .foregroundColor(.orange)
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if recentChallenges.isEmpty && recentFights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start by registering a spider or sending a challenge!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
            } else {
                VStack(spacing: 12) {
                    // Recent Challenges
                    if !recentChallenges.isEmpty {
                        ForEach(recentChallenges.prefix(3)) { challenge in
                            RecentActivityRow(
                                title: "Challenge from \(challenge.challengerId)",
                                subtitle: challenge.status.displayText,
                                icon: "sword.and.shield",
                                color: challenge.status == .pending ? .orange : .secondary
                            )
                        }
                    }
                    
                    // Recent Fights
                    if !recentFights.isEmpty {
                        ForEach(recentFights.prefix(3)) { fight in
                            RecentActivityRow(
                                title: "Fight completed",
                                subtitle: fight.isDraw ? "Draw" : "Winner: \(fight.winnerId)",
                                icon: "trophy.fill",
                                color: fight.isDraw ? .yellow : .green
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Ready to Fight Users Section
    private var readyToFightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ready to Fight")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full opponent list
                }
                .font(.subheadline)
                .foregroundColor(.orange)
            }
            
            // Placeholder for ready users
            VStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                
                Text("No opponents ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Check back later for new challengers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Actions
    private func toggleFightStatus() {
        isReadyToFight.toggle()
        // TODO: Update user status in Firebase
    }
    
    private func refreshData() async {
        isLoading = true
        // TODO: Refresh data from repositories
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        isLoading = false
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
