//
//  PrivilegedToolConnection.swift
//  OpenDirectoryServer
//
//  Created by William Kent on 6/5/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Foundation
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

		try Authorization.authorizationRightsUpdateDatabase(bundle: MainBundle, stringTableName: "Authorization")
	}
}
