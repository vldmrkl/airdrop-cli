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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let argCount = Int(CommandLine.argc)
        guard argCount >= 2 else {
            consoleIO.printUsage()
            exit(0)
        }

        let argument = CommandLine.arguments[1]
        if argCount == 2 && argument.hasPrefix("-") {
            let (option, _) = getOption(argument)

            if option == .help {
                consoleIO.printUsage()
            } else {
                consoleIO.writeMessage("Unknown option, see usage.\n", to: .error)
                consoleIO.printUsage()
            }

            exit(0)
        }

        let pathsToFiles = Array(CommandLine.arguments[1 ..< argCount])

        shareFiles(pathsToFiles)

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

        var filesToShare: [URL] = []

        for pathToFile in pathsToFiles {
            if let url = URL(string: pathToFile), url.scheme != nil {
                filesToShare.append(url)
            } else {
                let fileURL: URL = NSURL.fileURL(withPath: pathToFile, isDirectory: false)
                filesToShare.append(fileURL.standardizedFileURL)
            }
        }

        if service.canPerform(withItems: filesToShare) {
            service.delegate = self
            service.perform(withItems: filesToShare)
        }  else {
            consoleIO.writeMessage("Can't perform: file is likely to be nonexistent.", to: .error)
            exit(1)
        }
    }

    func sharingService(_ sharingService: NSSharingService, willShareItems items: [Any]) {
        consoleIO.writeMessage("Sending \(items.count) files:")
        for item in items {
            consoleIO.writeMessage("📩 \(item)")
        }
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        consoleIO.writeMessage("✅ Files were sent successfully!")
        exit(0)
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        consoleIO.writeMessage(error.localizedDescription, to: .error)
        exit(1)
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

        return airDropMenuWindow
    }
}
