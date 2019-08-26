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
