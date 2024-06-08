import Foundation

class OpenSSLInstaller {
    static func findOpenSSLPath() -> String? {
        // First, try to find OpenSSL using `which openssl`
        if let opensslPath = try? shell("which openssl"), !opensslPath.isEmpty {
            return opensslPath.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Check if OpenSSL is installed via Homebrew
        if let homebrewPath = try? shell("brew --prefix openssl"), !homebrewPath.isEmpty {
            return homebrewPath.trimmingCharacters(in: .whitespacesAndNewlines) + "/bin/openssl"
        }
        
        // Fallback to common system paths
        let commonPaths = [
            "/usr/local/bin/openssl",
            "/usr/bin/openssl",
            "/opt/local/bin/openssl",
            "/opt/homebrew/bin/openssl"
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // If OpenSSL is not found, return nil
        return nil
    }
    
    private static func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: findShellPath())
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
    }
    
    private static func findShellPath() -> String {
        return FileManager.default.fileExists(atPath: "/bin/zsh") ? "/bin/zsh" : "/bin/bash"
    }
    
    func installOpenSSL() -> Bool {
        do {
            let brewInstallOutput = try shell("brew install openssl")
            print("OpenSSL installation output: \(brewInstallOutput)")
            return true
        } catch {
            print("Failed to install OpenSSL: \(error)")
            return false
        }
    }

    func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh") // Use zsh or /bin/bash for macOS

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}
