import Testing
import Foundation
@testable import Dependencies

@Test func analyticsDependencyTracksEvents() {
    struct TrackingService {
        @Dependency(\.analytics) var analytics
        
        func trackUserAction() {
            analytics.track("button_clicked", properties: ["button_id": "submit"])
        }
    }
    
    // Use no-op analytics to avoid side effects
    let noOpAnalytics = Analytics()
    
    withDependencies {
        $0.analytics = noOpAnalytics
    } operation: {
        let service = TrackingService()
        // Should not crash when tracking
        service.trackUserAction()
    }
}

@Test func analyticsDependencyCanBeOverridden() {
    struct EventTracker {
        @Dependency(\.analytics) var analytics
        
        func logPageView(page: String) {
            analytics.track("page_view", properties: ["page_name": page])
        }
        
        func logPurchase(amount: Double, currency: String) {
            analytics.track("purchase", properties: [
                "amount": String(amount),
                "currency": currency
            ])
        }
    }
    
    let capturedEvents = LockIsolated<[Analytics.Event]>([])
    
    let testAnalytics = Analytics { event in
        capturedEvents.withValue { $0.append(event) }
    }
    
    withDependencies {
        $0.analytics = testAnalytics
    } operation: {
        let tracker = EventTracker()
        tracker.logPageView(page: "home")
        tracker.logPurchase(amount: 99.99, currency: "USD")
    }
    
    let events = capturedEvents.value
    #expect(events.count == 2)
    #expect(events[0].name == "page_view")
    #expect(events[0].properties["page_name"] == "home")
    #expect(events[1].name == "purchase")
    #expect(events[1].properties["amount"] == "99.99")
    #expect(events[1].properties["currency"] == "USD")
}

@Test func analyticsDependencyOverrideIsScoped() {
    struct MetricsCollector {
        @Dependency(\.analytics) var analytics
        
        func recordMetric(name: String, value: String) {
            analytics.track(name, properties: ["value": value])
        }
    }
    
    let defaultEvents = LockIsolated<[String]>([])
    let customEvents = LockIsolated<[String]>([])
    
    let defaultAnalytics = Analytics { event in
        defaultEvents.withValue { $0.append(event.name) }
    }
    
    let customAnalytics = Analytics { event in
        customEvents.withValue { $0.append(event.name) }
    }
    
    // Before override
    withDependencies {
        $0.analytics = defaultAnalytics
    } operation: {
        let collector = MetricsCollector()
        collector.recordMetric(name: "before_metric", value: "1")
    }
    
    // During override
    withDependencies {
        $0.analytics = customAnalytics
    } operation: {
        let collector = MetricsCollector()
        collector.recordMetric(name: "during_metric", value: "2")
    }
    
    // After override
    withDependencies {
        $0.analytics = defaultAnalytics
    } operation: {
        let collector = MetricsCollector()
        collector.recordMetric(name: "after_metric", value: "3")
    }
    
    #expect(defaultEvents.value == ["before_metric", "after_metric"])
    #expect(customEvents.value == ["during_metric"])
}

@Test func analyticsDependencySupportsIdentifyAndReset() {
    struct UserTracker {
        @Dependency(\.analytics) var analytics
        
        func identifyUser(id: String, email: String) {
            analytics.identify(userId: id, traits: ["email": email])
        }
        
        func logout() {
            analytics.reset()
        }
    }
    
    let identifiedUsers = LockIsolated<[(String, [String: String])]>([])
    let resetCount = LockIsolated(0)
    
    let trackingAnalytics = Analytics(
        track: { _ in },
        identify: { userId, traits in
            identifiedUsers.withValue { $0.append((userId, traits)) }
        },
        reset: {
            resetCount.withValue { $0 += 1 }
        }
    )
    
    withDependencies {
        $0.analytics = trackingAnalytics
    } operation: {
        let tracker = UserTracker()
        tracker.identifyUser(id: "user123", email: "test@example.com")
        tracker.logout()
    }
    
    let users = identifiedUsers.value
    #expect(users.count == 1)
    #expect(users[0].0 == "user123")
    #expect(users[0].1["email"] == "test@example.com")
    #expect(resetCount.value == 1)
}

@Test func analyticsDependencyWithEventObjects() {
    struct EventLogger {
        @Dependency(\.analytics) var analytics
        
        func logCustomEvent() {
            let event = Analytics.Event(
                name: "custom_event",
                properties: ["key1": "value1", "key2": "value2"],
                timestamp: Date(timeIntervalSince1970: 1000)
            )
            analytics.track(event)
        }
    }
    
    let capturedEvents = LockIsolated<[Analytics.Event]>([])
    
    let captureAnalytics = Analytics { event in
        capturedEvents.withValue { $0.append(event) }
    }
    
    withDependencies {
        $0.analytics = captureAnalytics
    } operation: {
        let logger = EventLogger()
        logger.logCustomEvent()
    }
    
    let events = capturedEvents.value
    #expect(events.count == 1)
    #expect(events[0].name == "custom_event")
    #expect(events[0].properties["key1"] == "value1")
    #expect(events[0].properties["key2"] == "value2")
    #expect(events[0].timestamp == Date(timeIntervalSince1970: 1000))
}

@Test func analyticsDependencyInNestedContexts() {
    struct AnalyticsReporter {
        @Dependency(\.analytics) var analytics
        
        func report(action: String) {
            analytics.track(action)
        }
    }
    
    let outerEvents = LockIsolated<[String]>([])
    let innerEvents = LockIsolated<[String]>([])
    
    let outerAnalytics = Analytics { event in
        outerEvents.withValue { $0.append(event.name) }
    }
    
    let innerAnalytics = Analytics { event in
        innerEvents.withValue { $0.append(event.name) }
    }
    
    withDependencies {
        $0.analytics = outerAnalytics
    } operation: {
        let reporter = AnalyticsReporter()
        reporter.report(action: "outer_start")
        
        withDependencies {
            $0.analytics = innerAnalytics
        } operation: {
            let innerReporter = AnalyticsReporter()
            innerReporter.report(action: "inner_action")
        }
        
        reporter.report(action: "outer_end")
    }
    
    #expect(outerEvents.value == ["outer_start", "outer_end"])
    #expect(innerEvents.value == ["inner_action"])
}

@Test func analyticsDependencyForTestingEventSequence() {
    struct OnboardingFlow {
        @Dependency(\.analytics) var analytics
        
        func startOnboarding() {
            analytics.track("onboarding_started")
        }
        
        func completeStep(_ step: Int) {
            analytics.track("onboarding_step_completed", properties: ["step": String(step)])
        }
        
        func finishOnboarding() {
            analytics.track("onboarding_completed")
        }
    }
    
    let eventSequence = LockIsolated<[String]>([])
    
    let sequenceAnalytics = Analytics { event in
        eventSequence.withValue { $0.append(event.name) }
    }
    
    withDependencies {
        $0.analytics = sequenceAnalytics
    } operation: {
        let flow = OnboardingFlow()
        flow.startOnboarding()
        flow.completeStep(1)
        flow.completeStep(2)
        flow.finishOnboarding()
    }
    
    #expect(eventSequence.value == [
        "onboarding_started",
        "onboarding_step_completed",
        "onboarding_step_completed",
        "onboarding_completed"
    ])
}

@Test func analyticsDependencyNoOpByDefault() {
    struct DefaultAnalytics {
        @Dependency(\.analytics) var analytics
        
        func performActions() {
            analytics.track("action1")
            analytics.identify(userId: "user1", traits: ["name": "Test"])
            analytics.reset()
            analytics.track("action2", properties: ["key": "value"])
        }
    }
    
    // Create a no-op analytics to ensure no side effects
    withDependencies {
        $0.analytics = Analytics()
    } operation: {
        let service = DefaultAnalytics()
        // Should not crash with default no-op implementation
        service.performActions()
    }
}