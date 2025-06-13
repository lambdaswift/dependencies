import Foundation

private enum DateKey: DependencyKey {
    static let liveValue: @Sendable () -> Date = { Date() }
}

private enum UUIDKey: DependencyKey {
    static let liveValue: @Sendable () -> UUID = { UUID() }
}

private enum CalendarKey: DependencyKey {
    static let liveValue: Calendar = .current
}

private enum LocaleKey: DependencyKey {
    static let liveValue: Locale = .current
}

private enum RandomNumberGeneratorKey: DependencyKey {
    static let liveValue = RandomNumberGenerator()
}

private enum FileManagerKey: DependencyKey {
    static nonisolated(unsafe) let liveValue: FileManager = .default
}

private enum UserDefaultsKey: DependencyKey {
    static nonisolated(unsafe) let liveValue: UserDefaults = .standard
}

private enum URLSessionKey: DependencyKey {
    static let liveValue: URLSession = .shared
}

public struct RandomNumberGenerator: Sendable {
    private let _nextDouble: @Sendable () -> Double
    private let _nextInt: @Sendable (ClosedRange<Int>) -> Int
    private let _nextBool: @Sendable () -> Bool
    
    public init(
        nextDouble: @escaping @Sendable () -> Double = { Double.random(in: 0..<1) },
        nextInt: @escaping @Sendable (ClosedRange<Int>) -> Int = { Int.random(in: $0) },
        nextBool: @escaping @Sendable () -> Bool = { Bool.random() }
    ) {
        self._nextDouble = nextDouble
        self._nextInt = nextInt
        self._nextBool = nextBool
    }
    
    public func next() -> Double { _nextDouble() }
    public func next(in range: ClosedRange<Int>) -> Int { _nextInt(range) }
    public func nextBool() -> Bool { _nextBool() }
}

extension DependencyValues {
    public var date: @Sendable () -> Date {
        get { self[DateKey.self] }
        set { self[DateKey.self] = newValue }
    }
    
    public var uuid: @Sendable () -> UUID {
        get { self[UUIDKey.self] }
        set { self[UUIDKey.self] = newValue }
    }
    
    public var calendar: Calendar {
        get { self[CalendarKey.self] }
        set { self[CalendarKey.self] = newValue }
    }
    
    public var locale: Locale {
        get { self[LocaleKey.self] }
        set { self[LocaleKey.self] = newValue }
    }
    
    public var randomNumberGenerator: RandomNumberGenerator {
        get { self[RandomNumberGeneratorKey.self] }
        set { self[RandomNumberGeneratorKey.self] = newValue }
    }
    
    public var fileManager: FileManager {
        get { self[FileManagerKey.self] }
        set { self[FileManagerKey.self] = newValue }
    }
    
    public var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self] }
        set { self[UserDefaultsKey.self] = newValue }
    }
    
    public var urlSession: URLSession {
        get { self[URLSessionKey.self] }
        set { self[URLSessionKey.self] = newValue }
    }
}