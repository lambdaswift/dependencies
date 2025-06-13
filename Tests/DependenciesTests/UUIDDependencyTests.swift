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
    
    let result = withDependencies {
        $0.uuid = { fixedUUID }
    } operation: {
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
    
    let view = TestView()
    
    let beforeOverride = view.generateID()
    #expect(beforeOverride != fixedUUID)
    
    let duringOverride = withDependencies {
        $0.uuid = { fixedUUID }
    } operation: {
        view.generateID()
    }
    #expect(duringOverride == fixedUUID)
    
    let afterOverride = view.generateID()
    #expect(afterOverride != fixedUUID)
    #expect(afterOverride != beforeOverride)
}

