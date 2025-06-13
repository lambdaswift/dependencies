import Foundation

@propertyWrapper
public struct Dependency<Value> {
    private let keyPath: WritableKeyPath<DependencyValues, Value>
    
    public init(_ keyPath: WritableKeyPath<DependencyValues, Value>) {
        self.keyPath = keyPath
    }
    
    public var wrappedValue: Value {
        get {
            if DependencyContext.shared.hasOverrides {
                return DependencyContext.shared.current[keyPath: keyPath]
            } else {
                return DependencyValues.live.withValue { $0[keyPath: keyPath] }
            }
        }
    }
}