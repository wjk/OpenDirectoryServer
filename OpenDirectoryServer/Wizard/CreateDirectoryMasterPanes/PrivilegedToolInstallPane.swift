//
//  PrivilegedToolInstallPane.swift
//  OpenDirectoryServer
//
//  Created by William Kent on 6/5/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Cocoa

internal final class PrivilegedToolInstallPaneController: WizardPaneController {
	internal static func create(previousPaneCallback: @escaping () -> WizardPaneController, nextPaneCallback: @escaping () -> WizardPaneController) -> PrivilegedToolInstallPaneController {
		let storyboard = NSStoryboard(name: "DirectoryServiceWizard", bundle: Bundle.main)
		let controller = storyboard.instantiateController(withIdentifier: "PrivilegedToolPane") as! PrivilegedToolInstallPaneController
		controller.createPreviousPaneCallback = previousPaneCallback
		controller.createNextPaneCallback = nextPaneCallback
		return controller
	}

	// MARK: Wizard Lifecycle

	private var createPreviousPaneCallback: (() -> WizardPaneController)?
	private var createNextPaneCallback: (() -> WizardPaneController)?

	override func paneWillBecomeCurrent() {
		nextButtonEnabled = PrivilegedToolConnection.isAvailable
		backButtonEnabled = true
		cancelButtonEnabled = true
		installButton?.isEnabled = !nextButtonEnabled
	}

	override func createNextPane() -> WizardPaneController {
		return createNextPaneCallback!()
	}

	override func createPreviousPane() -> WizardPaneController {
		return createPreviousPaneCallback!()
	}

	// MARK: Outlets & Actions

	@IBOutlet private var installButton: NSButton?

	@IBAction private func installHelperTool(_ sender: AnyObject?) {
		guard let installButton = installButton else {
			NSSound.beep()
			return
		}

		if !PrivilegedToolConnection.isAvailable {
			do {
				try PrivilegedToolConnection.updateConnection()
			} catch AuthorizationError.canceled {
				// Don't show an error here.
				return
			} catch AuthorizationError.denied {
				let alert = NSAlert()
				alert.messageText = localize("You do not have permission to install helper tools.", table: "Localizable")
				alert.informativeText = localize("Please consult your system administrator for further information.", table: "Localizable")
				alert.addButton(withTitle: localize("OK", table: "Localizable"))
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			} catch AuthorizationError.message(let message) {
				let alert = NSAlert()
				alert.messageText = localize("The privileged helper tool could not be registered.", table: "Localizable")
				alert.informativeText = message
				alert.addButton(withTitle: localize("OK", table: "Localizable"))
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			} catch _ {
				let alert = NSAlert()
				alert.messageText = localize("The privileged helper tool could not be registered.", table: "Localizable")
				alert.addButton(withTitle: localize("OK", table: "Localizable"))
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			}
		}

		installButton.isEnabled = false
		nextButtonEnabled = true
	}
}
