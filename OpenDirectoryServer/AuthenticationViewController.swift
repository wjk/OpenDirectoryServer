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
import SwiftKVO
import SVRUserManagement
import LocalizedString

class AuthenticationViewController: NSViewController, NSTextFieldDelegate {
	private func commonInit() {
		KVO.owner = self
	}

	public override init(nibName: NSNib.Name?, bundle: Bundle?) {
		super.init(nibName: nibName, bundle: bundle)
		commonInit()
	}

	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}

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

	// MARK: Observable Properties

	internal let KVO = KVOProxy<AuthenticationViewController>()
	private(set) internal var authSuccess = false {
		willSet {
			KVO.willChangeValue(keyPath: \AuthenticationViewController.authSuccess)
		}

		didSet {
			KVO.didChangeValue(keyPath: \AuthenticationViewController.authSuccess)
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

		let appDelegate = NSApp.delegate as! AppDelegate
		if let existingController = appDelegate.findWindowController(directoryNode: model) {
			existingController.showWindow(sender)
		} else {
			let windowController = MainWindowController.create(directoryNode: model)
			windowController.showWindow(sender)
		}

		authSuccess = true
		self.dismiss(sender)
	}

	@IBAction private func cancel(_ sender: AnyObject?) {
		authSuccess = false
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
				instructionLabel.stringValue = localize("Please enter the name and password of an administrator in the Open Directory domain on this Mac.", table: "Localizable")
			} else if model.nodeName.hasPrefix("/LDAPv3/") {
				let serverAddress = model.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")
				let text = localize("Please enter the name and password of an administrator in the Open Directory domain on the server \(serverAddress).")
				instructionLabel.stringValue = text
			}
		}
	}
}
