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

#import "SVRDirectoryNode.h"
@import OpenDirectory;
@import Security;

@implementation SVRDirectoryNode
{
	ODNode *node;
}

+ (NSArray<SVRDirectoryNode *> *)allNodesBoundToLocalComputerWithError:(NSError * _Nullable __autoreleasing *)outError {
	ODSession *session = [ODSession defaultSession];
	NSArray *nodeNames = [session nodeNamesAndReturnError:outError];
	if (nodeNames == nil) return nil;

	NSMutableArray<SVRDirectoryNode *> *nodes = [NSMutableArray array];
	for (NSString *nodeName in nodeNames) {
		NSError *nodeError;
		ODNode *node = [ODNode nodeWithSession:session name:nodeName error:&nodeError];
		if (node == nil) {
			NSLog(@"Could not retrieve node %@: %@", nodeName, nodeError);
			continue;
		}

		if ([node.nodeName isEqualToString:@"/Contacts"] || [node.nodeName isEqualToString:@"/Search"]) {
			// These are pesudo-nodes that should not be enumerated by this method.
			continue;
		}

		[nodes addObject:[[SVRDirectoryNode alloc] initWithODNode:node]];
	}

	return nodes;
}

- (nullable instancetype)initWithName:(NSString *)nodeName error:(NSError **)outError {
	ODNode *node = [ODNode nodeWithSession:[ODSession defaultSession] name:nodeName error:outError];
	if (node == nil) return nil;
	return [self initWithODNode:node];
}

- (instancetype)initWithODNode:(ODNode *)node {
	self = [super init];
	self->node = node;
	return self;
}

- (NSString *)nodeName {
	NSString *nodeName = node.nodeName;
	NSAssert(nodeName != nil, @"Node has no name?");
	return nodeName;
}

#pragma mark Authentication

- (BOOL)saveCredentialsWithError:(NSError * _Nullable __autoreleasing *)outError {
	SecKeychainRef keychain;
	OSStatus error = SecKeychainCopyDefault(&keychain);
	if (error != noErr) {
		if (outError != NULL) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
		return NO;
	}

	NSString *keychainServiceName;
	NSString *nodeName = self.nodeName;
	if ([nodeName hasPrefix:@"/LDAPv3/"]) {
		NSString *serverName = [nodeName stringByReplacingOccurrencesOfString:@"/LDAPv3/" withString:@""];
		keychainServiceName = [NSString stringWithFormat:@"%@ (Open Directory Server)", serverName];
	} else if ([nodeName isEqualToString:@"/Local/Default"]) {
		keychainServiceName = @"Local Directory Server";
	} else {
		// FIXME: Come up with a better error code here.
		if (outError != NULL) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
		return NO;
	}

	SecKeychainItemRef keychainItem;
	error = SecKeychainFindGenericPassword(keychain, (UInt32)[keychainServiceName length], [keychainServiceName UTF8String], (UInt32)[self.userName length], [self.userName UTF8String], NULL, NULL, &keychainItem);
	if (error == errSecItemNotFound) {
		SecKeychainAttribute attributes[2];
		attributes[0].tag = kSecServiceItemAttr;
		attributes[0].data = (void *)[keychainServiceName UTF8String];
		attributes[0].length = (UInt32)[keychainServiceName length];
		attributes[1].tag = kSecAccountItemAttr;
		attributes[1].data = (void *)[self.userName UTF8String];
		attributes[1].length = (UInt32)[self.userName length];

		SecKeychainAttributeList attrList;
		attrList.count = 2;
		attrList.attr = attributes;

		error = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &attrList, (UInt32)[self.password length], [self.password UTF8String], keychain, NULL, &keychainItem);

		if (error != noErr) {
			if (outError != nil) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
			return NO;
		}
	} else if (error != noErr) {
		if (outError != nil) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
		return NO;
	}

	NSDictionary *query = @{ (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
							 (__bridge NSString *)kSecAttrService: keychainServiceName,
							 (__bridge NSString *)kSecAttrAccount: self.userName };
	NSDictionary *update = @{ (__bridge NSString *)kSecAttrServer: self.nodeName,
							  (__bridge NSString *)kSecAttrAccount: self.userName };
	error = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);
	if (error != noErr) {
		if (outError != nil) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
		return NO;
	}

	error = SecKeychainItemModifyAttributesAndData(keychainItem, NULL, (UInt32)[self.password length], [self.password UTF8String]);
	if (error != noErr) {
		if (outError != nil) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
		return NO;
	}

	return YES;
}

- (BOOL)loadSavedCredentials {
	NSString *keychainServiceName;
	NSString *nodeName = self.nodeName;
	if ([nodeName hasPrefix:@"/LDAPv3/"]) {
		NSString *serverName = [nodeName stringByReplacingOccurrencesOfString:@"/LDAPv3/" withString:@""];
		keychainServiceName = [NSString stringWithFormat:@"%@ (Open Directory Server)", serverName];
	} else if ([nodeName isEqualToString:@"/Local/Default"]) {
		keychainServiceName = @"Local Directory Server";
	} else {
		return NO;
	}

	SecKeychainItemRef keychainItem;
	OSStatus error = SecKeychainFindGenericPassword(NULL, (UInt32)[keychainServiceName length], [keychainServiceName UTF8String], (UInt32)[self.userName length], [self.userName UTF8String], NULL, NULL, &keychainItem);
	if (error != noErr) return NO;

	void *passwordData; UInt32 length;
	error = SecKeychainItemCopyAttributesAndData(keychainItem, NULL, NULL, NULL, &length, &passwordData);
	if (error != noErr) return NO;

	NSData *blob = [NSData dataWithBytesNoCopy:passwordData length:length freeWhenDone:NO];
	self.password = [[NSString alloc] initWithData:blob encoding:NSUTF8StringEncoding];
	error = SecKeychainItemFreeAttributesAndData(NULL, passwordData);
	if (error != noErr) {
		// Don't leave the object in an inconsistent state.
		self.userName = self.password = nil;
		return NO;
	}

	NSDictionary *query = @{ (__bridge NSString *)kSecReturnAttributes: @YES,
							 (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
							 (__bridge NSString *)kSecAttrService: keychainServiceName,
							 (__bridge NSString *)kSecAttrServer: self.nodeName };

	CFDictionaryRef resultRef;
	error = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&resultRef);
	if (error != noErr) {
		self.userName = self.password = nil;
		return NO;
	}

	NSDictionary *result = (__bridge_transfer NSDictionary *)resultRef;
	self.userName = [result objectForKey:(__bridge NSString *)kSecAttrAccount];
	if (self.userName == nil) {
		self.password = nil;
		return NO;
	}

	return YES;
}

- (BOOL)authenticate {
	return [node setCredentialsWithRecordType:kODRecordTypeUsers recordName:self.userName password:self.password error:NULL];
}

@end
