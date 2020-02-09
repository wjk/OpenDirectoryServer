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

public protocol WizardStep {
	var viewController: NSViewController { get }

	func beforeNavigationToNextStep(completionHandler: (_ shouldNavigate: Bool) -> Void)
	func beforeNavigationToPreviousStep(completionHandler: (_ shouldNavigate: Bool) -> Void)
}

public enum WizardStepPlacement {
	/// The first step displayed in a wizard.
	case initial
	/// A wizard step that is neither `initial` nor `final`.
	case intermediate
	/// The last step displayed in a wizard.
	case final
}
