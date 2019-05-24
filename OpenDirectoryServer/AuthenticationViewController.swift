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

class AuthenticationViewController: NSViewController, NSTextFieldDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		updateUI()
	}

	override var representedObject: Any? {
		didSet {
			updateUI()
		}
	}

	private var model: SVRDirectoryNode? {
		get {
			guard let representedObject = representedObject else {
				return nil
			}

			guard let model = representedObject as? SVRDirectoryNode else {
				fatalError("model not of type SVRDirectoryNode")
			}

			return model
		}
	}

	// MARK: IBOutlets & IBActions

	@IBOutlet private var instructionLabel: NSTextField?
	@IBOutlet private var usernameField: NSTextField?
	@IBOutlet private var passwordField: NSTextField?
	@IBOutlet private var savePasswordCheckbox: NSButton?
	@IBOutlet private var loginButton: NSButton?

	@IBAction private func connect(_ sender: AnyObject?) {
		guard let model = model, let usernameField = usernameField, let passwordField = passwordField else {
			NSSound.beep()
			return
		}

		model.userName = usernameField.stringValue
		model.password = passwordField.stringValue

		if !model.authenticate() {
			let alert = NSAlert()
			alert.messageText = localize("The specified username and/or password is incorrect.", table: "Localizable")
			alert.informativeText = localize("Please try again.", table: "Localizable")
			alert.addButton(withTitle: localize("OK", table: "Localizable"))
			alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
			return
		}

		if let savePasswordCheckbox = savePasswordCheckbox, savePasswordCheckbox.state == .on {
			do {
				try model.saveCredentials()
			} catch {
				let alert = NSAlert(error: error as NSError)
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			}
		}

		self.dismiss(sender)
	}

	func controlTextDidChange(_ obj: Notification) {
		if let loginButton = loginButton, let usernameField = usernameField, let passwordField = passwordField {
			loginButton.isEnabled = usernameField.stringValue != "" && passwordField.stringValue != ""
		}
	}

	private func updateUI() {
		guard let model = model else {
			return
		}

		if let instructionLabel = instructionLabel {
			if model.nodeName == "/Local/Default" {
				instructionLabel.stringValue = localize("Please enter the name and password of a local administrator.", table: "Localizable")
			} else if model.nodeName == "/LDAPv3/127.0.0.1" {
				instructionLabel.stringValue = localize("Please enter the name and password of an administrator in the local Open Directory domain.", table: "Localizable")
			} else if model.nodeName.hasPrefix("/LDAPv3/") {
				let serverAddress = model.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")
				let text = String(format: localize("Please enter the name and password of an administrator in the Open Directory domain on the server %@.", table: "Localizable"), serverAddress)
				instructionLabel.stringValue = text
			}
		}
	}
}