import Foundation
import Combine

// MARK: - Service Container
class ServiceContainer: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = ServiceContainer()
    
    // MARK: - Repositories
    let userRepository: UserRepository
    let spiderRepository: SpiderRepository
    let challengeRepository: ChallengeRepository
    let fightRepository: FightRepository
    
    // MARK: - Private Initializer
    private init() {
        // Initialize repositories
        self.userRepository = UserRepository()
        self.spiderRepository = SpiderRepository()
        self.challengeRepository = ChallengeRepository()
        self.fightRepository = FightRepository()
    }
    
    // MARK: - Reset (for testing)
    func reset() {
        // Reset all repositories to clean state
        userRepository.removeAllListeners()
        spiderRepository.removeAllListeners()
        challengeRepository.removeAllListeners()
        fightRepository.removeAllListeners()
    }
}

// MARK: - Service Container Protocol
protocol ServiceContainerProtocol {
    var userRepository: UserRepository { get }
    var spiderRepository: SpiderRepository { get }
    var challengeRepository: ChallengeRepository { get }
    var fightRepository: FightRepository { get }
}

// MARK: - Service Container Extension
extension ServiceContainer: ServiceContainerProtocol {}
