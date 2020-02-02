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

#define ASSERT_NOT_DELETED() NSAssert(!deleted, @"Record was already deleted")

@implementation SVRUserRecord
{
	ODRecord *record;
	BOOL deleted;
}

- (instancetype)initWithRecord:(ODRecord *)record {
	self = [super init];
	self->record = record;
	self->deleted = NO;
	return self;
}

+ (BOOL)deleteRecord:(SVRUserRecord *)record error:(NSError **)outError; {
	BOOL result = [[record nativeRecord] deleteRecordAndReturnError:outError];
	if (result) record->deleted = YES;
	return result;
}

- (ODRecord *)nativeRecord {
	return record;
}

#pragma mark Attributes

- (nullable NSArray<NSString *> *)stringValuesForAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
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

- (nullable NSArray<NSData *> *)binaryValuesForAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
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

- (BOOL)setStringValues:(NSArray<NSString *> *)values forAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
	return [record setValue:values forAttribute:attributeName error:outError];
}

- (BOOL)setBinaryValues:(NSArray<NSData *> *)values forAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError; {
	ASSERT_NOT_DELETED();
	return [record setValue:values forAttribute:attributeName error:outError];
}

- (BOOL)appendStringValue:(NSString *)value toAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
	return [record addValue:value toAttribute:attributeName error:outError];
}

- (BOOL)appendBinaryValue:(NSData *)value toAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
	return [record addValue:value toAttribute:attributeName error:outError];
}

- (BOOL)removeStringValue:(NSString *)value fromAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
	return [record removeValue:value fromAttribute:attributeName error:outError];
}

- (BOOL)removeBinaryValue:(NSData *)value fromAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError {
	ASSERT_NOT_DELETED();
	return [record removeValue:value fromAttribute:attributeName error:outError];
}

#pragma mark Changing Password

- (BOOL)changePassword:(NSString *)oldPassword toPassword:(NSString *)newPassword error:(NSError *__autoreleasing  _Nullable *)outError {
	ASSERT_NOT_DELETED();
	return [record changePassword:oldPassword toPassword:newPassword error:outError];
}

- (BOOL)resetPassword:(NSString *)newPassword error:(NSError *__autoreleasing  _Nullable *)outError {
	ASSERT_NOT_DELETED();
	return [record changePassword:nil toPassword:newPassword error:outError];
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object {
	ASSERT_NOT_DELETED();

	if (![object isKindOfClass:[SVRUserRecord class]]) return NO;
	SVRUserRecord *other = object;
	return [other->record isEqual:record];
}

- (NSUInteger)hash {
	ASSERT_NOT_DELETED();
	return [record hash];
}

@end
