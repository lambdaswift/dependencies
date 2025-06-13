import Testing
import Foundation
@testable import Dependencies

@Test func withDependenciesOverridesSingleDependency() {
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

@Test func withDependenciesOverridesMultipleDependencies() {
    struct TestView {
        @Dependency(\.date) var date
        @Dependency(\.uuid) var uuid
        @Dependency(\.locale) var locale
        
        func getValues() -> (Date, UUID, String) {
            (date(), uuid(), locale.identifier)
        }
    }
    
    let fixedDate = Date(timeIntervalSince1970: 1234567890)
    let fixedUUID = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
    let japaneseLocale = Locale(identifier: "ja_JP")
    
    let result = withDependencies {
        $0.date = { fixedDate }
        $0.uuid = { fixedUUID }
        $0.locale = japaneseLocale
    } operation: {
        let view = TestView()
        return view.getValues()
    }
    
    #expect(result.0 == fixedDate)
    #expect(result.1 == fixedUUID)
    #expect(result.2 == "ja_JP")
}

@Test func withDependenciesIsScoped() {
    struct TestView {
        @Dependency(\.uuid) var uuid
        
        func generateID() -> UUID {
            uuid()
        }
    }
    
    let fixedUUID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
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

@Test func withDependenciesNested() {
    struct TestView {
        @Dependency(\.date) var date
        
        func getCurrentDate() -> Date {
            date()
        }
    }
    
    let outerDate = Date(timeIntervalSince1970: 1000)
    let innerDate = Date(timeIntervalSince1970: 2000)
    
    let result = withDependencies {
        $0.date = { outerDate }
    } operation: {
        let view = TestView()
        let outerResult = view.getCurrentDate()
        
        let innerResult = withDependencies {
            $0.date = { innerDate }
        } operation: {
            view.getCurrentDate()
        }
        
        let afterInnerResult = view.getCurrentDate()
        
        return (outerResult, innerResult, afterInnerResult)
    }
    
    #expect(result.0 == outerDate)
    #expect(result.1 == innerDate)
    #expect(result.2 == outerDate)
}

