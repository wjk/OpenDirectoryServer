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

#import "SVRUserRecord.h"
#import "SVRDirectoryNode.h"
@import OpenDirectory;

@implementation SVRUserRecord
{
	ODRecord *record;
	SVRDirectoryNode *owningNode;
}

- (instancetype)initWithRecord:(ODRecord *)record owningNode:(SVRDirectoryNode *)owningNode {
	self = [super init];
	self->record = record;
	self->owningNode = owningNode;
	return self;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[SVRUserRecord class]]) return NO;
	SVRUserRecord *other = object;
	return [other->record isEqual:record] && [other->owningNode isEqual:owningNode];
}

- (NSUInteger)hash {
	return [record hash] ^ [owningNode hash];
}

@end
