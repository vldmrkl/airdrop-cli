//
//  AirDropCLI.swift
//  airdrop
//
//  Created by Volodymyr Klymenko on 2020-12-30.
//

import Foundation

import Cocoa

enum OptionType: String {
    case help = "h"
    case unknown

    init(value: String) {
        switch value {
        case "-h", "--help": self = .help
        default: self = .unknown
        }
    }
}

class AirDropCLI:  NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    let consoleIO = ConsoleIO()
    private var sharingService: NSSharingService?
    private var shareWindow: NSWindow?
    private var isIndividualSharing = false
    private var individualSharingItems: [URL] = []
    private var individualSharingSuccessful = 0
    private var individualSharingFailed = 0
    private var sharingStartTime: Date?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let argCount = Int(CommandLine.argc)

        if argCount >= 2 {
            let argument = CommandLine.arguments[1]
            if argCount == 2 && argument.hasPrefix("-") {
                if argument == "-" {
                    // Process stdin
                    let stdinPaths = readPathsFromStdin()
                    if stdinPaths.isEmpty {
                        consoleIO.printUsage()
                        exit(0)
                    }
                    shareFiles(stdinPaths)
                } else {
                    let (option, _) = getOption(argument)

                    if option == .help {
                        consoleIO.printUsage()
                    } else {
                        consoleIO.writeMessage("Unknown option, see usage.\n", to: .error)
                        consoleIO.printUsage()
                    }

                    exit(0)
                }
            } else {
                let pathsToFiles = Array(CommandLine.arguments[1 ..< argCount])
                shareFiles(pathsToFiles)
            }
        } else {
            consoleIO.printUsage()
            exit(0)
        }

        if #available(macOS 13.0, *) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func getOption(_ option: String) -> (option:OptionType, value: String) {
        return (OptionType(value: option), option)
    }

    func shareFiles(_ pathsToFiles: [String]) {
        guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop)
        else {
            exit(2)
        }
        self.sharingService = service

        var filesToShare: [URL] = []
        var invalidPaths: [String] = []

        for pathToFile in pathsToFiles {
            if let url = URL(string: pathToFile), 
               let scheme = url.scheme?.lowercased(),
               ["http", "https"].contains(scheme) {
                filesToShare.append(url)
            } else {
                let fileURL: URL = NSURL.fileURL(withPath: pathToFile, isDirectory: false)
                
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    filesToShare.append(fileURL.standardizedFileURL)
                } else {
                    invalidPaths.append(pathToFile)
                }
            }
        }
        
        if !invalidPaths.isEmpty {
            consoleIO.writeMessage("Warning: The following paths are invalid")
            for path in invalidPaths {
                consoleIO.writeMessage("    \(path)")
            }
        }
        
        guard !filesToShare.isEmpty else {
            consoleIO.writeMessage("Warning: No valid files or URLs to share.")
            exit(1)
        }
        
        consoleIO.writeMessage("Sharing \(filesToShare.count) items:")
        for (index, url) in filesToShare.enumerated() {
            consoleIO.writeMessage("  \(index + 1). \(url)")
        }

        let hasURLs = filesToShare.contains { $0.scheme == "http" || $0.scheme == "https" }
        let hasFiles = filesToShare.contains { $0.scheme == "file" }
        let isMixedContent: Bool = hasURLs && hasFiles
        
        if isMixedContent {
            // Currently, AirDrop does not support sharing both URLs and files at once. Therefore, we need to share them individually.
            shareItemsIndividually(service: service, filesToShare)
        } else {
            if service.canPerform(withItems: filesToShare) {
                service.delegate = self
                service.perform(withItems: filesToShare)
            } else {
                // If we can't share all items at once, for example, when there is more than 1 URL, we need to share them individually
                shareItemsIndividually(service: service, filesToShare)
            }
        }
    }


    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        if isIndividualSharing {
            individualSharingSuccessful += 1
            guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop) else {
                exit(2)
            }
            self.sharingService = service
            shareNextItem(service: service, remainingItems: individualSharingItems)
        } else {
            consoleIO.writeMessage("✅ Sharing completed: \(items.count) successful")
            self.sharingService = nil
            shareWindow = nil
            exit(0)
        }
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        if isIndividualSharing {
            individualSharingFailed += 1
            consoleIO.writeMessage("Failed to share item: \(error.localizedDescription)", to: .error)
            
            guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop) else {
                exit(2)
            }
            self.sharingService = service
            shareNextItem(service: service, remainingItems: individualSharingItems)
        } else {
            consoleIO.writeMessage(error.localizedDescription, to: .error)
            self.sharingService = nil
            shareWindow = nil
            exit(1)
        }
    }

    func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
        return NSRect(x: 0, y: 0, width: 400, height: 100)
    }

    func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        let airDropMenuWindow = NSWindow(contentRect: .init(origin: .zero,
                                                            size: .init(width: 1,
                                                                        height: 1)),
                                         styleMask: [.closable],
                                         backing: .buffered,
                                         defer: false)

        airDropMenuWindow.center()
        airDropMenuWindow.level = .popUpMenu
        airDropMenuWindow.makeKeyAndOrderFront(nil)

        // Retain the window so it does not get deallocated while the share sheet is active.
        shareWindow = airDropMenuWindow

        return airDropMenuWindow
    }
    
    private func shareItemsIndividually(service: NSSharingService, _ items: [URL]) {
        isIndividualSharing = true
        individualSharingItems = items
        individualSharingSuccessful = 0
        individualSharingFailed = 0
        
        shareNextItem(service: service, remainingItems: items)
    }
    
    private func shareNextItem(service: NSSharingService, remainingItems: [URL]) {
        self.sharingService = service
        guard !remainingItems.isEmpty else {
            consoleIO.writeMessage("✅ Sharing completed: \(individualSharingSuccessful) successful, \(individualSharingFailed) failed")
            shareWindow = nil
            self.sharingService = nil
            exit(individualSharingFailed > 0 ? 1 : 0)
        }
        
        let currentItem = remainingItems.first!
        let remainingItemsAfterCurrent = Array(remainingItems.dropFirst())
        
        if service.canPerform(withItems: [currentItem]) {
            service.delegate = self
            service.perform(withItems: [currentItem])
            individualSharingItems = remainingItemsAfterCurrent
        } else {
            consoleIO.writeMessage("Cannot share: \(currentItem)", to: .error)
            individualSharingFailed += 1
            shareNextItem(service: service, remainingItems: remainingItemsAfterCurrent)
        }
    }

    private func readPathsFromStdin() -> [String] {
        var paths: [String] = []
        
        while let line = readLine() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                paths.append(trimmedLine)
            }
        }
        
        return paths
    }
}
