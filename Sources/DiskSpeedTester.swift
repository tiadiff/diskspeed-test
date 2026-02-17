import Foundation
import Combine

enum TestStatus: String, CaseIterable {
    case idle = "Ready"
    case testing = "Testing..."
    case success = "Complete"
    case error = "Error"
}

class VolumeTestState: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isInternal: Bool
    
    @Published var status: TestStatus = .idle
    @Published var writeSpeed: Double = 0
    @Published var readSpeed: Double = 0
    @Published var progress: Double = 0
    @Published var errorText: String?
    
    init(url: URL, name: String, isInternal: Bool) {
        self.url = url
        self.name = name
        self.isInternal = isInternal
    }
}

class DiskSpeedTester: ObservableObject {
    @Published var volumeStates: [VolumeTestState] = []
    private var testFileSize: Int64 = 1024 * 1024 * 1024 * 2 // 2GB
    
    init() {
        refreshVolumes()
    }
    
    func refreshVolumes() {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsInternalKey]
        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        
        let newStates = paths.compactMap { url -> VolumeTestState? in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let name = values?.volumeName ?? url.lastPathComponent
            let isInternal = values?.volumeIsInternal ?? true
            
            if name == "Preboot" || name == "Recovery" || name == "VM" { return nil }
            
            if let existing = volumeStates.first(where: { $0.url == url }) {
                return existing
            }
            
            return VolumeTestState(url: url, name: name, isInternal: isInternal)
        }
        
        DispatchQueue.main.async {
            self.volumeStates = newStates
        }
    }
    
    func runTest(for state: VolumeTestState) {
        guard state.status != .testing else { return }
        
        state.status = .testing
        state.writeSpeed = 0
        state.readSpeed = 0
        state.progress = 0
        state.errorText = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileName = ".speedtest_temp_\(UUID().uuidString)"
            var testFileURL: URL
            
            let rootCandidate = state.url.appendingPathComponent(fileName)
            if FileManager.default.isWritableFile(atPath: state.url.path) {
                testFileURL = rootCandidate
            } else {
                testFileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fileName)
            }
            
            let filePath = testFileURL.path
            
            do {
                // --- WRITE TEST ---
                try self.performWriteTest(path: filePath, state: state)
                
                // --- READ TEST ---
                try self.performReadTest(path: filePath, state: state)
                
                // Cleanup
                try? FileManager.default.removeItem(at: testFileURL)
                
                DispatchQueue.main.async {
                    state.status = .success
                    state.progress = 1.0
                }
                
            } catch {
                DispatchQueue.main.async {
                    state.status = .error
                    state.errorText = error.localizedDescription
                    try? FileManager.default.removeItem(atPath: filePath)
                }
            }
        }
    }
    
    private func performWriteTest(path: String, state: VolumeTestState) throws {
        DispatchQueue.main.async { state.status = .testing; state.progress = 0 }
        
        let fd = open(path, O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR)
        if fd == -1 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        
        // Disable cache
        if fcntl(fd, F_NOCACHE, 1) == -1 {
            print("Warning: Could not disable cache for write")
        }
        
        let chunkSize = 1024 * 1024 * 64 // 64MB
        let data = Data(count: chunkSize)
        let iterations = Int(testFileSize / Int64(chunkSize))
        
        let startTime = DispatchTime.now()
        
        for i in 0..<iterations {
            try data.withUnsafeBytes { ptr in
                let written = write(fd, ptr.baseAddress, chunkSize)
                if written == -1 {
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
                }
            }
            DispatchQueue.main.async {
                state.progress = Double(i) / Double(iterations * 2)
            }
        }
        
        fsync(fd)
        close(fd)
        
        let endTime = DispatchTime.now()
        let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let seconds = Double(nanoseconds) / 1_000_000_000
        
        DispatchQueue.main.async {
            state.writeSpeed = Double(self.testFileSize) / seconds / (1024 * 1024)
        }
    }
    
    private func performReadTest(path: String, state: VolumeTestState) throws {
        let fd = open(path, O_RDONLY)
        if fd == -1 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        
        // Disable cache
        if fcntl(fd, F_NOCACHE, 1) == -1 {
            print("Warning: Could not disable cache for read")
        }
        
        let chunkSize = 1024 * 1024 * 64 // 64MB
        var buffer = [UInt8](repeating: 0, count: chunkSize)
        var totalRead: Int64 = 0
        
        let startTime = DispatchTime.now()
        
        while totalRead < testFileSize {
            let bytesRead = read(fd, &buffer, chunkSize)
            if bytesRead == -1 {
                close(fd)
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
            }
            if bytesRead == 0 { break }
            
            totalRead += Int64(bytesRead)
            let currentTotal = totalRead
            DispatchQueue.main.async {
                state.progress = 0.5 + (Double(currentTotal) / Double(self.testFileSize * 2))
            }
        }
        
        close(fd)
        
        let endTime = DispatchTime.now()
        let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let seconds = Double(nanoseconds) / 1_000_000_000
        
        DispatchQueue.main.async {
            state.readSpeed = Double(self.testFileSize) / seconds / (1024 * 1024)
        }
    }
}
