//
//  SVRUserRecord+Attributes.swift
//  SVRUserManagement
//
//  Created by William Kent on 8/26/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

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
