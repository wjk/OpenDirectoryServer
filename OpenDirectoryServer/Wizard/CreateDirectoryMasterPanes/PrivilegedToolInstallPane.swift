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
import LocalizedString

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
