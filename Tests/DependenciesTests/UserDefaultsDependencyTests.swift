import Testing
import Foundation
@testable import Dependencies

@Test func userDefaultsDependencyReturnsStandardUserDefaults() {
    struct TestView {
        @Dependency(\.userDefaults) var userDefaults
        
        func getDefaults() -> UserDefaults {
            userDefaults
        }
    }
    
    let view = TestView()
    let result = view.getDefaults()
    
    #expect(result === UserDefaults.standard)
}

@Test func userDefaultsDependencyCanBeOverriddenWithMock() {
    // Create a mock UserDefaults that tracks all operations
    final class MockUserDefaults: UserDefaults {
        var storage: [String: Any] = [:]
        var setCalls: [(key: String, value: Any?)] = []
        var getCalls: [String] = []
        
        override func set(_ value: Any?, forKey defaultName: String) {
            setCalls.append((key: defaultName, value: value))
            storage[defaultName] = value
        }
        
        override func string(forKey defaultName: String) -> String? {
            getCalls.append(defaultName)
            return storage[defaultName] as? String
        }
        
        override func bool(forKey defaultName: String) -> Bool {
            getCalls.append(defaultName)
            return storage[defaultName] as? Bool ?? false
        }
        
        override func integer(forKey defaultName: String) -> Int {
            getCalls.append(defaultName)
            return storage[defaultName] as? Int ?? 0
        }
    }
    
    struct SettingsView {
        @Dependency(\.userDefaults) var userDefaults
        
        func saveTheme(_ theme: String) {
            userDefaults.set(theme, forKey: "theme")
        }
        
        func getTheme() -> String? {
            userDefaults.string(forKey: "theme")
        }
        
        func toggleFeature() {
            let current = userDefaults.bool(forKey: "featureEnabled")
            userDefaults.set(!current, forKey: "featureEnabled")
        }
    }
    
    let mockDefaults = MockUserDefaults()
    
    withDependencies {
        $0.userDefaults = mockDefaults
    } operation: {
        let view = SettingsView()
        
        // Test saving theme
        view.saveTheme("dark")
        #expect(mockDefaults.setCalls.count == 1)
        #expect(mockDefaults.setCalls[0].key == "theme")
        #expect(mockDefaults.setCalls[0].value as? String == "dark")
        
        // Test getting theme
        let theme = view.getTheme()
        #expect(theme == "dark")
        #expect(mockDefaults.getCalls.contains("theme"))
        
        // Test toggle feature
        view.toggleFeature()
        #expect(mockDefaults.setCalls.count == 2)
        #expect(mockDefaults.setCalls[1].key == "featureEnabled")
        #expect(mockDefaults.setCalls[1].value as? Bool == true)
    }
}

@Test func userDefaultsDependencyForTestingWithIsolatedSuite() {
    struct PreferencesService {
        @Dependency(\.userDefaults) var userDefaults
        
        var userName: String? {
            get { userDefaults.string(forKey: "userName") }
            set { 
                if let newValue {
                    userDefaults.set(newValue, forKey: "userName")
                } else {
                    userDefaults.removeObject(forKey: "userName")
                }
            }
        }
        
        var launchCount: Int {
            get { userDefaults.integer(forKey: "launchCount") }
            set { userDefaults.set(newValue, forKey: "launchCount") }
        }
        
        mutating func incrementLaunchCount() {
            launchCount += 1
        }
    }
    
    // Create isolated test defaults with unique suite name
    let suiteName = "com.test.dependencies.\(UUID().uuidString)"
    guard let testDefaults = UserDefaults(suiteName: suiteName) else {
        Issue.record("Failed to create test UserDefaults")
        return
    }
    
    withDependencies {
        $0.userDefaults = testDefaults
    } operation: {
        var service = PreferencesService()
        
        // Test initial state
        #expect(service.userName == nil)
        #expect(service.launchCount == 0)
        
        // Test setting values
        service.userName = "Test User"
        service.incrementLaunchCount()
        
        #expect(service.userName == "Test User")
        #expect(service.launchCount == 1)
        
        // Test removing value
        service.userName = nil
        #expect(service.userName == nil)
    }
    
    // Clean up test suite
    testDefaults.removePersistentDomain(forName: suiteName)
}

@Test func userDefaultsDependencyOverrideAffectsOnlyOverriddenInstance() {
    struct TestService {
        @Dependency(\.userDefaults) var userDefaults
        let id = UUID()
        
        func saveId() {
            userDefaults.set(id.uuidString, forKey: "serviceId")
        }
        
        func readId() -> String? {
            userDefaults.string(forKey: "serviceId")
        }
    }
    
    // Create a mock that always returns a fixed value
    final class FixedValueDefaults: UserDefaults {
        let fixedValue: String
        
        init(fixedValue: String) {
            self.fixedValue = fixedValue
            super.init(suiteName: nil)!
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func string(forKey defaultName: String) -> String? {
            return fixedValue
        }
    }
    
    let mockDefaults = FixedValueDefaults(fixedValue: "mocked-value")
    
    // Service outside of override should use standard defaults
    let service1 = TestService()
    service1.saveId()
    
    // Service inside override should use mocked defaults
    let result = withDependencies {
        $0.userDefaults = mockDefaults
    } operation: {
        let service2 = TestService()
        return service2.readId()
    }
    
    #expect(result == "mocked-value")
    
    // Clean up
    UserDefaults.standard.removeObject(forKey: "serviceId")
}