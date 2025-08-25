import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    
    // MARK: - Properties
    @State private var user: SpiderLeagueUser?
    @State private var isLoading = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading profile...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let user = user {
                        // Profile Header
                        profileHeader(user: user)
                        
                        // Fight Statistics
                        fightStatisticsSection(user: user)
                        
                        // Profile Actions
                        profileActionsSection
                        
                        // Settings Section
                        settingsSection
                    } else {
                        // Error or no user state
                        noUserState
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .refreshable {
                await loadProfile()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            Task {
                await loadProfile()
            }
        }
    }
    
    // MARK: - Profile Header
    private func profileHeader(user: SpiderLeagueUser) -> some View {
        VStack(spacing: 20) {
            // Profile Image
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                )
            
            // User Info
            VStack(spacing: 8) {
                Text(user.fightName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(user.town)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Status Badge
            HStack {
                Circle()
                    .fill(user.isReadyToFight ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(user.status.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(user.isReadyToFight ? .green : .red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Fight Statistics Section
    private func fightStatisticsSection(user: SpiderLeagueUser) -> some View {
        VStack(spacing: 16) {
            Text("Fight Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Wins",
                    value: "\(user.wins)",
                    icon: "trophy.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Losses",
                    value: "\(user.losses)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Win %",
                    value: String(format: "%.1f%%", user.winPercentage),
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
            
            // Total Fights
            HStack {
                Text("Total Fights:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(user.totalFights)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Profile Actions Section
    private var profileActionsSection: some View {
        VStack(spacing: 16) {
            Text("Profile Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ProfileActionButton(
                    title: "Change Fight Name",
                    subtitle: "Update your display name",
                    icon: "pencil",
                    color: .blue
                ) {
                    showingEditProfile = true
                }
                
                ProfileActionButton(
                    title: "Update Town",
                    subtitle: "Change your location",
                    icon: "location",
                    color: .green
                ) {
                    // TODO: Navigate to town update
                }
                
                ProfileActionButton(
                    title: "Change Profile Picture",
                    subtitle: "Upload new avatar",
                    icon: "camera",
                    color: .purple
                ) {
                    // TODO: Navigate to image picker
                }
                
                ProfileActionButton(
                    title: "Toggle Fight Status",
                    subtitle: user?.isReadyToFight == true ? "Set to Not Ready" : "Set to Ready to Fight",
                    icon: user?.isReadyToFight == true ? "xmark.circle" : "checkmark.circle",
                    color: user?.isReadyToFight == true ? .red : .green
                ) {
                    toggleFightStatus()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ProfileActionButton(
                    title: "App Settings",
                    subtitle: "Notifications, privacy, etc.",
                    icon: "gear",
                    color: .gray
                ) {
                    showingSettings = true
                }
                
                ProfileActionButton(
                    title: "Help & Support",
                    subtitle: "Get help with the app",
                    icon: "questionmark.circle",
                    color: .blue
                ) {
                    // TODO: Navigate to help
                }
                
                ProfileActionButton(
                    title: "About Spider League",
                    subtitle: "App version and info",
                    icon: "info.circle",
                    color: .orange
                ) {
                    // TODO: Show about info
                }
                
                ProfileActionButton(
                    title: "Sign Out",
                    subtitle: "Log out of your account",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: .red
                ) {
                    // TODO: Sign out
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - No User State
    private var noUserState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Profile Not Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Unable to load your profile. Please try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry") {
                Task {
                    await loadProfile()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.orange)
            .cornerRadius(12)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func loadProfile() async {
        isLoading = true
        // TODO: Load user profile from UserRepository
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        // Mock data for now
        user = SpiderLeagueUser(
            id: "user1",
            email: "fighter@spiderleague.com",
            fightName: "SpiderSlayer",
            town: "Encinitas, CA"
        )
        
        isLoading = false
    }
    
    private func toggleFightStatus() {
        guard var currentUser = user else { return }
        currentUser.status = currentUser.isReadyToFight ? .notReady : .ready
        user = currentUser
        // TODO: Update user status in Firebase
    }
}

// MARK: - Profile Action Button
struct ProfileActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
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
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View (Placeholder)
struct EditProfileView: View {
    let user: SpiderLeagueUser?
    @Environment(\.dismiss) private var dismiss
    @State private var fightName = ""
    @State private var town = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Fight Name") {
                    TextField("Enter fight name", text: $fightName)
                }
                
                Section("Town") {
                    TextField("Enter your town", text: $town)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save changes
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            fightName = user?.fightName ?? ""
            town = user?.town ?? ""
        }
    }
}

// MARK: - Settings View (Placeholder)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Sound Effects", isOn: $soundEnabled)
                }
                
                Section("Privacy") {
                    Toggle("Show Online Status", isOn: .constant(true))
                    Toggle("Allow Challenges", isOn: .constant(true))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
