//
//  HelperTool.swift
//  PrivilegedHelperTool
//
//  Created by William Kent on 5/24/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Foundation

internal final class HelperTool: NSObject, HelperToolRequestProtocol {
	func getProtocolVersion(reply: @escaping (String) -> Void) {
		reply(HelperToolVersion)
	}

	func createOpenDirectoryMaster(parameters: [String : String], reply: @escaping (NSNumber?, NSError?) -> Void) {
		// Not yet implemented.
		let error = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		reply(nil, error)
	}

	func createOpenDirectoryReplica(parameters: [String : String], reply: @escaping (NSNumber?, NSError?) -> Void) {
		// Not yet implemented.
		let error = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		reply(nil, error)
	}

	func createOpenDirectoryBackup(backupLocation: URL, reply: @escaping (NSNumber?, NSError?) -> Void) {
		// Not yet implemented.
		let error = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		reply(nil, error)
	}

	func restoreOpenDirectoryBackup(backupLocation: URL, reply: @escaping (NSNumber?, NSError?) -> Void) {
		// Not yet implemented.
		let error = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		reply(nil, error)
	}

}
