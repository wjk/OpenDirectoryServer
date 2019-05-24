//
//  SVRDirectoryNode.h
//  SVRUserManagement
//
//  Created by William Kent on 5/24/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

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
