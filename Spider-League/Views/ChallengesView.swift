import SwiftUI

// MARK: - Challenges View
struct ChallengesView: View {
    
    // MARK: - Properties
    @State private var receivedChallenges: [Challenge] = []
    @State private var sentChallenges: [Challenge] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Challenge Type", selection: $selectedTab) {
                    Text("Received").tag(0)
                    Text("Sent").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    receivedChallengesView
                } else {
                    sentChallengesView
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Navigate to send challenge
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await loadChallenges()
            }
        }
        .onAppear {
            Task {
                await loadChallenges()
            }
        }
    }
    
    // MARK: - Received Challenges View
    private var receivedChallengesView: some View {
        Group {
            if isLoading {
                ProgressView("Loading challenges...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if receivedChallenges.isEmpty {
                emptyReceivedChallengesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(receivedChallenges) { challenge in
                            ReceivedChallengeCard(challenge: challenge)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Sent Challenges View
    private var sentChallengesView: some View {
        Group {
            if isLoading {
                ProgressView("Loading challenges...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sentChallenges.isEmpty {
                emptySentChallengesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sentChallenges) { challenge in
                            SentChallengeCard(challenge: challenge)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Empty Received Challenges View
    private var emptyReceivedChallengesView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sword.and.shield")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Challenges Received")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("When other fighters challenge you, they'll appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty Sent Challenges View
    private var emptySentChallengesView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "plus.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Challenges Sent")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Send your first challenge to start battling!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                // TODO: Navigate to send challenge
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Send Challenge")
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
    
    // MARK: - Actions
    private func loadChallenges() async {
        isLoading = true
        // TODO: Load challenges from ChallengeRepository
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        // Mock data for now
        receivedChallenges = [
            Challenge(
                challengerId: "opponent1",
                challengedId: "user1",
                challengerSpiderId: "spider1"
            ),
            Challenge(
                challengerId: "opponent2",
                challengedId: "user1",
                challengerSpiderId: "spider2"
            )
        ]
        
        sentChallenges = [
            Challenge(
                challengerId: "user1",
                challengedId: "opponent3",
                challengerSpiderId: "spider3"
            )
        ]
        
        isLoading = false
    }
}

// MARK: - Received Challenge Card
struct ReceivedChallengeCard: View {
    let challenge: Challenge
    @State private var showingResponse = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge from \(challenge.challengerId)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Status: \(challenge.status.displayText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
            }
            
            // Challenge Details
            VStack(spacing: 8) {
                HStack {
                    Text("Expires:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(challenge.formattedTimeUntilExpiry)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(expiryColor)
                }
                
                if let message = challenge.message {
                    HStack {
                        Text("Message:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Action Buttons
            if challenge.canBeAccepted {
                HStack(spacing: 12) {
                    Button("Accept") {
                        // TODO: Accept challenge
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
                    
                    Button("Decline") {
                        // TODO: Decline challenge
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            } else if challenge.status == .accepted {
                Text("Challenge Accepted!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            } else if challenge.status == .declined {
                Text("Challenge Declined")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            } else if challenge.isExpired {
                Text("Challenge Expired")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    private var statusIcon: String {
        switch challenge.status {
        case .pending:
            return "clock.fill"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .expired:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch challenge.status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .declined:
            return .red
        case .expired:
            return .secondary
        }
    }
    
    private var expiryColor: Color {
        if challenge.isExpired {
            return .red
        } else if challenge.hoursUntilExpiry < 2 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Sent Challenge Card
struct SentChallengeCard: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge to \(challenge.challengedId)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Status: \(challenge.status.displayText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
            }
            
            // Challenge Details
            VStack(spacing: 8) {
                HStack {
                    Text("Expires:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(challenge.formattedTimeUntilExpiry)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(expiryColor)
                }
                
                if let message = challenge.message {
                    HStack {
                        Text("Message:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Status Message
            if challenge.status == .pending {
                Text("Waiting for response...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            } else if challenge.status == .accepted {
                Text("Challenge Accepted!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            } else if challenge.status == .declined {
                Text("Challenge Declined")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            } else if challenge.isExpired {
                Text("Challenge Expired")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    private var statusIcon: String {
        switch challenge.status {
        case .pending:
            return "clock.fill"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .expired:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch challenge.status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .declined:
            return .red
        case .expired:
            return .secondary
        }
    }
    
    private var expiryColor: Color {
        if challenge.isExpired {
            return .red
        } else if challenge.hoursUntilExpiry < 2 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview
struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
    }
}
