import Testing
import Foundation
@testable import Dependencies

@Test func featureFlagsDependencyReturnsDefaults() {
    struct FeatureService {
        @Dependency(\.featureFlags) var featureFlags
        
        func checkFeatures() -> (Bool, Bool, Bool) {
            let feature1 = featureFlags.isEnabled("feature1")
            let feature2 = featureFlags.isEnabled("feature2")
            let feature3 = featureFlags.bool(for: "feature3")
            return (feature1, feature2, feature3)
        }
    }
    
    // Use default feature flags (all disabled)
    withDependencies {
        $0.featureFlags = FeatureFlags()
    } operation: {
        let service = FeatureService()
        let (f1, f2, f3) = service.checkFeatures()
        #expect(f1 == false)
        #expect(f2 == false)
        #expect(f3 == false)
    }
}

@Test func featureFlagsDependencyCanBeOverridden() {
    struct AppFeatures {
        @Dependency(\.featureFlags) var featureFlags
        
        func isNewUIEnabled() -> Bool {
            featureFlags.isEnabled("new_ui")
        }
        
        func getMaxRetries() -> Int {
            featureFlags.int(for: "max_retries", default: 3)
        }
        
        func getAPIEndpoint() -> String {
            featureFlags.string(for: "api_endpoint", default: "https://api.example.com")
        }
    }
    
    let customFlags = FeatureFlags(
        isEnabled: { flag in
            flag == "new_ui"
        },
        value: { flag in
            switch flag {
            case "new_ui": return true
            case "max_retries": return 5
            case "api_endpoint": return "https://test.example.com"
            default: return nil
            }
        }
    )
    
    withDependencies {
        $0.featureFlags = customFlags
    } operation: {
        let features = AppFeatures()
        #expect(features.isNewUIEnabled() == true)
        #expect(features.getMaxRetries() == 5)
        #expect(features.getAPIEndpoint() == "https://test.example.com")
    }
}

@Test func featureFlagsDependencyOverrideIsScoped() {
    struct FeatureToggle {
        @Dependency(\.featureFlags) var featureFlags
        
        func isEnabled(_ flag: String) -> Bool {
            featureFlags.isEnabled(flag)
        }
    }
    
    let enabledFlags = FeatureFlags(
        isEnabled: { _ in true }
    )
    
    let disabledFlags = FeatureFlags(
        isEnabled: { _ in false }
    )
    
    // Before override
    withDependencies {
        $0.featureFlags = disabledFlags
    } operation: {
        let toggle = FeatureToggle()
        #expect(toggle.isEnabled("test_feature") == false)
    }
    
    // During override
    withDependencies {
        $0.featureFlags = enabledFlags
    } operation: {
        let toggle = FeatureToggle()
        #expect(toggle.isEnabled("test_feature") == true)
    }
    
    // After override
    withDependencies {
        $0.featureFlags = disabledFlags
    } operation: {
        let toggle = FeatureToggle()
        #expect(toggle.isEnabled("test_feature") == false)
    }
}

@Test func featureFlagsDependencySupportsTypedValues() {
    struct ConfigService {
        @Dependency(\.featureFlags) var featureFlags
        
        func getConfiguration() -> (String, Int, Double, Bool) {
            let name = featureFlags.string(for: "app_name", default: "MyApp")
            let timeout = featureFlags.int(for: "timeout_seconds", default: 30)
            let threshold = featureFlags.double(for: "threshold", default: 0.75)
            let debug = featureFlags.bool(for: "debug_mode", default: false)
            return (name, timeout, threshold, debug)
        }
    }
    
    let configFlags = FeatureFlags(
        value: { flag in
            switch flag {
            case "app_name": return "TestApp"
            case "timeout_seconds": return 60
            case "threshold": return 0.95
            case "debug_mode": return true
            default: return nil
            }
        }
    )
    
    withDependencies {
        $0.featureFlags = configFlags
    } operation: {
        let service = ConfigService()
        let (name, timeout, threshold, debug) = service.getConfiguration()
        #expect(name == "TestApp")
        #expect(timeout == 60)
        #expect(threshold == 0.95)
        #expect(debug == true)
    }
}

@Test func featureFlagsDependencyWithDefaultValues() {
    struct DefaultsService {
        @Dependency(\.featureFlags) var featureFlags
        
        func getValues() -> (String, Int, Double, Bool) {
            // These flags don't exist, so defaults should be returned
            let str = featureFlags.string(for: "missing_string", default: "default")
            let int = featureFlags.int(for: "missing_int", default: 42)
            let double = featureFlags.double(for: "missing_double", default: 3.14)
            let bool = featureFlags.bool(for: "missing_bool", default: true)
            return (str, int, double, bool)
        }
    }
    
    let emptyFlags = FeatureFlags()
    
    withDependencies {
        $0.featureFlags = emptyFlags
    } operation: {
        let service = DefaultsService()
        let (str, int, double, bool) = service.getValues()
        #expect(str == "default")
        #expect(int == 42)
        #expect(double == 3.14)
        #expect(bool == true)
    }
}

@Test func featureFlagsDependencyInNestedContexts() {
    struct FeatureChecker {
        @Dependency(\.featureFlags) var featureFlags
        
        func checkFlag(_ name: String) -> Bool {
            featureFlags.isEnabled(name)
        }
    }
    
    let outerFlags = FeatureFlags(
        isEnabled: { flag in
            flag == "outer_feature"
        }
    )
    
    let innerFlags = FeatureFlags(
        isEnabled: { flag in
            flag == "inner_feature"
        }
    )
    
    withDependencies {
        $0.featureFlags = outerFlags
    } operation: {
        let checker = FeatureChecker()
        #expect(checker.checkFlag("outer_feature") == true)
        #expect(checker.checkFlag("inner_feature") == false)
        
        withDependencies {
            $0.featureFlags = innerFlags
        } operation: {
            let innerChecker = FeatureChecker()
            #expect(innerChecker.checkFlag("outer_feature") == false)
            #expect(innerChecker.checkFlag("inner_feature") == true)
        }
        
        #expect(checker.checkFlag("outer_feature") == true)
        #expect(checker.checkFlag("inner_feature") == false)
    }
}

@Test func featureFlagsDependencyWithAllFlags() {
    struct FlagsInspector {
        @Dependency(\.featureFlags) var featureFlags
        
        func getAllFlags() -> [String: Any] {
            featureFlags.allFlags
        }
    }
    
    let testFlags = FeatureFlags(
        allFlags: {
            [
                "feature_a": true,
                "feature_b": false,
                "config_int": 123,
                "config_string": "test",
                "config_double": 45.67
            ]
        }
    )
    
    withDependencies {
        $0.featureFlags = testFlags
    } operation: {
        let inspector = FlagsInspector()
        let allFlags = inspector.getAllFlags()
        #expect(allFlags.count == 5)
        #expect(allFlags["feature_a"] as? Bool == true)
        #expect(allFlags["feature_b"] as? Bool == false)
        #expect(allFlags["config_int"] as? Int == 123)
        #expect(allFlags["config_string"] as? String == "test")
        #expect(allFlags["config_double"] as? Double == 45.67)
    }
}

@Test func featureFlagsDependencyForABTesting() {
    struct ABTestService {
        @Dependency(\.featureFlags) var featureFlags
        
        func getVariant(for experiment: String) -> String {
            featureFlags.string(for: experiment, default: "control")
        }
        
        func isInTreatment(for experiment: String) -> Bool {
            getVariant(for: experiment) != "control"
        }
    }
    
    let abTestFlags = FeatureFlags(
        value: { flag in
            switch flag {
            case "checkout_flow": return "variant_a"
            case "homepage_design": return "control"
            case "search_algorithm": return "variant_b"
            default: return nil
            }
        }
    )
    
    withDependencies {
        $0.featureFlags = abTestFlags
    } operation: {
        let service = ABTestService()
        
        #expect(service.getVariant(for: "checkout_flow") == "variant_a")
        #expect(service.isInTreatment(for: "checkout_flow") == true)
        
        #expect(service.getVariant(for: "homepage_design") == "control")
        #expect(service.isInTreatment(for: "homepage_design") == false)
        
        #expect(service.getVariant(for: "search_algorithm") == "variant_b")
        #expect(service.isInTreatment(for: "search_algorithm") == true)
        
        // Non-existent experiment
        #expect(service.getVariant(for: "unknown_experiment") == "control")
        #expect(service.isInTreatment(for: "unknown_experiment") == false)
    }
}