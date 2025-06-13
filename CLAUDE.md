# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift Package Manager library named "Dependencies" that requires Swift 6.1 or later. The project uses Swift's new Testing framework (not XCTest) for unit tests.

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

- **Sources/Dependencies/**: Main library source code
  - Library target that can be imported by other Swift projects
  - Currently minimal implementation - appears to be a new project for dependency management
  
- **Tests/DependenciesTests/**: Test files using Swift Testing framework
  - Uses `import Testing` (Swift 6's new testing framework)
  - Test functions are marked with `@Test` attribute

## Important Notes

- This package produces a library product (not an executable)
- No external dependencies are currently defined
- The project appears to be in initial/template state with minimal implementation
- When adding new functionality, maintain Swift 6.1 compatibility
- Use the new Testing framework for all tests (not XCTest)