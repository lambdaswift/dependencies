# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift Package Manager library named "Dependencies" that provides dependency injection functionality for Swift applications. It requires Swift 6.1 or later and uses Swift's new Testing framework (not XCTest) for unit tests.

The library allows users to:
- Inject dependencies using the `@Dependency` property wrapper
- Override dependencies for testing and previews
- Register custom dependencies
- Use built-in system dependencies (date, uuid, calendar, locale)

## Key Commands

### Build Commands
```bash
swift build                    # Build the package
swift build -c release         # Build in release mode
swift build --clean           # Clean build artifacts
```

### Test Commands
```bash
swift test                     # Run all tests
swift test --verbose          # Run tests with verbose output
swift test --filter TestName  # Run specific test by name
```

### Development Commands
```bash
open Package.swift            # Open in Xcode
swift package generate-xcodeproj  # Generate Xcode project if needed
swift package resolve         # Resolve package dependencies
swift package update         # Update dependencies
```

## Architecture & Structure

The project follows standard Swift Package Manager conventions:

### Core Components

- **DependencyKey.swift**: Protocol for defining dependency keys with live values
- **DependencyValues.swift**: Storage container for dependency values with thread-safe access
- **Dependency.swift**: Property wrapper for injecting dependencies
- **DependencyContext.swift**: Manages scoped dependency overrides
- **WithDependencies.swift**: Function for overriding dependencies in a scope
- **BuiltinDependencies.swift**: Built-in dependencies (date, uuid, calendar, locale)
- **SwiftUIIntegration.swift**: SwiftUI view modifier for previews

### Thread Safety

- Uses `NSRecursiveLock` for synchronization
- `LockIsolated` wrapper ensures thread-safe access to shared state
- All types are designed to be `Sendable` compliant for Swift 6 concurrency

### Testing

- Uses Swift's new Testing framework (`import Testing`)
- Test functions use `@Test` attribute
- Comprehensive test coverage for all components
- Tests verify scoped overrides, thread safety, and built-in dependencies

## Usage Patterns

### Basic Dependency Injection
```swift
struct MyView {
    @Dependency(\.date) var date
    @Dependency(\.uuid) var uuid
}
```

### Custom Dependencies
```swift
// 1. Define key
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
```

### Testing with Overrides
```swift
withDependencies {
    $0.date = { Date(timeIntervalSince1970: 0) }
} operation: {
    // Test code here
}
```

## Important Notes

- This package produces a library product (not an executable)
- No external dependencies are required
- Thread-safe by design for concurrent access
- SwiftUI integration is conditionally compiled with `#if canImport(SwiftUI)`
- Built-in dependencies use `@Sendable` closures for date/uuid generation