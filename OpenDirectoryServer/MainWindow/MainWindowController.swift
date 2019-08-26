/*
 * Open Directory Server - app for macOS Mojave
 * Copyright (C) 2019 William Kent
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Cocoa
import SVRUserManagement
import LocalizedString

internal final class MainWindowController: NSWindowController, NSWindowDelegate {
	internal static func create(directoryNode: SVRDirectoryNode) -> MainWindowController {
		guard let storyboard = NSStoryboard.main else {
			fatalError("Could not retrieve main storyboard")
		}

		let controller = storyboard.instantiateController(withIdentifier: "SVRMainWindow") as! MainWindowController
		controller.model = directoryNode
		return controller
	}

	// MARK: Lifecycle

	func windowDidBecomeMain(_ notification: Notification) {
		if let model = model {
			let appDelegate = NSApp.delegate as! AppDelegate
			appDelegate.windowControllers[model.nodeName] = self
		}
	}

	func windowWillClose(_ notification: Notification) {
		if let model = model {
			let appDelegate = NSApp.delegate as! AppDelegate
			appDelegate.windowControllers.removeValue(forKey: model.nodeName)
		}
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
			window.title = localize("Local Directory")
		} else if model.nodeName.hasPrefix("/LDAPv3/") {
			var serverName = model.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")
			if serverName == "127.0.0.1" {
				serverName = localize("This Mac")
			}
			window.title = localize("\(serverName) (Open Directory Server)")
		} else {
			NSLog("Unknown node type, this shouldn't happen")
			window.title = model.nodeName
		}

		contentViewController?.representedObject = model
	}
}
