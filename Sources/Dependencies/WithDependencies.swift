import Foundation

public func withDependencies<R>(
    _ mutations: (inout DependencyValues) throws -> Void,
    operation: () throws -> R
) rethrows -> R {
    var values = DependencyValues()
    try mutations(&values)
    return try DependencyContext.shared.withValues(values, operation: operation)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func withDependencies<R>(
    _ mutations: (inout DependencyValues) throws -> Void,
    operation: () async throws -> R
) async rethrows -> R {
    var values = DependencyValues()
    try mutations(&values)
    return try await DependencyContext.shared.withValues(values, operation: operation)
}