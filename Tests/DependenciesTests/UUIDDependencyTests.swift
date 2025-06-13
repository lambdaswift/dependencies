import Testing
import Foundation
@testable import Dependencies

@Test func uuidDependencyGeneratesUniqueIDs() {
    struct TestView {
        @Dependency(\.uuid) var uuid
        
        func generateID() -> UUID {
            uuid()
        }
    }
    
    let view = TestView()
    let id1 = view.generateID()
    let id2 = view.generateID()
    
    #expect(id1 != id2)
}

@Test func uuidDependencyCanBeOverridden() {
    struct TestView {
        @Dependency(\.uuid) var uuid
        
        func generateID() -> UUID {
            uuid()
        }
    }
    
    let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    var overridden = DependencyValues()
    overridden.uuid = { fixedUUID }
    
    let result = DependencyContext.shared.withValues(overridden) {
        let view = TestView()
        return view.generateID()
    }
    
    #expect(result == fixedUUID)
}

@Test func uuidDependencyOverrideIsScoped() {
    struct TestView {
        @Dependency(\.uuid) var uuid
        
        func generateID() -> UUID {
            uuid()
        }
    }
    
    let fixedUUID = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
    var overridden = DependencyValues()
    overridden.uuid = { fixedUUID }
    
    let view = TestView()
    
    let beforeOverride = view.generateID()
    #expect(beforeOverride != fixedUUID)
    
    let duringOverride = DependencyContext.shared.withValues(overridden) {
        view.generateID()
    }
    #expect(duringOverride == fixedUUID)
    
    let afterOverride = view.generateID()
    #expect(afterOverride != fixedUUID)
    #expect(afterOverride != beforeOverride)
}

