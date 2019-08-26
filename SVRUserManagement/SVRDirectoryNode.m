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

@interface SVRUserRecord ()
- (instancetype)initWithRecord:(ODRecord *)record owningNode:(SVRDirectoryNode *)owningNode;
@end

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

- (BOOL)authenticate {
	return [node setCredentialsWithRecordType:kODRecordTypeUsers recordName:self.userName password:self.password error:NULL];
}

- (nullable NSArray<SVRUserRecord *> *)queryAllUserRecordsWithError:(NSError **)outError {
	NSError *error;
	ODQuery *query = [ODQuery queryWithNode:node forRecordTypes:kODRecordTypeUsers attribute:kODAttributeTypeAllAttributes matchType:kODMatchAny queryValues:nil returnAttributes:kODAttributeTypeAllAttributes maximumResults:NSIntegerMax error:&error];
	if (query == nil) {
		if (outError != NULL) *outError = error;
		return nil;
	}

	NSArray *results = [query resultsAllowingPartial:NO error:&error];
	if (results == nil) {
		if (outError != NULL) *outError = error;
		return nil;
	}

	NSMutableArray<SVRUserRecord *> *retval = [[NSMutableArray alloc] init];
	for (ODRecord *record in results) {
		NSAssert([[record recordType] isEqualToString:kODRecordTypeUsers], @"ODRecord not of user type");
		[retval addObject:[[SVRUserRecord alloc] initWithRecord:record owningNode:self]];
	}
	return retval;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[SVRDirectoryNode class]]) return NO;
	SVRDirectoryNode *other = object;
	return [node isEqual:other->node];
}

- (NSUInteger)hash {
	return [node hash];
}

@end
