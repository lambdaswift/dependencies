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

private enum NotificationCenterKey: DependencyKey {
    static let liveValue: NotificationCenter = .default
}

private enum LoggerKey: DependencyKey {
    static let liveValue = Logger()
}

public struct Logger: Sendable {
    public enum Level: String, Sendable {
        case debug
        case info
        case warning
        case error
        case critical
    }
    
    private let _log: @Sendable (Level, String, String, String, Int) -> Void
    
    public init(
        log: @escaping @Sendable (Level, String, String, String, Int) -> Void = { level, message, file, function, line in
            print("[\(level.rawValue.uppercased())] \(file.split(separator: "/").last ?? ""):\(line) \(function) - \(message)")
        }
    ) {
        self._log = log
    }
    
    public func log(
        _ level: Level,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        _log(level, message, file, function, line)
    }
    
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    public func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.critical, message, file: file, function: function, line: line)
    }
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
    
    public var notificationCenter: NotificationCenter {
        get { self[NotificationCenterKey.self] }
        set { self[NotificationCenterKey.self] = newValue }
    }
    
    public var logger: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}