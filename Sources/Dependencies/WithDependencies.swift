import Foundation

public func withDependencies<R>(
    _ mutations: (inout DependencyValues) throws -> Void,
    operation: () throws -> R
) rethrows -> R {
    var values = DependencyValues()
    try mutations(&values)
    return try DependencyContext.shared.withValues(values, operation: operation)
}