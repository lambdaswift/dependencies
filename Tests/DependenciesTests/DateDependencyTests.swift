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
    
    let result = withDependencies {
        $0.date = { fixedDate }
    } operation: {
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
    let view = TestView()
    
    let beforeOverride = view.getCurrentDate()
    #expect(abs(beforeOverride.timeIntervalSince1970 - fixedDate.timeIntervalSince1970) > 1000)
    
    let duringOverride = withDependencies {
        $0.date = { fixedDate }
    } operation: {
        view.getCurrentDate()
    }
    #expect(duringOverride == fixedDate)
    
    let afterOverride = view.getCurrentDate()
    #expect(abs(afterOverride.timeIntervalSince1970 - fixedDate.timeIntervalSince1970) > 1000)
}