//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <CoreFoundation/CoreFoundation.h>

typedef CF_ENUM(int, sshpass_return_code) {
	RETURN_NOERROR,
	RETURN_INVALID_ARGUMENTS,
	RETURN_CONFLICTING_ARGUMENTS,
	RETURN_RUNTIME_ERROR,
	RETURN_PARSE_ERRROR,
	RETURN_INCORRECT_PASSWORD,
	RETURN_HOST_KEY_UNKNOWN,
	RETURN_HOST_KEY_CHANGED,
};
