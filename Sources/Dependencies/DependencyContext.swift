import Foundation

final class DependencyContext: @unchecked Sendable {
    static let shared = DependencyContext()
    
    private let lock = NSRecursiveLock()
    private var stack: [DependencyValues] = []
    
    private init() {}
    
    var hasOverrides: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !stack.isEmpty
    }
    
    var current: DependencyValues {
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
}