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

fileprivate let wizardBundle = Bundle(for: WizardWindowViewController.self)

internal final class WizardWindowViewController: WizardViewController {
	public static func create(dataSource: WizardDataSource, completionHandler: CompletionHandler?) -> WizardWindowViewController {
		let storyboard = NSStoryboard(name: "DirectoryServiceWizard", bundle: Bundle.main)
		let controller = storyboard.instantiateInitialController() as! WizardWindowViewController

		if let completionHandler = completionHandler {
			controller.configureWith(dataSource, completionHandler: completionHandler)
		} else {
			controller.configureWith(dataSource, completionHandler: { _ in })
		}

		return controller
	}

	// MARK: Outlets & Actions

	@IBOutlet private var backButton: NSButton?
	@IBOutlet private var continueButton: NSButton?
	@IBOutlet private var cancelButton: NSButton?
	@IBOutlet private var mainBox: NSBox?

	// MARK: Lifecycle

	override func viewDidAppear() {
		if let title = self.title, let window = self.view.window {
			window.title = title
		}
	}

	public override func navigateToInitial(wizardStep: WizardStep) {
		let viewController = wizardStep.viewController
		if viewController.parent != nil {
			viewController.removeFromParent()
		}

		addChild(viewController)
		mainBox?.contentView = viewController.view

		backButton?.isEnabled = false
		continueButton?.isEnabled = true
    }

	public override func navigateToNext(wizardStep: WizardStep, placement: WizardStepPlacement) {
		let viewController = wizardStep.viewController
		if viewController.parent != nil {
			viewController.removeFromParent()
		}

		addChild(viewController)
		mainBox?.contentView = viewController.view

		switch placement {
		case .initial:
			backButton?.isEnabled = false
			continueButton?.isEnabled = true
			continueButton?.stringValue = localize("Next", bundle: wizardBundle)

		case .intermediate:
			backButton?.isEnabled = false
			continueButton?.isEnabled = true
			continueButton?.stringValue = localize("Next", bundle: wizardBundle)

		case .final:
			backButton?.isEnabled = false
			continueButton?.isEnabled = true
			continueButton?.stringValue = localize("Finish", bundle: wizardBundle)
		}
    }

    public override func navigateToPrevious(wizardStep: WizardStep, placement: WizardStepPlacement) {
		// Since there is no animation, these two functions are identical.
		self.navigateToNext(wizardStep: wizardStep, placement: placement)
	}
}
