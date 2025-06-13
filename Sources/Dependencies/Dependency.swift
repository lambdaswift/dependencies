import Foundation

@propertyWrapper
public struct Dependency<Value> {
    private let keyPath: WritableKeyPath<DependencyValues, Value>
    
    public init(_ keyPath: WritableKeyPath<DependencyValues, Value>) {
        self.keyPath = keyPath
    }
    
    public var wrappedValue: Value {
        get {
            DependencyContext.shared.current[keyPath: keyPath]
        }
    }
}