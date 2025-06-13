import Testing
@testable import Dependencies

struct TestService {
    var value: String
}

private enum TestServiceKey: DependencyKey {
    static let liveValue = TestService(value: "live")
}

extension DependencyValues {
    var testService: TestService {
        get { self[TestServiceKey.self] }
        set { self[TestServiceKey.self] = newValue }
    }
}

@Test func dependencyPropertyWrapperReadsFromCurrentContext() {
    struct TestView {
        @Dependency(\.testService) var service
        
        func getValue() -> String {
            service.value
        }
    }
    
    let view = TestView()
    #expect(view.getValue() == "live")
}

@Test func dependencyPropertyWrapperUsesOverriddenValues() {
    struct TestView {
        @Dependency(\.testService) var service
        
        func getValue() -> String {
            service.value
        }
    }
    
    let result = withDependencies {
        $0.testService = TestService(value: "overridden")
    } operation: {
        let view = TestView()
        return view.getValue()
    }
    
    #expect(result == "overridden")
}