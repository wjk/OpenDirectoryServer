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
import OpenDirectory.CFOpenDirectory

public extension SVRUserAttribute {
	static let isHidden = SVRUserAttribute(rawValue: "dsAttrTypeNative:IsHidden")
	static let passwordHint = SVRUserAttribute(rawValue: kODAttributeTypeAuthenticationHint)
	static let shortName = SVRUserAttribute(rawValue: kODAttributeTypeRecordName)
	static let fullName = SVRUserAttribute(rawValue: kODAttributeTypeFullName)
	static let comment = SVRUserAttribute(rawValue: kODAttributeTypeComment)
	static let homeDirectoryLocation = SVRUserAttribute(rawValue: kODAttributeTypeNFSHomeDirectory)
	static let userPictureLocation = SVRUserAttribute(rawValue: kODAttributeTypePicture)
	static let userId = SVRUserAttribute(rawValue: kODAttributeTypeUniqueID)
	static let authenticationAuthority = SVRUserAttribute(rawValue: kODAttributeTypeAuthenticationAuthority)
	static let userPictureJPEGData = SVRUserAttribute(rawValue: kODAttributeTypeJPEGPhoto)
	static let primaryGroupId = SVRUserAttribute(rawValue: kODAttributeTypePrimaryGroupID)
	static let generatedUID = SVRUserAttribute(rawValue: kODAttributeTypeGUID)
	static let userShell = SVRUserAttribute(rawValue: kODAttributeTypeUserShell)
}
