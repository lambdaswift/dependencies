# Dependencies

A lightweight dependency injection library for Swift that provides a simple, type-safe way to manage dependencies in your applications. Perfect for improving testability and managing shared resources.

## Features

- 🎯 Simple property wrapper syntax: `@Dependency(\.uuid) var uuid`
- 🧪 Easy dependency overriding for tests and previews
- 📦 Built-in dependencies for common system services
- 🔧 Register your own custom dependencies
- 🚀 Type-safe and compile-time checked
- 🪶 Lightweight with minimal overhead

## Installation

### Swift Package Manager

Add Dependencies to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/lambdaswift/dependencies", from: "0.0.1")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["Dependencies"]
)
```

## Usage

### Basic Usage

Import the library and use the `@Dependency` property wrapper to inject dependencies:

```swift
import Dependencies

struct ContentView: View {
    @Dependency(\.date) var date
    @Dependency(\.uuid) var uuid
    
    var body: some View {
        VStack {
            Text("Current date: \(date())")
            Text("New UUID: \(uuid())")
        }
    }
}
```

### Built-in Dependencies

Dependencies comes with several built-in system dependencies:

- `\.date` - Current date provider (defaults to `Date.init`)
- `\.uuid` - UUID generator (defaults to `UUID.init`)
- `\.calendar` - Current calendar (defaults to `Calendar.current`)
- `\.locale` - Current locale (defaults to `Locale.current`)

### Overriding Dependencies

Override dependencies for testing or specific contexts:

```swift
// In tests
func testFeatureWithFixedDate() {
    withDependencies {
        $0.date = { Date(timeIntervalSince1970: 1234567890) }
    } operation: {
        let feature = MyFeature()
        // feature will use the fixed date
    }
}

// In SwiftUI previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .withDependencies {
                $0.uuid = { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
            }
    }
}
```

### Creating Custom Dependencies

Define your own dependencies by extending `DependencyValues`:

```swift
// 1. Define your dependency key
private enum APIClientKey: DependencyKey {
    static let liveValue = APIClient.live
}

// 2. Extend DependencyValues
extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

// 3. Use it in your code
struct MyService {
    @Dependency(\.apiClient) var apiClient
    
    func fetchData() async throws -> Data {
        try await apiClient.get("/data")
    }
}
```

### Live Application Overrides

You can also override dependencies at the application level:

```swift
@main
struct MyApp: App {
    init() {
        DependencyValues.live.date = {
            // Custom date logic for the entire app
            Date().addingTimeInterval(3600) // Always one hour ahead
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Testing

Dependencies makes testing easy by allowing you to control all external dependencies:

```swift
import XCTest
import Dependencies

final class MyFeatureTests: XCTestCase {
    func testFeatureWithMockedDependencies() {
        withDependencies {
            $0.date = { Date(timeIntervalSince1970: 0) }
            $0.uuid = { UUID(uuidString: "12345678-1234-1234-1234-123456789012")! }
            $0.apiClient = .mock
        } operation: {
            let feature = MyFeature()
            // All dependencies are now controlled
        }
    }
}
```

## Requirements

- Swift 6.1+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.