//
// This file is based on SwiftPrivilegedHelper.
// Copyright (c) 2018 Erik Berglund
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import Security
import AuthorizationAPI

internal enum Rights {
	private static let adminRule: AuthorizationRight.RuleDefinition = .custom(definition: AuthorizationRight.authenticateAsAdminRule) // shorthand
	internal static let createMasterServer = AuthorizationRight(name: "me.sunsol.OpenDirectoryServer.createMaster", description: "Open Directory Server is trying to create a master server.", ruleDefinition: adminRule)
	internal static let createReplicaServer = AuthorizationRight(name: "me.sunsol.OpenDirectoryServer.createReplica", description: "Open Directory Server is trying to create a replica server.", ruleDefinition: adminRule)
	internal static let createBackup = AuthorizationRight(name: "me.sunsol.OpenDirectoryServer.createBackup", description: "Open Directory Server is trying to create a backup of the local server's directory database.", ruleDefinition: adminRule)
	internal static let restoreBackup = AuthorizationRight(name: "me.sunsol.OpenDirectoryServer.restoreBackup", description: "Open Directory Server is trying to restore a backup of the local server's directory database.", ruleDefinition: adminRule)
}
