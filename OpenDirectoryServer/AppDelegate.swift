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
import ServiceManagement
import SVRUserManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	override init() {
		guard let storyboard = NSStoryboard.main else {
			fatalError("Could not get main storyboard")
		}

		connectToServerWindowController = storyboard.instantiateController(withIdentifier: "SVRConnectWindow") as! NSWindowController
	}

	func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
		self.showConnectToServerWindow(nil)
		return true
	}

	// MARK: Window Management

	private let connectToServerWindowController: NSWindowController
	internal var windowControllers: [String: MainWindowController] = [:]

	internal func findWindowController(directoryNode: SVRDirectoryNode) -> MainWindowController? {
		return windowControllers[directoryNode.nodeName]
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
