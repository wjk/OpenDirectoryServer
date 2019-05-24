//
// This file is based on SwiftPrivilegedHelper.
// Copyright (c) 2018 Erik Berglund
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import Security

internal struct AuthorizationRight {
	internal enum RightName {
		internal static let createMasterServer = "me.sunsol.OpenDirectoryServer.createMaster"
		internal static let createReplicaServer = "me.sunsol.OpenDirectoryServer.createReplica"
		internal static let destroyServer = "me.sunsol.OpenDirectoryServer.destroy"
		internal static let createBackup = "me.sunsol.OpenDirectoryServer.createBackup"
		internal static let restoreBackup = "me.sunsol.OpenDirectoryServer.restoreBackup"
	}

	internal enum Keys {
		static let ruleClass = "class"
		static let group = "group"
		static let rule = "rule"
		static let timeout = "timeout"
		static let version = "version"
	}

	let name: String
	let description: String
	let ruleCustom: [String: Any]?
	let ruleConstant: String?

	init(name: String, description: String, ruleCustom: [String: Any]? = nil, ruleConstant: String? = nil) {
		self.name = name
		self.description = description
		self.ruleCustom = ruleCustom
		self.ruleConstant = ruleConstant
	}

	func rule() -> CFTypeRef {
		let rule: CFTypeRef
		if let ruleCustom = self.ruleCustom as CFDictionary? {
			rule = ruleCustom
		} else if let ruleConstant = self.ruleConstant as CFString? {
			rule = ruleConstant
		} else {
			rule = kAuthorizationRuleAuthenticateAsAdmin as CFString
		}

		return rule
	}
}

enum AuthorizationError: Error {
	case canceled
	case denied
	case message(String)
}

class Authorization {
	// MARK: AuthorizationRights

	private static let authenticateAsAdminRule: [String: Any] = [
		AuthorizationRight.Keys.ruleClass: "user",
		AuthorizationRight.Keys.group: "admin",
		AuthorizationRight.Keys.version: 1
	]

	static let authorizationRights = [
		AuthorizationRight(name: AuthorizationRight.RightName.createMasterServer, description: "Open Directory Server is trying to create an Open Directory master server.", ruleCustom: authenticateAsAdminRule),
		AuthorizationRight(name: AuthorizationRight.RightName.createReplicaServer, description: "Open Directory Server is trying to create an Open Directory replica server.", ruleCustom: authenticateAsAdminRule),
		AuthorizationRight(name: AuthorizationRight.RightName.destroyServer, description: "Web Server is trying to destroy the Open Directory server.", ruleCustom: authenticateAsAdminRule),
		AuthorizationRight(name: AuthorizationRight.RightName.createBackup, description: "Web Server is trying to create a backup of the Open Directory database.", ruleCustom: authenticateAsAdminRule),
		AuthorizationRight(name: AuthorizationRight.RightName.restoreBackup, description: "Web Server is trying to restore a backup of the Open Directory database.", ruleCustom: authenticateAsAdminRule)
	]

	private static func authorizationRight(withName name: String) -> AuthorizationRight? {
		for right in authorizationRights {
			if right.name == name {
				return right
			}
		}

		return nil
	}

	static func authorizationRightsUpdateDatabase(bundle: Bundle?, stringTableName: String?) throws {
		let cfBundle: CFBundle?
		let cfStringTableName: CFString?
		if let bundle = bundle, let bundleIdentifier = bundle.bundleIdentifier {
			cfBundle = CFBundleGetBundleWithIdentifier(bundleIdentifier as CFString)

			guard let stringTableName = stringTableName else {
				fatalError("A string table name must be specified if a bundle is")
			}

			cfStringTableName = stringTableName as CFString
		} else {
			cfBundle = nil
			cfStringTableName = nil
		}

		guard let authRef = try self.emptyAuthorizationRef() else {
			throw AuthorizationError.message("Failed to get empty authorization ref")
		}

		for authorizationRight in self.authorizationRights {
			var osStatus = errAuthorizationSuccess
			var currentRule: CFDictionary?

			osStatus = AuthorizationRightGet(authorizationRight.name, &currentRule)
			if osStatus == errAuthorizationDenied || self.authorizationRuleUpdateRequired(currentRule, authorizationRight: authorizationRight) {
				osStatus = AuthorizationRightSet(authRef, authorizationRight.name, authorizationRight.rule(), authorizationRight.description as CFString, cfBundle, cfStringTableName)
			}

			guard osStatus == errAuthorizationSuccess else {
				NSLog("AuthorizationRightSet or Get failed with error: \(String(describing: SecCopyErrorMessageString(osStatus, nil)))")
				continue
			}
		}
	}

	private static func authorizationRuleUpdateRequired(_ currentRuleCFDict: CFDictionary?, authorizationRight: AuthorizationRight) -> Bool {
		guard let currentRuleDict = currentRuleCFDict as? [String: Any] else {
			return true
		}

		let newRule = authorizationRight.rule()
		if CFGetTypeID(newRule) == CFStringGetTypeID() {
			if
				let currentRule = currentRuleDict[AuthorizationRight.Keys.rule] as? [String],
				let newRule = authorizationRight.ruleConstant {
				return currentRule != [newRule]

			}
		} else if CFGetTypeID(newRule) == CFDictionaryGetTypeID() {
			if let currentVersion = currentRuleDict[AuthorizationRight.Keys.version] as? Int,
				let newVersion = authorizationRight.ruleCustom?[AuthorizationRight.Keys.version] as? Int {
				return currentVersion != newVersion
			}
		}

		return true
	}

	// MARK: Authorization Wrapper

	private static func executeAuthorizationFunction(_ authorizationFunction: () -> (OSStatus) ) throws {
		let osStatus = authorizationFunction()
		guard osStatus == errAuthorizationSuccess else {
			if osStatus == errAuthorizationCanceled {
				throw AuthorizationError.canceled
			} else if osStatus == errAuthorizationDenied {
				throw AuthorizationError.denied
			} else {
				throw AuthorizationError.message(String(describing: SecCopyErrorMessageString(osStatus, nil)))
			}
		}
	}

	// MARK: AuthorizationRef

	static func authorizationRef(_ rights: UnsafePointer<AuthorizationRights>?, _ environment: UnsafePointer<AuthorizationEnvironment>?, _ flags: AuthorizationFlags) throws -> AuthorizationRef? {
		var authRef: AuthorizationRef?
		try executeAuthorizationFunction { AuthorizationCreate(rights, environment, flags, &authRef) }
		return authRef
	}

	static func authorizationRef(fromExternalForm data: NSData) throws -> AuthorizationRef? {

		// Create an AuthorizationExternalForm from it's data representation
		var authRef: AuthorizationRef?
		let authRefExtForm: UnsafeMutablePointer<AuthorizationExternalForm> = UnsafeMutablePointer.allocate(capacity: kAuthorizationExternalFormLength * MemoryLayout<AuthorizationExternalForm>.size)
		memcpy(authRefExtForm, data.bytes, data.length)

		// Extract the AuthorizationRef from it's external form
		try executeAuthorizationFunction { AuthorizationCreateFromExternalForm(authRefExtForm, &authRef) }
		return authRef
	}

	// MARK: Empty Authorization Refs

	static func emptyAuthorizationRef() throws -> AuthorizationRef? {
		var authRef: AuthorizationRef?

		// Create an empty AuthorizationRef
		try executeAuthorizationFunction { AuthorizationCreate(nil, nil, [], &authRef) }
		return authRef
	}

	static func emptyAuthorizationExternalForm() throws -> AuthorizationExternalForm? {

		// Create an empty AuthorizationRef
		guard let authorizationRef = try self.emptyAuthorizationRef() else { return nil }

		// Make an external form of the AuthorizationRef
		var authRefExtForm = AuthorizationExternalForm()
		try executeAuthorizationFunction { AuthorizationMakeExternalForm(authorizationRef, &authRefExtForm) }
		return authRefExtForm
	}

	static func emptyAuthorizationExternalFormData() throws -> NSData? {
		guard var authRefExtForm = try self.emptyAuthorizationExternalForm() else { return nil }

		// Encapsulate the external form AuthorizationRef in an NSData object
		return NSData(bytes: &authRefExtForm, length: kAuthorizationExternalFormLength)
	}

	// MARK: Verification

	static func verifyAuthorization(_ authExtData: NSData?, rightName: String, promptText: String?) throws {
		// Verify that the passed authExtData looks reasonable
		guard let authorizationExtData = authExtData, authorizationExtData.length == kAuthorizationExternalFormLength else {
			throw AuthorizationError.message("Invalid Authorization External Form Data")
		}

		// Convert the external form to an AuthorizationRef
		guard let authorizationRef = try self.authorizationRef(fromExternalForm: authorizationExtData) else {
			throw AuthorizationError.message("Failed to convert the Authorization External Form to an Authorization Reference")
		}

		// Get the authorization right struct for the passed command
		guard let authorizationRight = self.authorizationRight(withName: rightName) else {
			throw AuthorizationError.message("Failed to get the correct authorization right for name: \(rightName)")
		}

		// Verity the user has the right to run the passed command
		try self.verifyAuthorization(authorizationRef, forAuthorizationRight: authorizationRight, promptText: promptText)
	}

	static func verifyAuthorization(_ authRef: AuthorizationRef, forAuthorizationRight authRight: AuthorizationRight, promptText: String?) throws {
		// Get the authorization name in the correct format
		guard let authRightName = (authRight.name as NSString).utf8String else {
			throw AuthorizationError.message("Failed to convert authorization name to C string")
		}

		var envItem: AuthorizationItem
		var authEnvironment: AuthorizationEnvironment

		if let promptText = promptText {
			guard let promptCString = (promptText as NSString).utf8String else {
				throw AuthorizationError.message("Failed to convert prompt text to C string")
			}

			let promptCStringPtr = UnsafeMutableRawPointer(mutating: promptCString)
			envItem = AuthorizationItem(name: kAuthorizationEnvironmentPrompt, valueLength: promptText.lengthOfBytes(using: .utf8), value: promptCStringPtr, flags: 0)

			authEnvironment = AuthorizationEnvironment(count: 1, items: &envItem)
		} else {
			authEnvironment = AuthorizationEnvironment(count: 0, items: nil)
		}

		// Create an AuthorizationItem using the authorization right name
		var authItem = AuthorizationItem(name: authRightName, valueLength: 0, value: UnsafeMutableRawPointer(bitPattern: 0), flags: 0)

		// Create the AuthorizationRights for using the AuthorizationItem
		var authRights = AuthorizationRights(count: 1, items: &authItem)

		// Check if the user is authorized for the AuthorizationRights.
		// If not the user might be asked for an admin credential.
		try executeAuthorizationFunction { AuthorizationCopyRights(authRef, &authRights, &authEnvironment, [.extendRights, .interactionAllowed], nil) }
	}
}
