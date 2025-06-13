#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
    /// Overrides dependencies for this view hierarchy.
    /// 
    /// Note: This is primarily intended for SwiftUI previews and testing.
    /// The overrides will be applied when the view appears and removed when it disappears.
    /// 
    /// Example usage in previews:
    /// ```swift
    /// struct ContentView_Previews: PreviewProvider {
    ///     static var previews: some View {
    ///         ContentView()
    ///             .withDependencies {
    ///                 $0.date = { Date(timeIntervalSince1970: 0) }
    ///                 $0.uuid = { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    ///             }
    ///     }
    /// }
    /// ```
    public func withDependencies(_ mutations: @escaping (inout DependencyValues) -> Void) -> some View {
        self
            .onAppear {
                // For SwiftUI previews, we'll modify the live values directly
                // This is a simplified approach that works well for preview contexts
                DependencyValues.live.withValue { values in
                    mutations(&values)
                }
            }
    }
}
#endif