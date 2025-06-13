import Testing
import Foundation
@testable import Dependencies

@Test func calendarDependencyReturnsCurrentCalendarByDefault() {
    struct TestView {
        @Dependency(\.calendar) var calendar
        
        func getCalendar() -> Calendar {
            calendar
        }
    }
    
    let view = TestView()
    let result = view.getCalendar()
    
    #expect(result == Calendar.current)
}

@Test func calendarDependencyCanBeOverridden() {
    struct TestView {
        @Dependency(\.calendar) var calendar
        
        func getCalendar() -> Calendar {
            calendar
        }
    }
    
    var customCalendar = Calendar(identifier: .japanese)
    customCalendar.firstWeekday = 2
    
    let result = withDependencies {
        $0.calendar = customCalendar
    } operation: {
        let view = TestView()
        return view.getCalendar()
    }
    
    #expect(result.identifier == .japanese)
    #expect(result.firstWeekday == 2)
}

@Test func calendarDependencyOverrideIsScoped() {
    struct TestView {
        @Dependency(\.calendar) var calendar
        
        func getCalendar() -> Calendar {
            calendar
        }
    }
    
    let customCalendar = Calendar(identifier: .buddhist)
    
    let view = TestView()
    
    let beforeOverride = view.getCalendar()
    #expect(beforeOverride.identifier != .buddhist)
    
    let duringOverride = withDependencies {
        $0.calendar = customCalendar
    } operation: {
        view.getCalendar()
    }
    #expect(duringOverride.identifier == .buddhist)
    
    let afterOverride = view.getCalendar()
    #expect(afterOverride.identifier != .buddhist)
}

@Test func calendarDependencyWorksWithDateCalculations() {
    struct TestView {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date) var date
        
        func getStartOfDay() -> Date {
            calendar.startOfDay(for: date())
        }
    }
    
    let fixedDate = Date(timeIntervalSince1970: 1234567890)
    var gregorianCalendar = Calendar(identifier: .gregorian)
    gregorianCalendar.timeZone = TimeZone(identifier: "UTC")!
    
    let result = withDependencies {
        $0.calendar = gregorianCalendar
        $0.date = { fixedDate }
    } operation: {
        let view = TestView()
        return view.getStartOfDay()
    }
    
    let expectedStartOfDay = Date(timeIntervalSince1970: 1234483200)
    #expect(result == expectedStartOfDay)
}