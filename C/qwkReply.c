/* 
 * ------------------------------------------------------------------
 * qwkReply.c - Inject into reply spool
 * Created by Robert Heller on Sun Nov 12 10:48:19 1995
 * ------------------------------------------------------------------
 * Modification History:
 * ------------------------------------------------------------------
 * Contents:
 * ------------------------------------------------------------------
 *  
 * 
 * Copyright (c) 1994 by Robert heller
 *        All Rights Reserved
 * 
 */

/******************************************************************
 *                                                                *
 * This program is mostly plagerized from parts of the ATP package*
 * which is a CLI Unix/POSIX/OSK QWK off-line reader. This code   *
 * creates a reply conference message that can be later bundled   *
 * into a reply packet for uploading to a QWK BBS.                *
 *                                                                *
 ******************************************************************/

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <time.h>

#include "qwk.h"

/* Main program. Takes 4 command line arguments:
 *  		 1) message security flag: public or private
 *		 2) spool directory
 *		 3) active file
 *		 4) group name
 *		 The message itself is piped in on stdin.
 *
 * This program creates a new message file in the reply conference with the
 * three 'magic' header lines needed by SpoolToReply. The active file is updated
 * with a new count of reply messages.
 */

int main(int argc,char *argv[])
{
	char *security, *spool, *active, *group, *l;
	static char replyFile[256];
	static char newActiveFile[256], backupActiveFile[256], buffer[4096];
	int number = 0;
	int bytes;
	FILE *infile, *outfile;
	time_t now;
	struct tm *timeBuff;

	/* Fetch CLI arguments */
	if (argc != 5)
	{
		fprintf(stderr,"usage: qwkReply public/private spool active group\n");
		exit(1);
	}
	security = argv[1];
	spool = argv[2];
	active = argv[3];
	group = argv[4];
	/* Read and update active file */
	sprintf(newActiveFile,"%s.new",active);
	infile = fopen(active,"r");
	if (infile == NULL)
	{
		int err = errno;
		perror("fopen: active");
		exit(err);
	}
	outfile = fopen(newActiveFile,"w");
	if (outfile == NULL)
	{
		int err = errno;
		perror("fopen: newactive");
		exit(err);
	}
	while ((l = fgets(buffer,256,infile)) != NULL)
	{
		char *sp = strchr(l,' ');
		*sp++ = '\0';
		if (strcmp(l,REPLY) != 0)
		{
			*--sp = ' ';
			fputs(buffer,outfile);
		} else
		{
			number = atoi(sp) + 1;
			fprintf(outfile,"%s %0.10d 00001 n\n",REPLY,number);
		}
	}
	/* Create new reply entry if needed. */
	if (number == 0)
	{
		number = 1;
		fprintf(outfile,"%s %0.10d 00001 n\n",REPLY,number);
	}
	fclose(infile);
	fclose(outfile);
	/* Backup active file */
	sprintf(backupActiveFile,"%s~",active);
	if (rename(active,backupActiveFile) < 0)
	{
		int err = errno;
		perror("rename: active=>active~");
		exit(err);
	}
	/* Install updated active file */
	if (rename(newActiveFile,active) < 0)
	{
		int err = errno;
		perror("rename: active.new=>active");
		exit(err);
	}
	/* Create reply message file name. */
	sprintf(replyFile,"%s/%s/%d",spool,REPLY,number);
	outfile = fopen(replyFile,"w");
	if (outfile == NULL)
	{
		int err = errno;
		perror("fopen: replyFile");
		exit(err);
	}
	/* Insert magic headers. */
	fprintf(outfile,"Security: %s\nGroup: %s\n",security,group);
	time(&now);
	timeBuff = localtime(&now);
	fprintf(outfile,"Date: %02d-%02d-%02d%02d:%02d\n",timeBuff->tm_mon+1,
		timeBuff->tm_mday,timeBuff->tm_year % 100,timeBuff->tm_hour,
		timeBuff->tm_min);
	/* Copy in message from stdin */
	while ((bytes = fread(buffer,sizeof(char),sizeof(buffer),stdin)) > 0)
	{
		fwrite(buffer,sizeof(char),bytes,outfile);
	}
	/* Done. */
	fclose(outfile);
	exit(0);
}

		
