//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import Foundation;

extern int sshpass_main_wrapper(NSArray<NSString *> *argv);
NSString *swift_getenv(NSString *key);
