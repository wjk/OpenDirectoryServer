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
	const char **native_argv = calloc(argc + 1, sizeof(char *));

	native_argv[0] = getprogname();
	for (int i = 0; i < argc; i++) {
		native_argv[i + 1] = [argv[i] UTF8String];
	}

	return sshpass_main(argc, native_argv);
}
