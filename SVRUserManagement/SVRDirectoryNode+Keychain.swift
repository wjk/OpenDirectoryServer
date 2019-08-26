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
import KeychainAccess
import LocalizedString

public extension SVRDirectoryNode {
	private func createKeychain() -> Keychain {
		let bundle = Bundle(for: SVRDirectoryNode.self)
		let label = localize("Open Directory Server Saved Credential", bundle: bundle)
		let comment = localize("This credential was saved by the Open Directory Server app. Please don't modify it, as then the app won't be able to find it again.", bundle: bundle)

		return Keychain(service: "me.sunsol.OpenDirectoryServer").label(label).comment(comment)
	}

	func saveCredentials() throws {
		guard let userName = self.userName, let password = self.password else {
			throw NSError(domain: SVRCredentialStoreErrors.domain, code: SVRCredentialStoreErrors.noCredentials, userInfo: nil)
		}

		do {
			let keychain = createKeychain()
			let keychainEntryPrefix: String
			if self.nodeName.hasPrefix("/LDAPv3/") {
				let serverName = self.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")

				if serverName == "127.0.0.1" {
					keychainEntryPrefix = "This Mac (Open Directory Server)"
				} else {
					keychainEntryPrefix = "\(serverName) (Open Directory Server)"
				}
			} else if self.nodeName == "/Local/Default" {
				keychainEntryPrefix = "Local Directory Server"
			} else {
				keychainEntryPrefix = "Server \"\(self.nodeName)\""
			}

			try keychain.set(userName, key: "\(keychainEntryPrefix) - User Name")
			try keychain.set(password, key: "\(keychainEntryPrefix) - Password")
		} catch {
			if let code = error as? Status {
				let underlyingError = NSError(domain: NSOSStatusErrorDomain, code: Int(code.rawValue), userInfo: nil)
				let userInfo = [NSUnderlyingErrorKey: underlyingError]
				throw NSError(domain: SVRCredentialStoreErrors.domain, code: SVRCredentialStoreErrors.securityFrameworkFailure, userInfo: userInfo)
			} else {
				fatalError("unexpected error thrown")
			}
		}
	}

	func loadSavedCredentials() -> Bool {
		do {
			let keychain = createKeychain()
			let keychainEntryPrefix: String
			if self.nodeName.hasPrefix("/LDAPv3/") {
				let serverName = self.nodeName.replacingOccurrences(of: "/LDAPv3/", with: "")

				if serverName == "127.0.0.1" {
					keychainEntryPrefix = "This Mac (Open Directory Server)"
				} else {
					keychainEntryPrefix = "\(serverName) (Open Directory Server)"
				}
			} else if self.nodeName == "/Local/Default" {
				keychainEntryPrefix = "Local Directory Server"
			} else {
				keychainEntryPrefix = "Server \"\(self.nodeName)\""
			}

			self.userName = try keychain.get("\(keychainEntryPrefix) - User Name")
			self.password = try keychain.get("\(keychainEntryPrefix) - Password")
			return self.userName != nil && self.password != nil
		} catch {
			if let _ = error as? Status {
				return false
			} else {
				fatalError("unexpected error thrown")
			}
		}
	}
}

public enum SVRCredentialStoreErrors {
	public static let domain = "me.sunsol.OpenDirectoryServer.CredentialStoreErrorDomain"

	/// The `userName` and/or `password` properties were not set.
	public static let noCredentials = 1
	/// The Security framework returned an error. Check the underlying error for details.
	public static let securityFrameworkFailure = 2
}
