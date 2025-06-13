import Testing
import Foundation
@testable import Dependencies

@Test func notificationCenterDependencyCanBeAccessed() {
    struct NotificationService {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func postNotification(name: String) {
            notificationCenter.post(
                name: Notification.Name(name),
                object: nil
            )
        }
    }
    
    let service = NotificationService()
    // Should not crash when posting
    service.postNotification(name: "TestNotification")
}

@Test func notificationCenterDependencyCanBeOverridden() {
    struct NotificationHandler {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func getCenter() -> NotificationCenter {
            notificationCenter
        }
    }
    
    let customCenter = NotificationCenter()
    let handler = NotificationHandler()
    
    let result = withDependencies {
        $0.notificationCenter = customCenter
    } operation: {
        handler.getCenter()
    }
    
    #expect(result === customCenter)
}

@Test func notificationCenterDependencyOverrideIsScoped() {
    struct EventDispatcher {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func postToCenter(name: String) {
            notificationCenter.post(name: Notification.Name(name), object: "test")
        }
    }
    
    let customCenter = NotificationCenter()
    let customReceived = LockIsolated(false)
    let defaultReceived = LockIsolated(false)
    
    let notificationName = Notification.Name("ScopeTest")
    
    // Observer on custom center
    let customObserver = customCenter.addObserver(
        forName: notificationName,
        object: nil,
        queue: nil
    ) { _ in
        customReceived.withValue { $0 = true }
    }
    
    // Observer on default center
    let defaultObserver = NotificationCenter.default.addObserver(
        forName: notificationName,
        object: nil,
        queue: nil
    ) { _ in
        defaultReceived.withValue { $0 = true }
    }
    
    let dispatcher = EventDispatcher()
    
    // During override - should post to custom center
    withDependencies {
        $0.notificationCenter = customCenter
    } operation: {
        dispatcher.postToCenter(name: "ScopeTest")
    }
    
    Thread.sleep(forTimeInterval: 0.01)
    
    #expect(customReceived.value == true)
    #expect(defaultReceived.value == false)
    
    // Cleanup
    customCenter.removeObserver(customObserver)
    NotificationCenter.default.removeObserver(defaultObserver)
}

@Test func notificationCenterDependencySupportsMultipleOverrides() {
    struct NotificationManager {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func getCenter() -> NotificationCenter {
            notificationCenter
        }
    }
    
    let center1 = NotificationCenter()
    let center2 = NotificationCenter()
    let manager = NotificationManager()
    
    // First override
    let result1 = withDependencies {
        $0.notificationCenter = center1
    } operation: {
        manager.getCenter()
    }
    #expect(result1 === center1)
    
    // Second override
    let result2 = withDependencies {
        $0.notificationCenter = center2
    } operation: {
        manager.getCenter()
    }
    #expect(result2 === center2)
    
    // Verify they're different
    #expect(result1 !== result2)
}

@Test func notificationCenterDependencyInNestedContexts() {
    struct NotificationRelay {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func postNotification(name: String) {
            notificationCenter.post(name: Notification.Name(name), object: nil)
        }
    }
    
    let outerCenter = NotificationCenter()
    let innerCenter = NotificationCenter()
    
    let outerCount = LockIsolated(0)
    let innerCount = LockIsolated(0)
    
    let notificationName = Notification.Name("NestedTest")
    
    // Set up observers
    let outerObserver = outerCenter.addObserver(
        forName: notificationName,
        object: nil,
        queue: nil
    ) { _ in
        outerCount.withValue { $0 += 1 }
    }
    
    let innerObserver = innerCenter.addObserver(
        forName: notificationName,
        object: nil,
        queue: nil
    ) { _ in
        innerCount.withValue { $0 += 1 }
    }
    
    let relay = NotificationRelay()
    
    withDependencies {
        $0.notificationCenter = outerCenter
    } operation: {
        // Outer context
        relay.postNotification(name: "NestedTest")
        Thread.sleep(forTimeInterval: 0.01)
        #expect(outerCount.value == 1)
        #expect(innerCount.value == 0)
        
        // Inner context overrides
        withDependencies {
            $0.notificationCenter = innerCenter
        } operation: {
            relay.postNotification(name: "NestedTest")
            Thread.sleep(forTimeInterval: 0.01)
            #expect(outerCount.value == 1)
            #expect(innerCount.value == 1)
        }
        
        // Back to outer context
        relay.postNotification(name: "NestedTest")
        Thread.sleep(forTimeInterval: 0.01)
        #expect(outerCount.value == 2)
        #expect(innerCount.value == 1)
    }
    
    // Cleanup
    outerCenter.removeObserver(outerObserver)
    innerCenter.removeObserver(innerObserver)
}

@Test func notificationCenterDependencyWorksWithNotifications() {
    struct NotificationPublisher {
        @Dependency(\.notificationCenter) var notificationCenter
        
        func publish(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
            notificationCenter.post(name: name, object: object, userInfo: userInfo)
        }
    }
    
    let customCenter = NotificationCenter()
    let notificationReceived = LockIsolated(false)
    let notificationName = Notification.Name("TestNotification")
    
    // Set up observer on custom center
    let observer = customCenter.addObserver(
        forName: notificationName,
        object: nil,
        queue: .main
    ) { _ in
        notificationReceived.withValue { $0 = true }
    }
    
    let publisher = NotificationPublisher()
    
    // Post to custom center
    withDependencies {
        $0.notificationCenter = customCenter
    } operation: {
        publisher.publish(name: notificationName)
    }
    
    // Give notification time to process on main queue
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
    
    #expect(notificationReceived.value == true)
    
    customCenter.removeObserver(observer)
}