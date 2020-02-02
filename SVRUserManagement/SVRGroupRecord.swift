//
//  SVRGroupRecord.swift
//  SVRUserManagement
//
//  Created by William Kent on 2/2/20.
//  Copyright © 2020 William Kent. All rights reserved.
//

import Foundation

public extension SVRGroupRecord {
	var isSystemAccount: Bool {
		guard let names = try? self.stringValues(forAttribute: .shortName) else {
			preconditionFailure("Could not get short name(s) for group")
		}

		for name in names {
			if name.hasPrefix("_") {
				return true
			}
		}

		guard let groupIds = try? self.stringValues(forAttribute: .posixGroupID) else {
			preconditionFailure("Could not get POSIX GID(s) for group")
		}

		for groupIdString in groupIds {
			if let groupId = Int(groupIdString) {
				if groupId < 500 {
					return true
				}
			}
		}

		return false
	}
}
