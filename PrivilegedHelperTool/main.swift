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
import os.log

internal extension OSLog {
	func log(type: OSLogType, message: StaticString, _ args: CVarArg...) {
		os_log(message, log: self, type: type, args)
	}
}

// MARK: -

fileprivate class XPCListenerDelegate: NSObject, NSXPCListenerDelegate {
	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
		let logger = OSLog(subsystem: "me.sunsol.WebServer", category: "Security")

		do {
			let matches = try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
			if !matches {
				logger.log(type: .info, message: "Refusing to connect to pid %{public}d, as its code signing does not match ours", connection.processIdentifier)
				return false
			}
		} catch {
			logger.log(type: .error, message: "Could not verify code signing for pid %{public}d: %{public}@", connection.processIdentifier, String(describing: error))
			return false
		}

		connection.exportedInterface = NSXPCInterface(with: HelperToolRequestProtocol.self)
		connection.exportedObject = HelperTool()
		connection.resume()

		return true
	}
}

func swift_main() {
	if CommandLine.arguments.count > 2 && CommandLine.arguments[1] == "-sshpass" {
		guard let _ = swift_getenv("SSHPASS") else {
			fputs("error: SSHPASS env var must be set to use -sshpass option", stderr)
			exit(1)
		}

		let sshpass_argv = Array<String>(CommandLine.arguments[2...])
		exit(sshpass_main_wrapper(sshpass_argv))
	} else {
		let delegate = XPCListenerDelegate()
		let listener = NSXPCListener(machServiceName: "me.sunsol.OpenDirectoryServer.PrivilegedHelperTool")
		listener.delegate = delegate
		listener.resume()

		RunLoop.current.run()

	}
}

swift_main()
