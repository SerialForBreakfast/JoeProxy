//
//  main.swift
//  JoeProxySSLHelperTool
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation

func runCommand(_ command: String) -> String? {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]

    if FileManager.default.fileExists(atPath: "/bin/zsh") {
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    } else {
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
    }

    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        print("Error running command \(command): \(error)")
        return nil
    }
}

func installOpenSSL() {
    print("Checking OpenSSL installation...")
    if runCommand("which openssl") == nil {
        print("OpenSSL not found. Attempting to install via Homebrew...")
        if runCommand("/usr/bin/ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"") != nil {
            if runCommand("brew install openssl") != nil {
                print("OpenSSL installed successfully.")
            } else {
                print("Failed to install OpenSSL.")
            }
        } else {
            print("Failed to install Homebrew.")
        }
    } else {
        print("OpenSSL is already installed.")
    }
}

installOpenSSL()
