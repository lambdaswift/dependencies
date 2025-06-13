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

private enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
}

private enum FeatureFlagsKey: DependencyKey {
    static let liveValue = FeatureFlags()
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

public struct Analytics: Sendable {
    public struct Event: Equatable, Sendable {
        public let name: String
        public let properties: [String: String]
        public let timestamp: Date
        
        public init(name: String, properties: [String: String] = [:], timestamp: Date = Date()) {
            self.name = name
            self.properties = properties
            self.timestamp = timestamp
        }
    }
    
    private let _track: @Sendable (Event) -> Void
    private let _identify: @Sendable (String, [String: String]) -> Void
    private let _reset: @Sendable () -> Void
    
    public init(
        track: @escaping @Sendable (Event) -> Void = { _ in },
        identify: @escaping @Sendable (String, [String: String]) -> Void = { _, _ in },
        reset: @escaping @Sendable () -> Void = { }
    ) {
        self._track = track
        self._identify = identify
        self._reset = reset
    }
    
    public func track(_ eventName: String, properties: [String: String] = [:]) {
        let event = Event(name: eventName, properties: properties)
        _track(event)
    }
    
    public func track(_ event: Event) {
        _track(event)
    }
    
    public func identify(userId: String, traits: [String: String] = [:]) {
        _identify(userId, traits)
    }
    
    public func reset() {
        _reset()
    }
}

public struct FeatureFlags: Sendable {
    private let _isEnabled: @Sendable (String) -> Bool
    private let _value: @Sendable (String) -> Any?
    private let _allFlags: @Sendable () -> [String: Any]
    
    public init(
        isEnabled: @escaping @Sendable (String) -> Bool = { _ in false },
        value: @escaping @Sendable (String) -> Any? = { _ in nil },
        allFlags: @escaping @Sendable () -> [String: Any] = { [:] }
    ) {
        self._isEnabled = isEnabled
        self._value = value
        self._allFlags = allFlags
    }
    
    public func isEnabled(_ flag: String) -> Bool {
        _isEnabled(flag)
    }
    
    public func value<T>(for flag: String, default defaultValue: T) -> T {
        if let value = _value(flag) as? T {
            return value
        }
        return defaultValue
    }
    
    public func string(for flag: String, default defaultValue: String = "") -> String {
        value(for: flag, default: defaultValue)
    }
    
    public func bool(for flag: String, default defaultValue: Bool = false) -> Bool {
        value(for: flag, default: defaultValue)
    }
    
    public func int(for flag: String, default defaultValue: Int = 0) -> Int {
        value(for: flag, default: defaultValue)
    }
    
    public func double(for flag: String, default defaultValue: Double = 0.0) -> Double {
        value(for: flag, default: defaultValue)
    }
    
    public var allFlags: [String: Any] {
        _allFlags()
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
    
    public var analytics: Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
    
    public var featureFlags: FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }
}