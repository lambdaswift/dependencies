import Testing
import Foundation
@testable import Dependencies

@Test func localeDependencyReturnsCurrentLocaleByDefault() {
    struct TestView {
        @Dependency(\.locale) var locale
        
        func getLocale() -> Locale {
            locale
        }
    }
    
    let view = TestView()
    let result = view.getLocale()
    
    #expect(result == Locale.current)
}

@Test func localeDependencyCanBeOverridden() {
    struct TestView {
        @Dependency(\.locale) var locale
        
        func getLocale() -> Locale {
            locale
        }
    }
    
    let japaneseLocale = Locale(identifier: "ja_JP")
    
    let result = withDependencies {
        $0.locale = japaneseLocale
    } operation: {
        let view = TestView()
        return view.getLocale()
    }
    
    #expect(result.identifier == "ja_JP")
}

@Test func localeDependencyOverrideIsScoped() {
    struct TestView {
        @Dependency(\.locale) var locale
        
        func getLocale() -> Locale {
            locale
        }
    }
    
    let frenchLocale = Locale(identifier: "fr_FR")
    
    let view = TestView()
    
    let beforeOverride = view.getLocale()
    #expect(beforeOverride.identifier != "fr_FR")
    
    let duringOverride = withDependencies {
        $0.locale = frenchLocale
    } operation: {
        view.getLocale()
    }
    #expect(duringOverride.identifier == "fr_FR")
    
    let afterOverride = view.getLocale()
    #expect(afterOverride.identifier != "fr_FR")
}

@Test func localeDependencyAffectsFormatting() {
    struct TestView {
        @Dependency(\.locale) var locale
        
        func formatNumber(_ number: Double) -> String {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: number)) ?? ""
        }
    }
    
    let germanLocale = Locale(identifier: "de_DE")
    
    let germanResult = withDependencies {
        $0.locale = germanLocale
    } operation: {
        let view = TestView()
        return view.formatNumber(1234.56)
    }
    
    #expect(germanResult == "1.234,56")
    
    let usLocale = Locale(identifier: "en_US")
    
    let usResult = withDependencies {
        $0.locale = usLocale
    } operation: {
        let view = TestView()
        return view.formatNumber(1234.56)
    }
    
    #expect(usResult == "1,234.56")
}