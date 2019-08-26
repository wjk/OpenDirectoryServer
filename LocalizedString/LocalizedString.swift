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

public func localize(_ string: LocalizedStringBuilder, table: String? = nil, bundle: Bundle? = nil) -> String {
	return string.resolve(tableName: table, bundle: bundle)
}

public struct LocalizedStringBuilder: ExpressibleByStringInterpolation {
	public typealias StringLiteralType = String
	fileprivate typealias InterpolatedValueProvider = () -> CVarArg

	private let key: String
	private let valueProviders: [InterpolatedValueProvider]

	public init(stringLiteral: String) {
		self.key = stringLiteral
		self.valueProviders = []
	}

	public init(stringInterpolation: StringInterpolation) {
		self.key = stringInterpolation.key
		self.valueProviders = stringInterpolation.providers
	}

	public func resolve(tableName table: String? = nil, bundle: Bundle? = nil) -> String {
		let bundle = bundle ?? Bundle.main

		if valueProviders.count > 0 {
			let arguments = valueProviders.map { provider in provider() }
			let format = bundle.localizedString(forKey: self.key, value: nil, table: table)
			return String.localizedStringWithFormat(format, arguments)
		} else {
			return bundle.localizedString(forKey: self.key, value: nil, table: table)
		}
	}

	public struct StringInterpolation: StringInterpolationProtocol {
		public typealias StringLiteralType = String

		fileprivate var key = ""
		fileprivate var providers: [InterpolatedValueProvider] = []

		public init(literalCapacity: Int, interpolationCount: Int) {
		}

		public mutating func appendLiteral(_ literal: String) {
			key += literal
		}

		public mutating func appendInterpolation(_ value: String) {
			key += "%@"
			providers.append { value as NSString }
		}

		public mutating func appendInterpolation<Subject: CustomStringConvertible>(_ object: Subject) {
			key += "%@"
			providers.append { object.description as NSString }
		}

		public mutating func appendInterpolation<Subject>(_ object: Subject, formatter: Formatter) {
			key += "%@"
			providers.append {
				guard let string = formatter.string(for: object) else {
					fatalError("Could not convert object to string")
				}
				return string as NSString
			}
		}

		public mutating func appendInterpolation(value: Int) {
			key += "%ld"
			providers.append { value }
		}
	}
}
