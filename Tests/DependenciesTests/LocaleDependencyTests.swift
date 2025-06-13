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
    var overridden = DependencyValues()
    overridden.locale = japaneseLocale
    
    let result = DependencyContext.shared.withValues(overridden) {
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
    var overridden = DependencyValues()
    overridden.locale = frenchLocale
    
    let view = TestView()
    
    let beforeOverride = view.getLocale()
    #expect(beforeOverride.identifier != "fr_FR")
    
    let duringOverride = DependencyContext.shared.withValues(overridden) {
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
    var overridden = DependencyValues()
    overridden.locale = germanLocale
    
    let germanResult = DependencyContext.shared.withValues(overridden) {
        let view = TestView()
        return view.formatNumber(1234.56)
    }
    
    #expect(germanResult == "1.234,56")
    
    let usLocale = Locale(identifier: "en_US")
    overridden.locale = usLocale
    
    let usResult = DependencyContext.shared.withValues(overridden) {
        let view = TestView()
        return view.formatNumber(1234.56)
    }
    
    #expect(usResult == "1,234.56")
}