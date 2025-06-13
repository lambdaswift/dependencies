import Testing
import Foundation
@testable import Dependencies

@Test func randomNumberGeneratorReturnsValuesInExpectedRange() {
    struct TestView {
        @Dependency(\.randomNumberGenerator) var rng
        
        func generateDouble() -> Double {
            rng.next()
        }
        
        func generateInt(in range: ClosedRange<Int>) -> Int {
            rng.next(in: range)
        }
        
        func generateBool() -> Bool {
            rng.nextBool()
        }
    }
    
    let view = TestView()
    
    // Test double generation
    for _ in 0..<10 {
        let value = view.generateDouble()
        #expect(value >= 0 && value < 1)
    }
    
    // Test int generation
    for _ in 0..<10 {
        let value = view.generateInt(in: 5...15)
        #expect(value >= 5 && value <= 15)
    }
    
    // Test bool generation - should get mix of true/false
    let bools = (0..<20).map { _ in view.generateBool() }
    #expect(bools.contains(true))
    #expect(bools.contains(false))
}

@Test func randomNumberGeneratorCanBeOverridden() {
    struct TestView {
        @Dependency(\.randomNumberGenerator) var rng
        
        func generateDouble() -> Double {
            rng.next()
        }
        
        func generateInt(in range: ClosedRange<Int>) -> Int {
            rng.next(in: range)
        }
        
        func generateBool() -> Bool {
            rng.nextBool()
        }
    }
    
    let result = withDependencies {
        $0.randomNumberGenerator = RandomNumberGenerator(
            nextDouble: { 0.5 },
            nextInt: { _ in 42 },
            nextBool: { true }
        )
    } operation: {
        let view = TestView()
        return (
            double: view.generateDouble(),
            int: view.generateInt(in: 1...100),
            bool: view.generateBool()
        )
    }
    
    #expect(result.double == 0.5)
    #expect(result.int == 42)
    #expect(result.bool == true)
}

@Test func randomNumberGeneratorOverrideIsScoped() {
    struct TestView {
        @Dependency(\.randomNumberGenerator) var rng
        
        func generateDouble() -> Double {
            rng.next()
        }
    }
    
    let view = TestView()
    
    let beforeOverride = view.generateDouble()
    #expect(beforeOverride >= 0 && beforeOverride < 1)
    
    let duringOverride = withDependencies {
        $0.randomNumberGenerator = RandomNumberGenerator(
            nextDouble: { 0.12345 },
            nextInt: { _ in 0 },
            nextBool: { false }
        )
    } operation: {
        view.generateDouble()
    }
    #expect(duringOverride == 0.12345)
    
    let afterOverride = view.generateDouble()
    #expect(afterOverride >= 0 && afterOverride < 1)
    #expect(afterOverride != 0.12345)
}

@Test func randomNumberGeneratorForDeterministicTesting() {
    struct GameView {
        @Dependency(\.randomNumberGenerator) var rng
        
        func rollDice() -> Int {
            rng.next(in: 1...6)
        }
        
        func flipCoin() -> String {
            rng.nextBool() ? "Heads" : "Tails"
        }
        
        func generateProbability() -> Double {
            rng.next()
        }
    }
    
    let result = withDependencies {
        $0.randomNumberGenerator = RandomNumberGenerator(
            nextDouble: { 0.75 },
            nextInt: { range in 
                // Always return max value for testing
                range.upperBound
            },
            nextBool: { false }
        )
    } operation: {
        let game = GameView()
        return (
            dice: game.rollDice(),
            coin: game.flipCoin(),
            probability: game.generateProbability()
        )
    }
    
    #expect(result.dice == 6)
    #expect(result.coin == "Tails")
    #expect(result.probability == 0.75)
}