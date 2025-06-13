import Foundation

final class DependencyContext: @unchecked Sendable {
    static let shared = DependencyContext()
    
    private let lock = NSRecursiveLock()
    private var stack: [DependencyValues] = []
    
    // Task-local storage for async contexts
    private static let taskLocalStorage = TaskLocalStorage()
    
    private init() {}
    
    var hasOverrides: Bool {
        // Check task-local storage if available
        if Self.taskLocalStorage.current != nil {
            return true
        }
        
        // Check thread-local stack
        lock.lock()
        defer { lock.unlock() }
        return !stack.isEmpty
    }
    
    var current: DependencyValues {
        // For async contexts, task-local values take precedence
        if let taskLocal = Self.taskLocalStorage.current {
            return taskLocal
        }
        
        // For sync contexts, return the top of the stack
        lock.lock()
        defer { lock.unlock() }
        
        if let last = stack.last {
            return last
        }
        
        return DependencyValues.live.withValue { $0 }
    }
    
    func withValues<R>(_ values: DependencyValues, operation: () throws -> R) rethrows -> R {
        lock.lock()
        stack.append(values)
        lock.unlock()
        
        defer {
            lock.lock()
            _ = stack.popLast()
            lock.unlock()
        }
        
        return try operation()
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func withValues<R>(_ values: DependencyValues, operation: () async throws -> R) async rethrows -> R {
        let mergedValues = mergeWithCurrent(values)
        return try await Self.taskLocalStorage.withValue(mergedValues) {
            try await operation()
        }
    }
    
    private func mergeWithCurrent(_ overrides: DependencyValues) -> DependencyValues {
        var merged = current
        for (key, value) in overrides.storage {
            merged.storage[key] = value
        }
        return merged
    }
}

// Task-local storage wrapper to handle availability
private final class TaskLocalStorage: @unchecked Sendable {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @TaskLocal static var taskLocalCurrent: DependencyValues?
    
    var current: DependencyValues? {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            return Self.taskLocalCurrent
        }
        return nil
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func withValue<R>(_ value: DependencyValues, operation: () async throws -> R) async rethrows -> R {
        try await Self.$taskLocalCurrent.withValue(value, operation: operation)
    }
}