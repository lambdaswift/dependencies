import Testing
import Foundation
@testable import Dependencies

@Test func fileManagerDependencyReturnsDefaultFileManager() {
    struct TestView {
        @Dependency(\.fileManager) var fileManager
        
        func getManager() -> FileManager {
            fileManager
        }
    }
    
    let view = TestView()
    let result = view.getManager()
    
    #expect(result === FileManager.default)
}

@Test func fileManagerDependencyCanBeOverridden() {
    struct TestView {
        @Dependency(\.fileManager) var fileManager
        
        func checkFileExists(at path: String) -> Bool {
            fileManager.fileExists(atPath: path)
        }
    }
    
    // Create a mock file manager
    final class MockFileManager: FileManager {
        var fileExistsCalled = false
        var fileExistsPath: String?
        var fileExistsResult = true
        
        override func fileExists(atPath path: String) -> Bool {
            fileExistsCalled = true
            fileExistsPath = path
            return fileExistsResult
        }
    }
    
    let mockFileManager = MockFileManager()
    mockFileManager.fileExistsResult = false
    
    let result = withDependencies {
        $0.fileManager = mockFileManager
    } operation: {
        let view = TestView()
        return view.checkFileExists(at: "/test/path.txt")
    }
    
    #expect(result == false)
    #expect(mockFileManager.fileExistsCalled == true)
    #expect(mockFileManager.fileExistsPath == "/test/path.txt")
}

@Test func fileManagerDependencyOverrideIsScoped() {
    struct TestView {
        @Dependency(\.fileManager) var fileManager
        
        func getManager() -> FileManager {
            fileManager
        }
    }
    
    let customFileManager = FileManager()
    let view = TestView()
    
    let beforeOverride = view.getManager()
    #expect(beforeOverride === FileManager.default)
    
    let duringOverride = withDependencies {
        $0.fileManager = customFileManager
    } operation: {
        view.getManager()
    }
    #expect(duringOverride === customFileManager)
    
    let afterOverride = view.getManager()
    #expect(afterOverride === FileManager.default)
}

@Test func fileManagerDependencyForTestingFileOperations() {
    struct FileService {
        @Dependency(\.fileManager) var fileManager
        
        func writeData(_ data: Data, to path: String) throws {
            let url = URL(fileURLWithPath: path)
            try data.write(to: url)
        }
        
        func readData(from path: String) throws -> Data {
            let url = URL(fileURLWithPath: path)
            return try Data(contentsOf: url)
        }
        
        func deleteFile(at path: String) throws {
            try fileManager.removeItem(atPath: path)
        }
        
        func fileExists(at path: String) -> Bool {
            fileManager.fileExists(atPath: path)
        }
    }
    
    // Create a temporary directory for testing
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    let testFilePath = tempDir.appendingPathComponent("test.txt").path
    
    // Use real file manager for this test
    let service = FileService()
    
    // Test file doesn't exist initially
    #expect(service.fileExists(at: testFilePath) == false)
    
    // Create directory
    try? FileManager.default.createDirectory(
        at: tempDir,
        withIntermediateDirectories: true
    )
    
    // Write data
    let testData = "Hello, World!".data(using: .utf8)!
    try? service.writeData(testData, to: testFilePath)
    
    // File should exist now
    #expect(service.fileExists(at: testFilePath) == true)
    
    // Read data back
    if let readData = try? service.readData(from: testFilePath) {
        #expect(readData == testData)
    }
    
    // Clean up
    try? service.deleteFile(at: testFilePath)
    #expect(service.fileExists(at: testFilePath) == false)
    
    // Clean up temp directory
    try? FileManager.default.removeItem(at: tempDir)
}