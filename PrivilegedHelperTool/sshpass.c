// NOTE: This file is used under the GPLv3 per the "any later version" clause included below.
// The Web link 404ed, so I assume that GPLv3 is acceptable.

/*  This file is part of "sshpass", a tool for batch running password ssh authentication
 *  Copyright (C) 2006, 2015 Lingnu Open Source Consulting Ltd.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version, provided that it was accepted by
 *  Lingnu Open Source Consulting Ltd. as an acceptable license for its
 *  projects. Consult http://www.lingnu.com/licenses.html
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/ioctl.h>
#include <sys/select.h>

#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <termios.h>

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <os/log.h>
#include "BridgingHeader.h"

static struct {
	enum { PWT_STDIN, PWT_FILE, PWT_FD, PWT_PASS } pwtype;
	union {
		const char *filename;
		int fd;
		const char *password;
	} pwsrc;

	const char *pwprompt;
	int verbose;
} args;

/* Global variables so that this information be shared with the signal handler */
static int masterpt;

static int handleoutput( int fd );
static void sigchld_handler(int signum);

sshpass_return_code sshpass_runprogram( const char *password, int* exit_code, int argc, char *argv[] )
{
	os_log_t logger = os_log_create("me.sunsol.OpenDirectoryServer", "sshpass");
	args.pwsrc.password = password;

	// We need to interrupt a select with a SIGCHLD. In order to do so, we need a SIGCHLD handler
	signal( SIGCHLD,sigchld_handler );

	// Create a pseudo terminal for our process
	masterpt=posix_openpt(O_RDWR);

	if( masterpt==-1 ) {
		os_log(logger, "Failed to get a pseudo terminal");
		return RETURN_RUNTIME_ERROR;
	}

	fcntl(masterpt, F_SETFL, O_NONBLOCK);

	if( grantpt( masterpt )!=0 ) {
		os_log(logger, "Failed to change pseudo terminal's permission");
		return RETURN_RUNTIME_ERROR;
	}
	if( unlockpt( masterpt )!=0 ) {
		os_log(logger, "Failed to unlock pseudo terminal");
		return RETURN_RUNTIME_ERROR;
	}

	const char *name=ptsname(masterpt);
	int slavept;
	/*
	 Comment no. 3.14159

	 This comment documents the history of code.

	 We need to open the slavept inside the child process, after "setsid", so that it becomes the controlling
	 TTY for the process. We do not, otherwise, need the file descriptor open. The original approach was to
	 close the fd immediately after, as it is no longer needed.

	 It turns out that (at least) the Linux kernel considers a master ptty fd that has no open slave fds
	 to be unused, and causes "select" to return with "error on fd". The subsequent read would fail, causing us
	 to go into an infinite loop. This is a bug in the kernel, as the fact that a master ptty fd has no slaves
	 is not a permenant problem. As long as processes exist that have the slave end as their controlling TTYs,
	 new slave fds can be created by opening /dev/tty, which is exactly what ssh is, in fact, doing.

	 Our attempt at solving this problem, then, was to have the child process not close its end of the slave
	 ptty fd. We do, essentially, leak this fd, but this was a small price to pay. This worked great up until
	 openssh version 5.6.

	 Openssh version 5.6 looks at all of its open file descriptors, and closes any that it does not know what
	 they are for. While entirely within its prerogative, this breaks our fix, causing sshpass to either
	 hang, or do the infinite loop again.

	 Our solution is to keep the slave end open in both parent AND child, at least until the handshake is
	 complete, at which point we no longer need to monitor the TTY anyways.
	 */

	int childpid=fork();
	if( childpid==0 ) {
		// Child

		// Detach us from the current TTY
		setsid();
		// This line makes the ptty our controlling tty. We do not otherwise need it open
		slavept=open(name, O_RDWR );
		close( slavept );

		close( masterpt );

		char **new_argv=malloc(sizeof(char *)*(argc+1));

		int i;

		for( i=0; i<argc; ++i ) {
			new_argv[i]=argv[i];
		}

		new_argv[i]=NULL;

		execvp( new_argv[0], new_argv );

		// Don't os_log() here, as we have forked.
		perror("sshpass: Failed to run command");
		exit(RETURN_RUNTIME_ERROR);
	} else if( childpid<0 ) {
		os_log(logger, "sshpass: Failed to create child process");
		return RETURN_RUNTIME_ERROR;
	}
	
	// We are the parent
	slavept=open(name, O_RDWR|O_NOCTTY );

	int status=0;
	int terminate=0;
	pid_t wait_id;
	sigset_t sigmask, sigmask_select;

	// Set the signal mask during the select
	sigemptyset(&sigmask_select);

	// And during the regular run
	sigemptyset(&sigmask);
	sigaddset(&sigmask, SIGCHLD);

	sigprocmask( SIG_SETMASK, &sigmask, NULL );

	do {
		if( !terminate ) {
			fd_set readfd;

			FD_ZERO(&readfd);
			FD_SET(masterpt, &readfd);

			int selret=pselect( masterpt+1, &readfd, NULL, NULL, NULL, &sigmask_select );

			if( selret>0 ) {
				if( FD_ISSET( masterpt, &readfd ) ) {
					int ret;
					if( (ret=handleoutput( masterpt )) ) {
						// Authentication failed or any other error

						// handleoutput returns positive error number in case of some error, and a negative value
						// if all that happened is that the slave end of the pt is closed.
						if( ret>0 ) {
							close( masterpt ); // Signal ssh that it's controlling TTY is now closed
							close(slavept);
						}

						terminate=ret;

						if( terminate ) {
							close( slavept );
						}
					}
				}
			}
			wait_id=waitpid( childpid, &status, WNOHANG );
		} else {
			wait_id=waitpid( childpid, &status, 0 );
		}
	} while( wait_id==0 || (!WIFEXITED( status ) && !WIFSIGNALED( status )) );

	if( terminate>0 )
		return terminate;
	else if( WIFEXITED( status ) ) {
		if (exit_code != NULL) *exit_code = WEXITSTATUS(status);
		return RETURN_NOERROR;
	} else
		return RETURN_RUNTIME_ERROR;
}

static int match( const char *reference, const char *buffer, ssize_t bufsize, int state );
static void write_pass( int fd );

int handleoutput( int fd )
{
	// We are looking for the string
	static int prevmatch=0; // If the "password" prompt is repeated, we have the wrong password.
	static int state1, state2;
	static int firsttime = 1;
	static const char *compare1="assword"; // Asking for a password
	static const char compare2[]="The authenticity of host "; // Asks to authenticate host
	// static const char compare3[]="WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"; // Warns about man in the middle attack
	// The remote identification changed error is sent to stderr, not the tty, so we do not handle it.
	// This is not a problem, as ssh exists immediately in such a case
	char buffer[256];
	int ret=0;

	if( args.pwprompt ) {
		compare1 = args.pwprompt;
	}

	if( args.verbose && firsttime ) {
		firsttime=0;
		fprintf(stderr, "SSHPASS searching for password prompt using match \"%s\"\n", compare1);
	}

	ssize_t numread=read(fd, buffer, sizeof(buffer)-1 );
	buffer[numread] = '\0';
	if( args.verbose ) {
		fprintf(stderr, "SSHPASS read: %s\n", buffer);
	}

	state1=match( compare1, buffer, numread, state1 );

	// Are we at a password prompt?
	if( compare1[state1]=='\0' ) {
		if( !prevmatch ) {
			if( args.verbose )
				fprintf(stderr, "SSHPASS detected prompt. Sending password.\n");
			write_pass( fd );
			state1=0;
			prevmatch=1;
		} else {
			// Wrong password - terminate with proper error code
			if( args.verbose )
				fprintf(stderr, "SSHPASS detected prompt, again. Wrong password. Terminating.\n");
			ret=RETURN_INCORRECT_PASSWORD;
		}
	}

	if( ret==0 ) {
		state2=match( compare2, buffer, numread, state2 );

		// Are we being prompted to authenticate the host?
		if( compare2[state2]=='\0' ) {
			if( args.verbose )
				fprintf(stderr, "SSHPASS detected host authentication prompt. Exiting.\n");
			ret=RETURN_HOST_KEY_UNKNOWN;
		}
	}

	return ret;
}

int match( const char *reference, const char *buffer, ssize_t bufsize, int state )
{
	// This is a highly simplisic implementation. It's good enough for matching "Password: ", though.
	int i;
	for( i=0;reference[state]!='\0' && i<bufsize; ++i ) {
		if( reference[state]==buffer[i] )
			state++;
		else {
			state=0;
			if( reference[state]==buffer[i] )
				state++;
		}
	}

	return state;
}

void write_pass_fd( int srcfd, int dstfd );

void write_pass( int fd )
{
	switch( args.pwtype ) {
		case PWT_STDIN:
			write_pass_fd( STDIN_FILENO, fd );
			break;
		case PWT_FD:
			write_pass_fd( args.pwsrc.fd, fd );
			break;
		case PWT_FILE:
		{
			int srcfd=open( args.pwsrc.filename, O_RDONLY );
			if( srcfd!=-1 ) {
				write_pass_fd( srcfd, fd );
				close( srcfd );
			}
		}
			break;
		case PWT_PASS:
			write( fd, args.pwsrc.password, strlen( args.pwsrc.password ) );
			write( fd, "\n", 1 );
			break;
	}
}

void write_pass_fd( int srcfd, int dstfd )
{

	int done=0;

	while( !done ) {
		char buffer[40];
		int i;
		ssize_t numread=read( srcfd, buffer, sizeof(buffer) );
		done=(numread<1);
		for( i=0; i<numread && !done; ++i ) {
			if( buffer[i]!='\n' )
				write( dstfd, buffer+i, 1 );
			else
				done=1;
		}
	}

	write( dstfd, "\n", 1 );
}

// Do nothing handler - makes sure the select will terminate if the signal arrives, though.
void sigchld_handler(int signum)
{
}
