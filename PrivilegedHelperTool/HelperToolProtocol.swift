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

internal enum HelperToolRequetParameters {
	internal static let certificateName = "SVRCertificateAuthName"
	internal static let certificateOrganizationName = "SVRCertificateOrganizationName"
	internal static let certificateAdminEmail = "SVRCertificateAdminEmail"
	internal static let adminUserName = "SVRDirectoryAdministratorUserName"
	internal static let adminFullName = "SVRDirectoryAdministratorRealName"
	internal static let adminPassword = "SVRDirectoryAdministratorPassword"
	internal static let adminUid = "SVRDirectoryAdministratorUserID"
	internal static let domainName = "SVRDomain"
	internal static let masterAddress = "SVRMasterAddress"
}

@objc internal protocol HelperToolRequestProtocol: NSObjectProtocol {
	func getProtocolVersion(reply: @escaping (String) -> Void)

	// Required parameters: adminUserName, adminFullName, adminUid, domainName
	// Optional parameters: certificateName, certificateOrganizationName, certificateAdminEmail
	func createOpenDirectoryMaster(parameters: [String: String], reply: @escaping (NSNumber?, NSError?) -> Void)

	// Required parameters: masterAddress, adminUserName
	// Optional parameters: certificateAdminEmail
	func createOpenDirectoryReplica(parameterrs: [String: String], reply: @escaping (NSNumber? , NSError?) -> Void)

	func createOpenDirectoryBackup(backupLocation: URL, reply: @escaping (NSNumber?, NSError?) -> Void)
	func restoreOpenDirectoryBackup(backupLocation: URL, reply: @escaping (NSNumber?, NSError?) -> Void)
}

@objc internal protocol HelperToolResponseProtocol: NSObjectProtocol {
	func standardOutputWritten(text: String)
	func standardErrorWritten(text: String)
}

internal let HelperToolVersion = "1.0"

internal enum HelperToolErrors {
	internal static let domain = "me.sunsol.OpenDirectoryServer.PrivilegedToolErrorDomain"

	internal static let authorizationDenied = 1
	internal static let authorizationCancelled = 2
	internal static let invalidParameter = 3
}
