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

import Foundation
import AppKit

open class WizardViewController: NSViewController, WizardDelegate {
	public typealias CompletionHandler = (_ canceled: Bool) -> Void

	private(set) open var wizard: Wizard?
	private var completionHandler: CompletionHandler?

	private func invokeCompletionHandler(canceled: Bool) {
		if let completionHandler = completionHandler {
			completionHandler(canceled)
			self.completionHandler = nil
		}
	}

	open func configureWith(_ dataSource: WizardDataSource, completionHandler: @escaping CompletionHandler) {
		precondition(wizard == nil, "The wizard view controller can only be initialized once.")

		self.completionHandler = completionHandler
		wizard = Wizard(dataSource: dataSource, delegate: self)
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		if let wizard = wizard, wizard.currentStep == nil {
			wizard.navigateToInitialStep()
		}
	}

	// MARK: For Subclassers

	open var isNavigating: Bool = false

    /// Subclasses must override this method to display the initial wizard step. Do not call the super implementation.
    open func navigateToInitial(wizardStep: WizardStep) {
        preconditionFailure("\(Mirror(reflecting: self).subjectType) does not properly override \(#function)")
    }

    /// Subclasses must override this method to display the next wizard step. Do not call the super implementation.
    open func navigateToNext(wizardStep: WizardStep, placement: WizardStepPlacement) {
        preconditionFailure("\(Mirror(reflecting: self).subjectType) does not properly override \(#function)")
    }

    /// Subclasses must override this method to display the previous wizard step. Do not call the super implementation.
    open func navigateToPrevious(wizardStep: WizardStep, placement: WizardStepPlacement) {
        preconditionFailure("\(Mirror(reflecting: self).subjectType) does not properly override \(#function)")
    }

	// MARK: Actions

	@IBAction public func navigateToNextStep(_ sender: AnyObject?) {
		if !isNavigating {
			wizard?.navigateToNextStep()
		}
	}

	@IBAction public func navigateToPreviousStep(_ sender: AnyObject?) {
		if !isNavigating {
			wizard?.navigateToPreviousStep()
		}
	}

	@IBAction public func cancelWizard(_ sender: AnyObject?) {
		invokeCompletionHandler(canceled: true)
	}

	// MARK: WizardDelegate

	public func wizardDidCancel(_ wizard: Wizard) {
		invokeCompletionHandler(canceled: true)
	}

	public func wizardDidFinish(_ wizard: Wizard) {
		invokeCompletionHandler(canceled: false)
	}

	public func wizard(_ wizard: Wizard, didNavigateToInitialStep step: WizardStep) {
		navigateToInitial(wizardStep: step)
	}

	public func wizard(_ wizard: Wizard, didNavigateToNextStep step: WizardStep, placement: WizardStepPlacement) {
		navigateToNext(wizardStep: step, placement: placement)
	}

	public func wizard(_ wizard: Wizard, didNavigateToPreviousStep step: WizardStep, placement: WizardStepPlacement) {
		navigateToPrevious(wizardStep: step, placement: placement)
	}
}
