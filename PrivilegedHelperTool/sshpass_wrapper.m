//
//  sshpass_wrapper.m
//  PrivilegedHelperTool
//
//  Created by William Kent on 5/24/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

#import "BridgingHeader.h"

extern int sshpass_main( int argc, const char *argv[] );

int sshpass_main_wrapper(NSArray<NSString *> *argv) {
	int argc = (int)argv.count;
	const char **native_argv = calloc(argc + 2, sizeof(char *));

	native_argv[0] = "sshpass";
	native_argv[1] = "-e";
	for (int i = 0; i < argc; i++) {
		native_argv[i + 2] = [argv[i] UTF8String];
	}

	return sshpass_main(argc + 2, native_argv);
}

NSString *swift_getenv(NSString *key) {
	char *value = getenv([key UTF8String]);
	if (value != NULL) return [NSString stringWithUTF8String:value];
	else return nil;
}
