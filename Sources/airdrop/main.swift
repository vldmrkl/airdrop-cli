//
//  main.swift
//  airdrop
//
//  Created by Volodymyr Klymenko on 2020-12-30.
//

import Cocoa

let airDropCLI = AirDropCLI()
let app = NSApplication.shared

app.delegate = airDropCLI
app.run()
