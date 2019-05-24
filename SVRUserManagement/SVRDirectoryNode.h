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

@interface SVRDirectoryNode : NSObject

+ (nullable NSArray<SVRDirectoryNode *> *)allNodesBoundToLocalComputerWithError:(NSError **)outError;
- (nullable instancetype)initWithName:(NSString *)nodeName error:(NSError **)outError;

@property (readonly) NSString *nodeName;

#pragma mark Authentication

@property (nullable, copy) NSString *userName;
@property (nullable, copy) NSString *password;

- (BOOL)saveCredentialsWithError:(NSError **)outError;
- (BOOL)loadSavedCredentials;
- (BOOL)authenticate;

@end

NS_ASSUME_NONNULL_END
