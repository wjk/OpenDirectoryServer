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

@end
