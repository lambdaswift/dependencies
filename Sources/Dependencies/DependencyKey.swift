import Foundation

public protocol DependencyKey {
    associatedtype Value
    static var liveValue: Value { get }
}