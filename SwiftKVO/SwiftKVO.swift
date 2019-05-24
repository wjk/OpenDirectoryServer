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

internal typealias ObserverToken = UInt
internal typealias ProxyData = (options: Set<KVOChangeType>, callbackHolder: AnyObject)

public enum KVOChangeType {
	case beforeChange
	case afterChange
	case initial
}

public final class KVOObserver {
	internal init(callback: @escaping () -> Void) {
		self.callback = callback
	}

	deinit {
		cancel()
	}

	private var callback: () -> Void

	public func cancel() {
		callback()
	}
}

public final class KVOProxy<TObject: AnyObject> {
	private final class CallbackHolder<TProperty> {
		internal typealias Callback = (KVOChangeType, TProperty) -> Void

		internal init(_ callback: @escaping Callback) {
			self.callback = callback
		}

		public var callback: Callback
	}

	public init() {}

	public weak var owner: TObject? {
		willSet {
			if self.owner != nil {
				fatalError("KVOProxy.owner can only be set once")
			}
		}
	}

	private var cache = [AnyKeyPath: [ObserverToken: ProxyData]]()
	private var nextId: ObserverToken = 0

	private func getCachedValue(keyPath: AnyKeyPath, id: ObserverToken) -> ProxyData? {
		if cache[keyPath] == nil {
			cache[keyPath] = [:]
		}

		return cache[keyPath]![id]
	}

	private func setCachedValue(keyPath: AnyKeyPath, id: ObserverToken, value: ProxyData) {
		if cache[keyPath] == nil {
			cache[keyPath] = [:]
		}

		cache[keyPath]![id] = value
	}

	public func addObserver<TProperty>(keyPath: KeyPath<TObject, TProperty>, options: Set<KVOChangeType>, callback: @escaping (KVOChangeType, TProperty) -> Void) -> KVOObserver {
		guard let owner = owner else {
			fatalError("owner died before its KVOProxy did")
		}

		nextId += 1
		let id = nextId

		let holder = CallbackHolder(callback)
		setCachedValue(keyPath: keyPath, id: id, value: (options, holder))

		if options.contains(.initial) {
			callback(.initial, owner[keyPath: keyPath])
		}

		return KVOObserver {
			[weak self] in
			self?.cache[keyPath]?.removeValue(forKey: id)
		}
	}

	public func willChangeValue<TProperty>(keyPath: KeyPath<TObject, TProperty>) {
		guard let owner = owner else {
			fatalError("owner died before its KVOProxy did")
		}

		if let cacheDict = cache[keyPath] {
			let value = owner[keyPath: keyPath]
			for (_, proxyData) in cacheDict {
				let (options, callbackHolder) = proxyData

				if options.contains(.beforeChange) {
					guard let typedHolder = callbackHolder as? CallbackHolder<TProperty> else {
						fatalError("callback type mismatch")
					}
					typedHolder.callback(.beforeChange, value)
				}
			}
		}
	}

	public func didChangeValue<TProperty>(keyPath: KeyPath<TObject, TProperty>) {
		guard let owner = owner else {
			fatalError("owner died before its KVOProxy did")
		}

		if let cacheDict = cache[keyPath] {
			let value = owner[keyPath: keyPath]
			for (_, proxyData) in cacheDict {
				let (options, callbackHolder) = proxyData

				if options.contains(.afterChange) {
					guard let typedHolder = callbackHolder as? CallbackHolder<TProperty> else {
						fatalError("callback type mismatch")
					}
					typedHolder.callback(.afterChange, value)
				}
			}
		}
	}
}
