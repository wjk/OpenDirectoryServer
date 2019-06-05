//
//  PrivilegedToolConnection.swift
//  OpenDirectoryServer
//
//  Created by William Kent on 6/5/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Foundation

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
}
