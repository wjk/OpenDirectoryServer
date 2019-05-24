//
//  MainWindowController.swift
//  OpenDirectoryServer
//
//  Created by William Kent on 5/24/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Cocoa
import SVRUserManagement

internal final class MainWindowController: NSWindowController {
	internal static func create(directoryNode: SVRDirectoryNode) -> MainWindowController {
		guard let storyboard = NSStoryboard.main else {
			fatalError("Could not retrieve main storyboard")
		}

		let controller = storyboard.instantiateController(withIdentifier: "SVRMainWindow") as! MainWindowController
		controller.model = directoryNode
		return controller
	}

	// MARK: Model

	var model: SVRDirectoryNode? {
		didSet {
			updateUI()
		}
	}

	override func windowDidLoad() {
		updateUI()
	}

	private func updateUI() {
		guard let model = model, let window = window else {
			return
		}

		if model.nodeName == "/Local/Default" {
			window.title = localize("Local Directory", table: "Localizable")
		} else if model.nodeName.hasPrefix("/LDAPv3/") {
			var serverName = model.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")
			if serverName == "127.0.0.1" {
				serverName = localize("This Mac", table: "Localizable")
			}
			window.title = String(format: localize("%@ (Open Directory Server)", table: "Localizable"), serverName)
		} else {
			NSLog("Unknown node type, this shouldn't happen")
			window.title = model.nodeName
		}

		contentViewController?.representedObject = model
	}
}
