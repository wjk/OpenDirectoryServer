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

#import "SVRGroupRecord.h"
@import OpenDirectory;

@interface SVRUserRecord ()
- (ODRecord *)nativeRecord;
@end

@implementation SVRGroupRecord
{
	ODRecord *record;
}

- (instancetype)initWithRecord:(ODRecord *)record {
	self = [super init];
	self->record = record;
	return self;
}

#pragma mark Attributes

- (nullable NSArray<NSString *> *)stringValuesForAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	NSArray *nativeValues = [record valuesForAttribute:attributeName error:outError];
	if (nativeValues == nil) return nil;

	NSMutableArray<NSString *> *retval = [[NSMutableArray alloc] init];
	for (id object in nativeValues) {
		if ([object isKindOfClass:[NSString class]]) {
			[retval addObject:(NSString *)object];
		} else if ([object isKindOfClass:[NSData class]]) {
			NSLog(@"Unexpected binary value found when querying attribute %@, ignoring", attributeName);
		} else {
			NSAssert(NO, @"Found unexpected attribute value %@", object);
		}
	}

	return retval;
}

- (nullable NSArray<NSData *> *)binaryValuesForAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	NSArray *nativeValues = [record valuesForAttribute:attributeName error:outError];
	if (nativeValues == nil) return nil;

	NSMutableArray<NSData *> *retval = [[NSMutableArray alloc] init];
	for (id object in nativeValues) {
		if ([object isKindOfClass:[NSData class]]) {
			[retval addObject:(NSData *)object];
		} else if ([object isKindOfClass:[NSString class]]) {
			NSLog(@"Unexpected string value found when querying attribute %@, ignoring", attributeName);
		} else {
			NSAssert(NO, @"Found unexpected attribute value %@", object);
		}
	}

	return retval;
}

- (BOOL)setStringValues:(NSArray<NSString *> *)values forAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	return [record setValue:values forAttribute:attributeName error:outError];
}

- (BOOL)setBinaryValues:(NSArray<NSData *> *)values forAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError; {
	return [record setValue:values forAttribute:attributeName error:outError];
}

- (BOOL)appendStringValue:(NSString *)value toAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	return [record addValue:value toAttribute:attributeName error:outError];
}

- (BOOL)appendBinaryValue:(NSData *)value toAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	return [record addValue:value toAttribute:attributeName error:outError];
}

- (BOOL)removeStringValue:(NSString *)value fromAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	return [record removeValue:value fromAttribute:attributeName error:outError];
}

- (BOOL)removeBinaryValue:(NSData *)value fromAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError {
	return [record removeValue:value fromAttribute:attributeName error:outError];
}

#pragma mark Group Membership

- (BOOL)addGroupMember:(SVRUserRecord *)member error:(NSError **)outError {
	return [record addMemberRecord:[member nativeRecord] error:outError];
}

- (BOOL)removeGroupMember:(SVRUserRecord *)member error:(NSError **)outError {
	return [record removeMemberRecord:[member nativeRecord] error:outError];
}

- (BOOL)isGroupMember:(SVRUserRecord *)member {
	return [record isMemberRecord:[member nativeRecord] error:nil];
}

@end
