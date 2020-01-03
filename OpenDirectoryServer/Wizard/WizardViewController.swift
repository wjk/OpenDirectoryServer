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
import LocalizedString

internal class WizardPaneController: NSViewController {
	public let commonKVO = SwiftKVO.Proxy<WizardPaneController>()
	private var kvoIsReady = false

	private func commonInit() {
		commonKVO.owner = self
		kvoIsReady = true
	}

	public override init(nibName: NSNib.Name?, bundle: Bundle?) {
		super.init(nibName: nibName, bundle: bundle)
		commonInit()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}

	public var nextButtonEnabled: Bool = true {
		willSet {
			guard kvoIsReady else { return }
			commonKVO.willChangeValue(keyPath: \.nextButtonEnabled)
		}

		didSet {
			guard kvoIsReady else { return }
			commonKVO.didChangeValue(keyPath: \.nextButtonEnabled)
		}
	}

	public var backButtonEnabled: Bool = false {
		willSet {
			guard kvoIsReady else { return }
			commonKVO.willChangeValue(keyPath: \.backButtonEnabled)
		}

		didSet {
			guard kvoIsReady else { return }
			commonKVO.didChangeValue(keyPath: \.backButtonEnabled)
		}
	}

	public var cancelButtonEnabled: Bool = false {
		willSet {
			guard kvoIsReady else { return }
			commonKVO.willChangeValue(keyPath: \.cancelButtonEnabled)
		}

		didSet {
			guard kvoIsReady else { return }
			commonKVO.didChangeValue(keyPath: \.cancelButtonEnabled)
		}
	}

	public func paneWillBecomeCurrent() {}
	public func paneDidBecomeCurrent() {}

	/// If this property returns `true`, then the "Continue" button will say "Finish" instead.
	public var isFinalPane: Bool { false }

	/// This method is called when Continue is clicked. If it returns `false`, then the navigation will be cancelled.
	/// Use this to implement error sheets or similar.
	public func viewShouldContinue() -> Bool { true }

	public func createNextPane() -> WizardPaneController { fatalError("must be overridden") }
	public func createPreviousPane() -> WizardPaneController { fatalError("must be overridden") }
}

internal final class WizardViewController: NSViewController {
	public static func create(initialPane: WizardPaneController) -> WizardViewController {
		let storyboard = NSStoryboard(name: "DirectoryServiceWizard", bundle: Bundle.main)
		let controller = storyboard.instantiateInitialController() as! WizardViewController
		controller.currentPane = initialPane
		return controller
	}

	private var observers: [AnyKeyPath: [SwiftKVO.Observer]] = [
		\WizardPaneController.backButtonEnabled: [],
		\WizardPaneController.nextButtonEnabled: [],
		\WizardPaneController.cancelButtonEnabled: []
	]

	private var currentPane: WizardPaneController?

	// MARK: Outlets & Actions

	@IBOutlet private var backButton: NSButton?
	@IBOutlet private var continueButton: NSButton?
	@IBOutlet private var cancelButton: NSButton?
	@IBOutlet private var mainBox: NSBox?

	@IBAction private func cancel(_ sender: AnyObject?) {
		guard let currentPane = currentPane else {
			fatalError("currentPane not set")
		}

		if !currentPane.cancelButtonEnabled {
			NSSound.beep()
			return
		}

		self.dismiss(sender)
	}

	@IBAction private func goBack(_ sender: AnyObject?) {
		guard let currentPane = currentPane else {
			fatalError("currentPane not set")
		}

		if !currentPane.backButtonEnabled {
			NSSound.beep()
			return
		}

		self.currentPane = currentPane.createPreviousPane()
		showCurrentPane()
	}

	@IBAction private func goForward(_ sender: AnyObject?) {
		guard let currentPane = currentPane else {
			fatalError("currentPane not set")
		}

		if !currentPane.nextButtonEnabled {
			NSSound.beep()
			return
		}

		if !currentPane.viewShouldContinue() {
			// Don't beep here - that's the pane's responsibility to do, if desired.
			return
		}

		if currentPane.isFinalPane {
			self.dismiss(sender)
		} else {
			self.currentPane = currentPane.createNextPane()
			showCurrentPane()
		}
	}

	// MARK: Lifecycle

	override func viewWillAppear() {
		showCurrentPane()
	}

	override func viewDidAppear() {
		if let title = self.title, let window = self.view.window {
			window.title = title
		}
	}

	private func showCurrentPane() {
		guard let currentPane = currentPane else {
			fatalError("currentPane not set")
		}
		guard let mainBox = mainBox, let backButton = backButton, let continueButton = continueButton, let cancelButton = cancelButton else {
			fatalError("required outlets not set")
		}

		for observer in observers[\WizardPaneController.backButtonEnabled]! { observer.cancel() }
		observers[\WizardPaneController.backButtonEnabled]!.removeAll()
		for observer in observers[\WizardPaneController.nextButtonEnabled]! { observer.cancel() }
		observers[\WizardPaneController.nextButtonEnabled]!.removeAll()
		for observer in observers[\WizardPaneController.cancelButtonEnabled]! { observer.cancel() }
		observers[\WizardPaneController.cancelButtonEnabled]!.removeAll()

		currentPane.paneWillBecomeCurrent()

		mainBox.contentView = currentPane.view
		backButton.isEnabled = currentPane.backButtonEnabled
		continueButton.isEnabled = currentPane.nextButtonEnabled
		cancelButton.isEnabled = currentPane.cancelButtonEnabled

		if currentPane.isFinalPane {
			continueButton.title = localize("Complete")
		} else {
			continueButton.title = localize("Continue")
		}

		if let window = self.view.window {
			var mask = window.styleMask
			if currentPane.cancelButtonEnabled {
				mask.insert(.closable)
			} else {
				mask.remove(.closable)
			}
			window.styleMask = mask
		}

		var observer: SwiftKVO.Observer
		observer = currentPane.commonKVO.addObserver(keyPath: \WizardPaneController.backButtonEnabled, options: [.afterChange]) {
			(_, newValue) in
			backButton.isEnabled = newValue
		}
		observers[\WizardPaneController.backButtonEnabled]!.append(observer)
		observer = currentPane.commonKVO.addObserver(keyPath: \WizardPaneController.nextButtonEnabled, options: [.afterChange]) {
			(_, newValue) in
			continueButton.isEnabled = newValue
		}
		observers[\WizardPaneController.nextButtonEnabled]!.append(observer)
		observer = currentPane.commonKVO.addObserver(keyPath: \WizardPaneController.cancelButtonEnabled, options: [.afterChange]) {
			(_, newValue) in
			cancelButton.isEnabled = newValue
		}
		observers[\WizardPaneController.cancelButtonEnabled]!.append(observer)

		currentPane.paneDidBecomeCurrent()
	}
}
