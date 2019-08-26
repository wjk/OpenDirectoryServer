//
//  SVRDirectoryNode+Keychain.swift
//  SVRUserManagement
//
//  Created by William Kent on 8/25/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Foundation
import KeychainAccess

public extension SVRDirectoryNode {
	private func createKeychain() -> Keychain {
		let bundle = Bundle(for: SVRDirectoryNode.self)
		let label = bundle.localizedString(forKey: "Open Directory Server Saved Credential", value: nil, table: nil)
		let comment = bundle.localizedString(forKey: "This credential was saved by the Open Directory Server app. Please don't modify it, as then the app won't be able to find it again.", value: nil, table: nil)

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
