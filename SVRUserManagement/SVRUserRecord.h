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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NSString * SVRUserAttribute NS_TYPED_EXTENSIBLE_ENUM;

@interface SVRUserRecord : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)deleteRecord:(SVRUserRecord *)record error:(NSError **)outError;

#pragma mark Attributes

- (nullable NSArray<NSString *> *)stringValuesForAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (nullable NSArray<NSData *> *)binaryValuesForAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)setStringValues:(NSArray<NSString *> *)values forAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)setBinaryValues:(NSArray<NSData *> *)values forAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)appendStringValue:(NSString *)value toAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)appendBinaryValue:(NSData *)value toAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)removeStringValue:(NSString *)value fromAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;
- (BOOL)removeBinaryValue:(NSData *)value fromAttribute:(SVRUserAttribute)attributeName error:(NSError **)outError;

#pragma mark Changing Password

- (BOOL)changePassword:(NSString *)oldPassword toPassword:(NSString *)newPassword error:(NSError **)outError;
- (BOOL)resetPassword:(NSString *)newPassword error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
