import Testing
import Foundation
@testable import Dependencies

@Test func dateDependencyReturnsCurrentDateByDefault() {
    struct TestView {
        @Dependency(\.date) var date
        
        func getCurrentDate() -> Date {
            date()
        }
    }
    
    let view = TestView()
    let before = Date()
    let result = view.getCurrentDate()
    let after = Date()
    
    #expect(result >= before)
    #expect(result <= after)
}

@Test func dateDependencyCanBeOverridden() {
    struct TestView {
        @Dependency(\.date) var date
        
        func getCurrentDate() -> Date {
            date()
        }
    }
    
    let fixedDate = Date(timeIntervalSince1970: 1234567890)
    var overridden = DependencyValues()
    overridden.date = { fixedDate }
    
    let result = DependencyContext.shared.withValues(overridden) {
        let view = TestView()
        return view.getCurrentDate()
    }
    
    #expect(result == fixedDate)
}

@Test func dateDependencyOverrideIsScoped() {
    struct TestView {
        @Dependency(\.date) var date
        
        func getCurrentDate() -> Date {
            date()
        }
    }
    
    let fixedDate = Date(timeIntervalSince1970: 1234567890)
    var overridden = DependencyValues()
    overridden.date = { fixedDate }
    
    let view = TestView()
    
    let beforeOverride = view.getCurrentDate()
    #expect(beforeOverride != fixedDate)
    
    let duringOverride = DependencyContext.shared.withValues(overridden) {
        view.getCurrentDate()
    }
    #expect(duringOverride == fixedDate)
    
    let afterOverride = view.getCurrentDate()
    #expect(afterOverride != fixedDate)
}