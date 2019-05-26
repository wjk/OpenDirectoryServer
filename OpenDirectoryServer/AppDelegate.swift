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

	// MARK: Installation

	private func showPrivilegedToolAlert() {
		let alert = NSAlert()
		alert.messageText = localize("Open Directory Server must install a privileged helper tool for it to be able to create Open Directory databases.", table: "Localizable")
		alert.addButton(withTitle: localize("Install", table: "Localizable"))
		alert.addButton(withTitle: localize("Quit", table: "Localizable"))

		let buttonCode = alert.runModal()
		if buttonCode == NSApplication.ModalResponse.alertFirstButtonReturn {
			installPrivilegedTool()
		} else {
			NSApplication.shared.terminate(nil)
		}
	}

	private func installPrivilegedTool() {
		do {
			guard let authRef = try Authorization.emptyAuthorizationRef() else {
				fatalError("Could not create empty AuthorizationRef")
			}

			let right = AuthorizationRight(name: kSMRightModifySystemDaemons, description: "")
			try Authorization.verifyAuthorization(authRef, forAuthorizationRight: right, promptText: nil)

			var error: Unmanaged<CFError>? = nil
			let success = SMJobBless(kSMDomainSystemLaunchd, "me.sunsol.OpenDirectoryServer.PrivilegedHelperTool" as CFString, authRef, &error)
			if !success {
				let errorAlert = NSAlert()
				errorAlert.messageText = localize("The privileged helper tool could not be registered.", table: "Localizable")
				if let error = error {
					errorAlert.informativeText = error.takeRetainedValue().localizedDescription
				}
				errorAlert.addButton(withTitle: localize("OK", table: "Localizable"))
				errorAlert.runModal()
				NSApplication.shared.terminate(nil)
			}
		} catch AuthorizationError.canceled {
			NSApplication.shared.terminate(nil)
		} catch AuthorizationError.denied {
			let errorAlert = NSAlert()
			errorAlert.messageText = localize("You do not have permission to install helper tools.", table: "Localizable")
			errorAlert.informativeText = localize("Please consult your system administrator for further information.", table: "Localizable")
			errorAlert.addButton(withTitle: localize("OK", table: "Localizable"))
			errorAlert.runModal()
			NSApplication.shared.terminate(nil)
		} catch AuthorizationError.message(let message) {
			let errorAlert = NSAlert()
			errorAlert.messageText = localize("The privileged helper tool could not be registered.", table: "Localizable")
			errorAlert.informativeText = message
			errorAlert.addButton(withTitle: localize("OK", table: "Localizable"))
			errorAlert.runModal()
			NSApplication.shared.terminate(nil)
		} catch {
			fatalError("unhandled error: \(error)")
		}

		do {
			try Authorization.authorizationRightsUpdateDatabase(bundle: MainBundle, stringTableName: "Authorization")
		} catch {
			NSLog("Failed to create authorization rights, ignoring as this isn't a fatal error")
		}
	}
}

// MARK: -

internal let MainBundle = Bundle(for: AppDelegate.self)
func localize(_ key: String, table: String) -> String {
	return MainBundle.localizedString(forKey: key, value: nil, table: table)
}
