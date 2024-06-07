import Foundation

class OpenSSLInstaller {
    func installOpenSSL() {
        if let _ = try? shell("brew install openssl") {
            print("OpenSSL installed via Homebrew")
        } else if let _ = try? shell("curl -O https://www.openssl.org/source/openssl-1.1.1.tar.gz") {
            print("OpenSSL downloaded via curl")
        } else {
            print("Failed to install OpenSSL. Please install it manually.")
        }
    }
    
    private func shell(_ command: String) throws -> String {
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
