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
import ServiceManagement

internal enum PrivilegedToolConnection {
	static var isAvailable: Bool {
		get {
			let semaphore = DispatchSemaphore(value: 0)
			var result = true

			let connection = createConnection(responseProtocol: nil)
			connection.invalidationHandler = {
				result = false
				semaphore.signal()
			}

			connection.resume()
			let remoteObject = connection.remoteObjectProxy as! HelperToolRequestProtocol
			remoteObject.getProtocolVersion {
				(version) in
				result = version == HelperToolVersion
				semaphore.signal()
			}

			semaphore.wait()
			return result
		}
	}

	// Returns `true` if the user clicked Install.
	static func showInstallRequiredSheet(parentWindow: NSWindow) -> Bool {
		let alert = NSAlert()
		alert.messageText = localize("Open Directory Server must install or update a privileged helper tool to complete this operation.")
		let defaultButton = alert.addButton(withTitle: localize("Install"))
		defaultButton.keyEquivalent = "\r"
		alert.addButton(withTitle: localize("Cancel"))

		alert.beginSheetModal(for: parentWindow) {
			(returnCode) in
			NSApp.stopModal(withCode: returnCode)
		}

		let returnCode = NSApp.runModal(for: alert.window)
		return returnCode == .alertFirstButtonReturn
	}

	static func createHelperToolProxy(responseObject: HelperToolResponseProtocol?) -> (NSXPCConnection, HelperToolRequestProtocol) {
		let connection = createConnection(responseProtocol: responseObject)
		connection.resume()
		return (connection, connection.remoteObjectProxy as! HelperToolRequestProtocol)
	}

	private static func createConnection(responseProtocol: HelperToolResponseProtocol?) -> NSXPCConnection {
		let connection = NSXPCConnection(machServiceName: "me.sunsol.OpenDirectoryServer.PrivilegedHelperTool", options: .privileged)

		connection.exportedObject = responseProtocol
		connection.exportedInterface = NSXPCInterface(with: HelperToolResponseProtocol.self)
		connection.remoteObjectInterface = NSXPCInterface(with: HelperToolRequestProtocol.self)

		return connection
	}

	static func updateConnection() throws {
		guard let authRef = try Authorization.emptyAuthorizationRef() else {
			fatalError("Could not create empty AuthorizationRef")
		}

		let right = AuthorizationRight(name: kSMRightModifySystemDaemons, description: "")
		try Authorization.verifyAuthorization(authRef, forAuthorizationRight: right, promptText: nil)

		var error: Unmanaged<CFError>? = nil
		let success = SMJobBless(kSMDomainSystemLaunchd, "me.sunsol.OpenDirectoryServer.PrivilegedHelperTool" as CFString, authRef, &error)
		if !success {
			if let error = error {
				throw error.takeRetainedValue()
			} else {
				// FIXME: Throw a better error here
				throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
			}
		}

		try Authorization.authorizationRightsUpdateDatabase(bundle: Bundle.main, stringTableName: "Authorization")
	}
}
