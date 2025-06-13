import Testing
@testable import Dependencies

// MARK: - Test Dependencies

private struct AsyncTestService: Sendable {
    var value: Int
}

private enum AsyncTestServiceKey: DependencyKey {
    static let liveValue = AsyncTestService(value: 1)
}

extension DependencyValues {
    fileprivate var asyncTestService: AsyncTestService {
        get { self[AsyncTestServiceKey.self] }
        set { self[AsyncTestServiceKey.self] = newValue }
    }
}

private struct Counter: Sendable {
    var count: Int
}

private enum CounterKey: DependencyKey {
    static let liveValue = Counter(count: 0)
}

extension DependencyValues {
    fileprivate var counter: Counter {
        get { self[CounterKey.self] }
        set { self[CounterKey.self] = newValue }
    }
}

// MARK: - Tests

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Dependencies propagate across async boundaries")
func asyncDependenciesPropagateAcrossAsyncBoundaries() async throws {
    func checkService() -> Int {
        @Dependency(\.asyncTestService) var service
        return service.value
    }
    
    #expect(checkService() == 1)
    
    await withDependencies {
        $0.asyncTestService = AsyncTestService(value: 42)
    } operation: {
        #expect(checkService() == 42)
        
        let value = await Task {
            checkService()
        }.value
        #expect(value == 42)
        
        // Detached tasks don't inherit task-local context by design
        let detachedValue = await Task.detached {
            checkService()
        }.value
        #expect(detachedValue == 1) // Should use default value
    }
    
    #expect(checkService() == 1)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Nested async dependency overrides work correctly")
func nestedAsyncDependencyOverrides() async throws {
    func getCount() -> Int {
        @Dependency(\.counter) var counter
        return counter.count
    }
    
    #expect(getCount() == 0)
    
    await withDependencies {
        $0.counter = Counter(count: 10)
    } operation: {
        #expect(getCount() == 10)
        
        await withDependencies {
            $0.counter = Counter(count: 20)
        } operation: {
            #expect(getCount() == 20)
            
            let nestedValue = await Task {
                getCount()
            }.value
            #expect(nestedValue == 20)
        }
        
        #expect(getCount() == 10)
    }
    
    #expect(getCount() == 0)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Multiple concurrent tasks share same dependency context")
func concurrentTasksShareDependencyContext() async throws {
    actor TestActor {
        func getUUID() -> UUID {
            @Dependency(\.uuid) var uuid
            return uuid()
        }
    }
    
    let fixedUUID = UUID()
    let actor = TestActor()
    
    await withDependencies {
        $0.uuid = { fixedUUID }
    } operation: {
        async let uuid1 = actor.getUUID()
        async let uuid2 = actor.getUUID()
        async let uuid3 = actor.getUUID()
        
        let results = await [uuid1, uuid2, uuid3]
        
        #expect(results.allSatisfy { $0 == fixedUUID })
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Dependencies work across actor boundaries")
func dependenciesWorkAcrossActorBoundaries() async throws {
    actor DataStore {
        func getCurrentDate() -> Date {
            @Dependency(\.date) var date
            return date()
        }
    }
    
    let fixedDate = Date(timeIntervalSince1970: 0)
    let store = DataStore()
    
    await withDependencies {
        $0.date = { fixedDate }
    } operation: {
        let date = await store.getCurrentDate()
        #expect(date == fixedDate)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Dependencies persist through async operations")
func dependenciesPersistThroughAsyncOperations() async throws {
    func getUUID() async -> UUID {
        @Dependency(\.uuid) var uuid
        await Task.yield()
        return uuid()
    }
    
    let fixedUUID = UUID()
    
    await withDependencies {
        $0.uuid = { fixedUUID }
    } operation: {
        let uuid1 = await getUUID()
        let uuid2 = await getUUID()
        
        #expect(uuid1 == fixedUUID)
        #expect(uuid2 == fixedUUID)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@Test("Async: Concurrent async operations use same dependencies")
func concurrentAsyncOperationsUseSameDependencies() async throws {
    func fetchDate() async -> Date {
        @Dependency(\.date) var date
        return date()
    }
    
    let fixedDate = Date(timeIntervalSince1970: 1234567890)
    
    await withDependencies {
        $0.date = { fixedDate }
    } operation: {
        async let date1 = fetchDate()
        async let date2 = fetchDate()
        async let date3 = fetchDate()
        
        let dates = await [date1, date2, date3]
        
        #expect(dates.allSatisfy { $0 == fixedDate })
    }
}