import Testing
import Foundation
@testable import Dependencies

@Test func loggerDependencyLogsMessages() {
    struct LoggingService {
        @Dependency(\.logger) var logger
        
        func performOperation() {
            logger.debug("Starting operation")
            logger.info("Operation in progress")
            logger.warning("This might take a while")
            logger.error("Something went wrong")
            logger.critical("Critical failure")
        }
    }
    
    // Use a no-op logger to avoid console output during tests
    let noOpLogger = Logger { _, _, _, _, _ in }
    
    withDependencies {
        $0.logger = noOpLogger
    } operation: {
        let service = LoggingService()
        // Should not crash when logging
        service.performOperation()
    }
}

@Test func loggerDependencyCanBeOverridden() {
    struct Application {
        @Dependency(\.logger) var logger
        
        func startup() {
            logger.info("Application starting")
        }
        
        func shutdown() {
            logger.info("Application shutting down")
        }
    }
    
    let capturedLogs = LockIsolated<[(Logger.Level, String, String, String, Int)]>([])
    
    let customLogger = Logger { level, message, file, function, line in
        capturedLogs.withValue { $0.append((level, message, file, function, line)) }
    }
    
    withDependencies {
        $0.logger = customLogger
    } operation: {
        let app = Application()
        app.startup()
        app.shutdown()
    }
    
    let logs = capturedLogs.value
    #expect(logs.count == 2)
    #expect(logs[0].0 == .info)
    #expect(logs[0].1 == "Application starting")
    #expect(logs[0].3 == "startup()")
    #expect(logs[1].0 == .info)
    #expect(logs[1].1 == "Application shutting down")
    #expect(logs[1].3 == "shutdown()")
}

@Test func loggerDependencyOverrideIsScoped() {
    struct Service {
        @Dependency(\.logger) var logger
        
        func log(message: String) {
            logger.info(message)
        }
    }
    
    let defaultLogs = LockIsolated<[String]>([])
    let customLogs = LockIsolated<[String]>([])
    
    let customLogger = Logger { _, message, _, _, _ in
        customLogs.withValue { $0.append(message) }
    }
    
    // Capture default logs by temporarily overriding
    let captureLogger = Logger { _, message, _, _, _ in
        defaultLogs.withValue { $0.append(message) }
    }
    
    // Before override
    withDependencies {
        $0.logger = captureLogger
    } operation: {
        let service = Service()
        service.log(message: "Before")
    }
    
    // During override
    withDependencies {
        $0.logger = customLogger
    } operation: {
        let service = Service()
        service.log(message: "During")
    }
    
    // After override
    withDependencies {
        $0.logger = captureLogger
    } operation: {
        let service = Service()
        service.log(message: "After")
    }
    
    #expect(defaultLogs.value == ["Before", "After"])
    #expect(customLogs.value == ["During"])
}

@Test func loggerDependencySupportsAllLogLevels() {
    struct DebugService {
        @Dependency(\.logger) var logger
        
        func testAllLevels() {
            logger.debug("Debug message")
            logger.info("Info message")
            logger.warning("Warning message")
            logger.error("Error message")
            logger.critical("Critical message")
        }
    }
    
    let loggedLevels = LockIsolated<[Logger.Level]>([])
    
    let trackingLogger = Logger { level, _, _, _, _ in
        loggedLevels.withValue { $0.append(level) }
    }
    
    withDependencies {
        $0.logger = trackingLogger
    } operation: {
        let service = DebugService()
        service.testAllLevels()
    }
    
    #expect(loggedLevels.value == [.debug, .info, .warning, .error, .critical])
}

@Test func loggerDependencyIncludesMetadata() {
    struct MetadataService {
        @Dependency(\.logger) var logger
        
        func logWithMetadata() {
            logger.info("Test message")
        }
    }
    
    let capturedFile = LockIsolated<String?>(nil)
    let capturedFunction = LockIsolated<String?>(nil)
    let capturedLine = LockIsolated<Int?>(nil)
    
    let metadataLogger = Logger { _, _, file, function, line in
        capturedFile.withValue { $0 = file }
        capturedFunction.withValue { $0 = function }
        capturedLine.withValue { $0 = line }
    }
    
    withDependencies {
        $0.logger = metadataLogger
    } operation: {
        let service = MetadataService()
        service.logWithMetadata()
    }
    
    #expect(capturedFile.value?.contains("LoggerDependencyTests.swift") == true)
    #expect(capturedFunction.value == "logWithMetadata()")
    #expect(capturedLine.value != nil)
}

@Test func loggerDependencyInNestedContexts() {
    struct NestedService {
        @Dependency(\.logger) var logger
        
        func outerOperation() {
            logger.info("Outer operation")
        }
        
        func innerOperation() {
            logger.info("Inner operation")
        }
    }
    
    let outerLogs = LockIsolated<[String]>([])
    let innerLogs = LockIsolated<[String]>([])
    
    let outerLogger = Logger { _, message, _, _, _ in
        outerLogs.withValue { $0.append(message) }
    }
    
    let innerLogger = Logger { _, message, _, _, _ in
        innerLogs.withValue { $0.append(message) }
    }
    
    withDependencies {
        $0.logger = outerLogger
    } operation: {
        let service = NestedService()
        service.outerOperation()
        
        withDependencies {
            $0.logger = innerLogger
        } operation: {
            let innerService = NestedService()
            innerService.innerOperation()
        }
        
        service.outerOperation()
    }
    
    #expect(outerLogs.value == ["Outer operation", "Outer operation"])
    #expect(innerLogs.value == ["Inner operation"])
}

@Test func loggerDependencyNoOpLogger() {
    struct QuietService {
        @Dependency(\.logger) var logger
        
        func performQuietly() {
            logger.debug("This should be silent")
            logger.info("No output expected")
            logger.error("Silent error")
        }
    }
    
    let logCount = LockIsolated(0)
    
    // Create a no-op logger that just counts calls
    let noOpLogger = Logger { _, _, _, _, _ in
        logCount.withValue { $0 += 1 }
    }
    
    withDependencies {
        $0.logger = noOpLogger
    } operation: {
        let service = QuietService()
        service.performQuietly()
    }
    
    #expect(logCount.value == 3)
}

@Test func loggerDependencyWithFormattedMessages() {
    struct FormattingService {
        @Dependency(\.logger) var logger
        
        func logFormattedData(user: String, action: String, count: Int) {
            logger.info("User '\(user)' performed '\(action)' \(count) times")
        }
    }
    
    let capturedMessage = LockIsolated<String?>(nil)
    
    let captureLogger = Logger { _, message, _, _, _ in
        capturedMessage.withValue { $0 = message }
    }
    
    withDependencies {
        $0.logger = captureLogger
    } operation: {
        let service = FormattingService()
        service.logFormattedData(user: "alice", action: "login", count: 3)
    }
    
    #expect(capturedMessage.value == "User 'alice' performed 'login' 3 times")
}