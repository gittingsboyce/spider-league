import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    
    // MARK: - Properties
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            Text("Home View")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Spiders Tab
            Text("Spiders View")
                .tabItem {
                    Image(systemName: "spider.fill")
                    Text("Spiders")
                }
                .tag(1)
            
            // Challenges Tab
            Text("Challenges View")
                .tabItem {
                    Image(systemName: "sword.and.shield.fill")
                    Text("Challenges")
                }
                .tag(2)
            
            // Profile Tab
            Text("Profile View")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.orange) // Spider League brand color
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
