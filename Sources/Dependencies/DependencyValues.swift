import Foundation

public struct DependencyValues {
    private var storage: [ObjectIdentifier: Any] = [:]
    
    public static let live = LockIsolated(DependencyValues())
    
    public init() {}
    
    public subscript<K: DependencyKey>(key: K.Type) -> K.Value {
        get {
            if let value = storage[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return K.liveValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}

public final class LockIsolated<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSRecursiveLock()
    
    public init(_ value: Value) {
        self._value = value
    }
    
    public func withValue<T>(_ operation: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation(&_value)
    }
    
    public var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}