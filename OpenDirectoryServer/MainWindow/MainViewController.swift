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
import LocalizedString

fileprivate extension NSUserInterfaceItemIdentifier {
	static let headerCell = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
	static let dataCell = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
}

internal final class MainViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSplitViewDelegate, NSUserInterfaceValidations {
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

	private var showsSystemAccounts = false
	private var userAccounts: [SVRUserRecord] = []

	private func updateUI() {
		guard let model = model else {
			return
		}

		do {
			userAccounts = try model.queryAllUserRecords()

			if !showsSystemAccounts {
				userAccounts = userAccounts.filter {
					(record) -> Bool in
					!record.isSystemAccount
				}
			}

			userAccounts = userAccounts.sorted {
				(lhs, rhs) -> Bool in
				let leftName = displayName(forUser: lhs)
				let rightName = displayName(forUser: rhs)
				return leftName.compare(rightName) == .orderedAscending
			}
		} catch let error {
			preconditionFailure("Could not query user records: \(error)")
		}

		sidebar?.reloadData()
	}

	private func displayName(forUser record: SVRUserRecord) -> String {
		if let values = try? record.stringValues(forAttribute: .fullName), values.count > 0 {
			return values[0]
		} else if let values = try? record.stringValues(forAttribute: .shortName), values.count > 0 {
			return values[0]
		} else {
			preconditionFailure("Could not get display name for user record \(record)")
		}
	}

	// MARK: Outlets & Actions

	@IBOutlet private var sidebar: NSOutlineView?

	@IBAction private func toggleSystemUserAccounts(_ sender: AnyObject?) {
		showsSystemAccounts = !showsSystemAccounts
		updateUI()
	}

	func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		if let menuItem = item as? NSMenuItem {
			if menuItem.action == #selector(toggleSystemUserAccounts(_:)) {
				menuItem.state = showsSystemAccounts ? .on : .off
			}
		}

		return true
	}

	// MARK: Outline View

	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		assert(outlineView == sidebar)

		if let item = item {
			guard let name = item as? String else {
				preconditionFailure("item not a string")
			}

			if name == "Users" {
				return userAccounts.count
			} else if name == "Groups" {
				// TODO: Implement
				return 0
			} else {
				return 0
			}
		} else {
			// There are two root items: Users and Groups.
			return 2
		}
	}

	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		assert(outlineView == sidebar)

		if let item = item {
			guard let name = item as? String else {
				preconditionFailure("item not a string")
			}

			if name == "Users" {
				return userAccounts[index]
			} else if name == "Groups" {
				// TODO: Implement
				return ()
			} else {
				preconditionFailure("this item should not have children")
			}
		} else {
			if index == 0 {
				return "Users"
			} else if index == 1 {
				return "Groups"
			} else {
				preconditionFailure("too many children of root item")
			}
		}
	}

	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		assert(outlineView == sidebar)

		if let name = item as? String {
			if name == "Users" {
				let view = outlineView.makeView(withIdentifier: .headerCell, owner: nil) as! NSTableCellView
				view.textField?.stringValue = localize("Users").uppercased(with: Locale.current)
				return view
			} else if name == "Groups" {
				let view = outlineView.makeView(withIdentifier: .headerCell, owner: nil) as! NSTableCellView
				view.textField?.stringValue = localize("Groups").uppercased(with: Locale.current)
				return view
			}
		} else if let record = item as? SVRUserRecord {
			let view = outlineView.makeView(withIdentifier: .dataCell, owner: nil) as! NSTableCellView
			view.textField?.stringValue = displayName(forUser: record)
			return view
		}

		return nil
	}

	func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		assert(outlineView == sidebar)

		if let name = item as? String {
			return name == "Users" || name == "Groups"
		} else if item is SVRUserRecord {
			return false
		} else {
			preconditionFailure("unknown item")
		}
	}

	func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		// Group items should not be selectable.
		return !self.outlineView(outlineView, isGroupItem: item)
	}

	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		// Only group items should be expandable.
		return self.outlineView(outlineView, isGroupItem: item)
	}

	// MARK: NSSplitViewDelegate

	func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
		return false
	}

	func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		if dividerIndex == 0 {
			return view.bounds.width / 4
		} else {
			return proposedMinimumPosition
		}
	}

	func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		if dividerIndex == 0 {
			return view.bounds.width / 3
		} else {
			return proposedMaximumPosition
		}
	}
}
