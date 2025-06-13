import Testing
import Foundation
@testable import Dependencies

@Test func urlSessionDependencyReturnsSharedSession() {
    struct NetworkService {
        @Dependency(\.urlSession) var urlSession
        
        func getSession() -> URLSession {
            urlSession
        }
    }
    
    let service = NetworkService()
    let result = service.getSession()
    
    #expect(result === URLSession.shared)
}

@Test func urlSessionDependencyCanBeOverridden() {
    struct APIService {
        @Dependency(\.urlSession) var urlSession
        
        func getConfiguration() -> URLSessionConfiguration {
            urlSession.configuration
        }
    }
    
    // Create custom session
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 30.0
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    let customSession = URLSession(configuration: configuration)
    
    let service = APIService()
    
    // Test with override
    let result = withDependencies {
        $0.urlSession = customSession
    } operation: {
        service.getConfiguration()
    }
    
    #expect(result.timeoutIntervalForRequest == 30.0)
    #expect(result.requestCachePolicy == .reloadIgnoringLocalCacheData)
}

@Test func urlSessionDependencyOverrideIsScoped() {
    struct TestService {
        @Dependency(\.urlSession) var urlSession
        
        func getTimeout() -> TimeInterval {
            urlSession.configuration.timeoutIntervalForRequest
        }
    }
    
    let customConfiguration = URLSessionConfiguration.ephemeral
    customConfiguration.timeoutIntervalForRequest = 5.0
    let customSession = URLSession(configuration: customConfiguration)
    
    let service = TestService()
    
    // Before override - should use default
    let beforeTimeout = service.getTimeout()
    let defaultTimeout = URLSession.shared.configuration.timeoutIntervalForRequest
    #expect(beforeTimeout == defaultTimeout)
    
    // During override
    let duringTimeout = withDependencies {
        $0.urlSession = customSession
    } operation: {
        service.getTimeout()
    }
    #expect(duringTimeout == 5.0)
    
    // After override - should be back to default
    let afterTimeout = service.getTimeout()
    #expect(afterTimeout == defaultTimeout)
}

@Test func urlSessionDependencySupportsMultipleOverrides() {
    struct DataFetcher {
        @Dependency(\.urlSession) var urlSession
        
        func getTimeout() -> TimeInterval {
            urlSession.configuration.timeoutIntervalForRequest
        }
    }
    
    let session1 = URLSession(configuration: {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        return config
    }())
    
    let session2 = URLSession(configuration: {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20.0
        return config
    }())
    
    let fetcher = DataFetcher()
    
    // First override
    let timeout1 = withDependencies {
        $0.urlSession = session1
    } operation: {
        fetcher.getTimeout()
    }
    #expect(timeout1 == 10.0)
    
    // Second override
    let timeout2 = withDependencies {
        $0.urlSession = session2
    } operation: {
        fetcher.getTimeout()
    }
    #expect(timeout2 == 20.0)
    
    // Back to default
    let defaultTimeout = fetcher.getTimeout()
    #expect(defaultTimeout == URLSession.shared.configuration.timeoutIntervalForRequest)
}

@Test func urlSessionDependencyInNestedContexts() {
    struct NetworkLayer {
        @Dependency(\.urlSession) var urlSession
        
        func getCachePolicy() -> URLRequest.CachePolicy {
            urlSession.configuration.requestCachePolicy
        }
    }
    
    let outerSession = URLSession(configuration: {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }())
    
    let innerSession = URLSession(configuration: {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return config
    }())
    
    let layer = NetworkLayer()
    
    withDependencies {
        $0.urlSession = outerSession
    } operation: {
        // Outer context
        let outerPolicy = layer.getCachePolicy()
        #expect(outerPolicy == .reloadIgnoringLocalCacheData)
        
        // Inner context overrides
        withDependencies {
            $0.urlSession = innerSession
        } operation: {
            let innerPolicy = layer.getCachePolicy()
            #expect(innerPolicy == .returnCacheDataElseLoad)
        }
        
        // Back to outer context
        let outerPolicyAgain = layer.getCachePolicy()
        #expect(outerPolicyAgain == .reloadIgnoringLocalCacheData)
    }
}