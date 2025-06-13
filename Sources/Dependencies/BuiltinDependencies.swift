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
}