/*
 * Open Directory Server - app for macOS
 * Copyright (C) 2020 William Kent
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

public extension SVRUserRecord {
	var isSystemAccount: Bool {
		guard let names = try? self.stringValues(forAttribute: .shortName) else {
			preconditionFailure("Could not get short name(s) for user")
		}

		for name in names {
			if name.hasPrefix("_") {
				return true
			} else if name == "root" || name == "daemon" || name == "nobody" {
				return true
			}
		}

		return false
	}

	func append(stringValue newValue: String, toAttribute attributeName: SVRUserAttribute) throws {
		var values = try self.stringValues(forAttribute: attributeName)
		values.append(newValue)
		try self.setStringValues(values, forAttribute: attributeName)
	}

	func append(binaryValue newValue: Data, toAttribute attributeName: SVRUserAttribute) throws {
		var values = try self.binaryValues(forAttribute: attributeName)
		values.append(newValue)
		try self.setBinaryValues(values, forAttribute: attributeName)
	}

	func remove(stringValue valueToRemove: String, fromAttribute attributeName: SVRUserAttribute) throws {
		var values = try self.stringValues(forAttribute: attributeName)
		values.removeAll { $0 == valueToRemove }
		try self.setStringValues(values, forAttribute: attributeName)
	}

	func remove(binaryValue valueToRemove: Data, fromAttribute attributeName: SVRUserAttribute) throws {
		var values = try self.binaryValues(forAttribute: attributeName)
		values.removeAll { $0 == valueToRemove }
		try self.setBinaryValues(values, forAttribute: attributeName)
	}
}
