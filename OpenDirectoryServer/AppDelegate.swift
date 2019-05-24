//
//  AppDelegate.swift
//  Open Directory Server
//
//  Created by William Kent on 5/3/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	override init() {
		guard let storyboard = NSStoryboard.main else {
			fatalError("Could not get main storyboard")
		}

		connectToServerWindowController = storyboard.instantiateController(withIdentifier: "SVRConnectWindow") as! NSWindowController
	}

	private let connectToServerWindowController: NSWindowController

	func applicationDidFinishLaunching(_ notification: Notification) {
		connectToServerWindowController.showWindow(nil)
	}

	func applicationWillTerminate(_ notification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

	// MARK: IBActions

	@IBAction private func showConnectToServerWindow(_ sender: AnyObject?) {
		connectToServerWindowController.showWindow(sender)
	}
}

// MARK: -

internal let MainBundle = Bundle(for: AppDelegate.self)
func localize(_ key: String, table: String) -> String {
	return MainBundle.localizedString(forKey: key, value: nil, table: table)
}
