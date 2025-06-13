import Testing
@testable import Dependencies

@Test func dependencyValuesStoresAndRetrievesValues() {
    var values = DependencyValues()
    
    enum TestKey: DependencyKey {
        static let liveValue = "default"
    }
    
    #expect(values[TestKey.self] == "default")
    
    values[TestKey.self] = "custom"
    #expect(values[TestKey.self] == "custom")
}

@Test func dependencyValuesReturnsLiveValueWhenNotSet() {
    let values = DependencyValues()
    
    enum TestKey: DependencyKey {
        static let liveValue = 42
    }
    
    #expect(values[TestKey.self] == 42)
}

@Test func dependencyValuesHandlesMultipleKeys() {
    var values = DependencyValues()
    
    enum StringKey: DependencyKey {
        static let liveValue = "string"
    }
    
    enum IntKey: DependencyKey {
        static let liveValue = 123
    }
    
    values[StringKey.self] = "modified"
    values[IntKey.self] = 456
    
    #expect(values[StringKey.self] == "modified")
    #expect(values[IntKey.self] == 456)
}