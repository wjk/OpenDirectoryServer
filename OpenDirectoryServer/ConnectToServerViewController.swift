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

class ConnectToServerViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}

	private var observers: [AnyKeyPath: [KVOObserver]] = [
		\AuthenticationViewController.authSuccess: []
	]

	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		if segue.identifier == "SVRAuthenticationSheet" {
			let destinationController = segue.destinationController as! AuthenticationViewController
			destinationController.representedObject = selectedDirectoryNode

			let observer = destinationController.KVO.addObserver(keyPath: \AuthenticationViewController.authSuccess, options: [.afterChange]) {
				(_, value) in
				self.observers[\AuthenticationViewController.authSuccess]?.removeAll()

				if value {
					self.view.window!.close()
				}
			}

			observers[\AuthenticationViewController.authSuccess]!.append(observer)
		}
	}

	private var selectedDirectoryNode: SVRDirectoryNode?

	// MARK: IBOutlets & IBActions

	@IBOutlet private var nodeTableView: NSTableView?
	@IBOutlet private var continueButton: NSButton?

	@IBAction private func connect(_ sender: AnyObject?) {
		guard let nodeTableView = nodeTableView, nodeTableView.selectedRow != -1 else {
			NSSound.beep()
			return
		}

		let model = tableRows[nodeTableView.selectedRow]
		if model.nodeType == .createLocalLDAPLink {
			// FIXME: Implement this
			NSSound.beep()
		} else {
			// Active Directory nodes cannot be edited using this application.
			// (Theoretically, the OpenDirectory subsystem might be able to do so,
			// but I wouldn't count on it working properly, plus I have no Active
			// Directory server to test against.)
			if model.nodeName.hasPrefix("/Active Directory/") {
				let alert = NSAlert()
				alert.messageText = localize("This application cannot edit Active Directory domains.", table: "Localizable")
				alert.addButton(withTitle: localize("OK", table: "Localizable"))
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			}

			let node: SVRDirectoryNode
			do {
				node = try SVRDirectoryNode(name: model.nodeName)
			} catch {
				NSLog("Could not connect to \(model.nodeName): \(error)")
				let alert = NSAlert()
				alert.messageText = String(format: localize("The Open Directory domain on the server \"%@\" couldn't be contacted.", table: "Localizable"), model.nodeName.replacingOccurrences(of: "/LDAPv3/", with: ""))
				alert.addButton(withTitle: localize("OK", table: "Localizable"))
				alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
				return
			}

			self.selectedDirectoryNode = node
			var credentialsOK = node.loadSavedCredentials()
			if credentialsOK {
				credentialsOK = node.authenticate()
			}

			if credentialsOK {
				let controller = MainWindowController.create(directoryNode: node)
				controller.showWindow(sender)
				self.view.window!.close()
			} else {
				performSegue(withIdentifier: "SVRAuthenticationSheet", sender: sender)
			}
		}
	}

	// MARK: NSTableView

	private var tableRows: [TableDataModel] = []
	private class TableDataModel {
		enum NodeType {
			case localDirectory
			case localLDAP
			case remote
			case createLocalLDAPLink // not really a node type
		}

		init(nodeName: String, nodeType: NodeType) {
			self.nodeName = nodeName
			self.nodeType = nodeType
		}

		let nodeName: String
		let nodeType: NodeType
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		if tableRows.count == 0 {
			let directoryNodes: [SVRDirectoryNode]
			do {
				directoryNodes = try SVRDirectoryNode.allNodesBoundToLocalComputer()
			} catch {
				NSLog("Could not retrieve list of directory nodes: \(error as NSError)")
				return 0
			}

			var localLDAPNode: SVRDirectoryNode?
			var localOnlyNode: SVRDirectoryNode?
			for node in directoryNodes {
				if node.nodeName == "/LDAPv3/127.0.0.1" {
					localLDAPNode = node
				} else if node.nodeName == "/Local/Default" {
					localOnlyNode = node
				}
			}

			tableRows.removeAll()
			if let localOnlyNode = localOnlyNode {
				tableRows.append(TableDataModel(nodeName: localOnlyNode.nodeName, nodeType: .localDirectory))
			}

			if let localLDAPNode = localLDAPNode {
				tableRows.append(TableDataModel(nodeName: localLDAPNode.nodeName, nodeType: .localLDAP))
			} else {
				tableRows.append(TableDataModel(nodeName: "/LDAPv3/127.0.0.1", nodeType: .createLocalLDAPLink))
			}

			for node in directoryNodes {
				if node == localLDAPNode || node == localOnlyNode {
					continue
				}

				tableRows.append(TableDataModel(nodeName: node.nodeName, nodeType: .remote))
			}
		}

		return tableRows.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let rowData = tableRows[row]

		if rowData.nodeType == .localDirectory {
			return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("LocalDirectoryCell"), owner: nil)
		} else if rowData.nodeType == .localLDAP {
			return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("LocalLDAPCell"), owner: nil)
		} else if rowData.nodeType == .createLocalLDAPLink {
			return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("CreateLocalLDAPCell"), owner: nil)
		} else if rowData.nodeType == .remote {
			let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("RemoteLDAPCell"), owner: nil) as! NSTableCellView

			if rowData.nodeName.hasPrefix("/LDAPv3/") {
				let remoteName = rowData.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")
				let formattedName = String(format: localize("%@ (Open Directory Server)", table: "Localizable"), remoteName)
				view.textField?.stringValue = formattedName
			} else if rowData.nodeName.hasPrefix("/Active Directory/") {
				let remoteName = rowData.nodeName.replacingOccurrences(of: "/Active Directory/", with: "")
				let formattedName = String(format: localize("%@ (Active Directory Server)", table: "Localizable"), remoteName)
				view.textField?.stringValue = formattedName
			}

			return view
		} else {
			return nil
		}
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		guard let nodeTableView = nodeTableView, let continueButton = continueButton else {
			return
		}

		if nodeTableView.selectedRow == -1 {
			continueButton.title = localize("Connect...", table: "Localizable")
			continueButton.isEnabled = false
		} else {
			let rowData = tableRows[nodeTableView.selectedRow]
			if rowData.nodeType == .createLocalLDAPLink {
				continueButton.title = localize("Create...", table: "Localizable")
			} else {
				continueButton.title = localize("Connect...", table: "Localizable")
			}

			continueButton.isEnabled = true
		}
	}
}
