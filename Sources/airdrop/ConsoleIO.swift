//
//  ConsoleIO.swift
//  airdrop
//
//  Created by Volodymyr Klymenko on 2020-12-30.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("\n❌ Error: \(message)\n", stderr)
        }
    }

    func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent

        writeMessage("usage: \(executableName) [<args>]")
        writeMessage("    args – URLs or paths to files, which you'd like to AirDrop")
        writeMessage("\nOPTIONS:")
        writeMessage("    -h, --help – print help info")
    }
}
