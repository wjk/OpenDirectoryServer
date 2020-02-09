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

public final class Wizard {
	private(set) internal var currentStep: WizardStep?
	private let dataSource: WizardDataSource
	private weak var delegate: WizardDelegate?
	private var isTransitioning = false

	public init(dataSource: WizardDataSource, delegate: WizardDelegate) {
		self.dataSource = dataSource
		self.delegate = delegate
	}

	public func navigateToInitialStep() {
		precondition(Thread.isMainThread, "Wizard should only be used on the main thread.")

		guard currentStep == nil else {
			preconditionFailure("Cannot go to the initial step more than once.")
		}

		let initialStep = dataSource.initialWizardStep
		navigateTo(initialStep)
	}

	public func navigateToNextStep() {
		precondition(Thread.isMainThread, "Wizard should only be used on the main thread.")

		guard let currentStep = currentStep else {
			return
		}

		guard !isTransitioning else {
			return
		}

		isTransitioning = true
		currentStep.beforeNavigationToNextStep {
			[weak self] (continueNavigation) in
			precondition(Thread.isMainThread, "Wizard should only be used on the main thread.")
			if continueNavigation {
				self?.navigateToStepAfter(currentStep)
			}
			self?.isTransitioning = false
		}
	}

	public func navigateToPreviousStep() {
		precondition(Thread.isMainThread, "Wizard should only be used on the main thread.")

		guard let currentStep = currentStep else {
			return
		}

		guard !isTransitioning else {
			return
		}

		isTransitioning = true
		currentStep.beforeNavigationToPreviousStep {
			[weak self] (continueNavigation) in
			precondition(Thread.isMainThread, "Wizard should only be used on the main thread.")
			if continueNavigation {
				self?.navigateToStepBefore(currentStep)
			}
			self?.isTransitioning = false
		}
	}

	// MARK: Implementation

	private func navigateTo(_ step: WizardStep) {
		currentStep = step
		delegate?.wizard(self, didNavigateToInitialStep: step)
	}

	private func navigateToStepAfter(_ wizardStep: WizardStep) {
		if let currentStep = dataSource.wizardStepAfter(wizardStep: wizardStep) {
			let placement = dataSource.placementOf(wizardStep: currentStep)
			delegate?.wizard(self, didNavigateToNextStep: currentStep, placement: placement)
		} else {
			delegate?.wizardDidFinish(self)
		}
	}

	private func navigateToStepBefore(_ wizardStep: WizardStep) {
		if let currentStep = dataSource.wizardStepBefore(wizardStep: wizardStep) {
			let placement = dataSource.placementOf(wizardStep: currentStep)
			delegate?.wizard(self, didNavigateToPreviousStep: currentStep, placement: placement)
		} else {
			delegate?.wizardDidFinish(self)
		}
	}
}

// MARK: -

public extension Wizard {
	static func showModalWizard(dataSource: WizardDataSource, completionHandler: WizardViewController.CompletionHandler?) {
		let storyboard = NSStoryboard(name: "Wizard", bundle: wizardBundle)
		guard let windowController: NSWindowController = storyboard.instantiateInitialController() else {
			preconditionFailure("could not load initial window controller")
		}

		guard let wizardController = windowController.contentViewController as? WizardWindowViewController else {
			preconditionFailure("Content view controller has incorrect type")
		}

		wizardController.initialize(dataSource: dataSource) {
			(canceled) in
			NSApp.stopModal()
			windowController.window?.orderOut(nil)
			completionHandler?(canceled)
		}

		guard let window = windowController.window else {
			preconditionFailure("controller has no window")
		}

		NSApp.runModal(for: window)
	}
}
