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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NSString * SVRGroupAttribute NS_TYPED_EXTENSIBLE_ENUM;

@interface SVRGroupRecord : NSObject

- (instancetype)init NS_UNAVAILABLE;

#pragma mark Attributes

- (nullable NSArray<NSString *> *)stringValuesForAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (nullable NSArray<NSData *> *)binaryValuesForAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)setStringValues:(NSArray<NSString *> *)values forAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)setBinaryValues:(NSArray<NSData *> *)values forAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)appendStringValue:(NSString *)value toAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)appendBinaryValue:(NSData *)value toAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)removeStringValue:(NSString *)value fromAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;
- (BOOL)removeBinaryValue:(NSData *)value fromAttribute:(SVRGroupAttribute)attributeName error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
