/* 
 * ------------------------------------------------------------------
 * SpoolToReply.c - Convert Spooled replies into a QWK .msg file
 * Created by Robert Heller on Tue Nov 14 18:32:35 1995
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
 * collects messages in the 'reply' group (conference) and bundles*
 * them into a .msg file for uploading to a QWK BBS for insertion *
 * into the BBS's message base.                                   *
 *                                                                *
 ******************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include "qwk.h"

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

/* Active table */

Active *activeTable = NULL;
int numActive = 0,maxActive = 0;

/* Read in active table */
void ReadActive(const char *activeFile)
{
	FILE *activeIn;
	static char lineBuffer[256];
	char *lp, *p;
	char *n, *f;
	int ilast, ifirst;
	int i;
	numActive = 0;
	if ((activeIn = fopen(activeFile,"r")) == NULL) return;
	maxActive = 0;
	while (fgets(lineBuffer,256,activeIn) != NULL) maxActive++;
	rewind(activeIn);
	activeTable = (Active *) malloc(sizeof(Active)*maxActive);
	if (activeTable == NULL)
	{
		int err = errno;
		perror("malloc: Active");
		exit(err);
	}
	while ((lp = fgets(lineBuffer,256,activeIn)) != NULL)
	{
		n = lp;
		p = strchr(lp,' ');
		if (p == NULL) continue;
		*p++ = '\0';
		ilast = atoi(p);
		p = strchr(p,' ');
		if (p == NULL) continue;
		*p++ = '\0';
		ifirst = atoi(p);
		f = strchr(p,' ');
		if (f == NULL) continue;
		f++;
		p = strchr(p,'\n');
		if (p == NULL) continue;
		*p = '\0';
		if (*f == '=')
		{
			f++;
			for (i = 0; i < numActive; i++)
			{
				if (strcmp(activeTable[i].name,f) == 0)
				{
					activeTable[i].confNumber = atoi(n);
					break;
				}
			}
			if (i == numActive)
			{
				numActive++;
				activeTable[i].confNumber = atoi(n);
				strcpy(activeTable[i].name,f);
				activeTable[i].last = 0;
				activeTable[i].first = 1;
				activeTable[i].newsrcFlag = FALSE;
			}
		} else
		{
			for (i = 0; i < numActive; i++)
			{
				if (strcmp(activeTable[i].name,n) == 0)
				{
					activeTable[i].last = ilast;
					activeTable[i].first = ifirst;
					break;
				}
			}
			if (i == numActive)
			{
				numActive++;
				strcpy(activeTable[i].name,f);
				activeTable[i].last = ilast;
				activeTable[i].first = ifirst;
				activeTable[i].newsrcFlag = FALSE;
			}
		}
	}
	fclose(activeIn);
}

/* Copy a string, but unlike strcpy, don't copy the NUL byte. */
inline void str2mem(char *d,char *s)
{
	while (*s != '\0') *d++ = *s++;
}

/* Reset the header structure to a 'vanila' state. */
void 
ResetHeader(struct QmailRepType * Qmail)
{

	byte            word16[2];	/* space for 16 bit unsigned word */
	char            qbuf[30];	/* temporary buffer */

	/* fill struct with spaces / struct remplie d'espaces    */

	memset(&Qmail->Status, 0x20, sizeof(struct QmailRepType));

	Qmail->Status = 0x20;	/* Public Message Unread */

	Qmail->MsgActive = 0xE1;/* 0xE1 = active  0xE2 = non active  */
	Qmail->Unused1 = 0x20;	/* space                             */
	Qmail->Unused2 = 0x20;	/* space                             */
	Qmail->NetTag = 0x20;	/* space                             */
}

/* Process the replies */
void ProcessReplies(const char *msgfile,const char *spoolDirectory,const char *spoolName,const char *author)
{
	FILE *messageIn, *MSGOut;
	struct QmailRepType OutHeader;
	static char buffer[128], filename[256], sentname[256];
	char *p,*q,*colon;
	int iconference,numBlocks;
	long int numBytes;
	Active *current = NULL, *replyConf = NULL;
	int messageNumber;
	int iconf,i,ib,ic;
	long int topOfFile,bottomOfFile;
	byte word16[2];	/* space for 16 bit unsigned word */
	int RealConfN;
	static char qbuf[30];
	int NumPacked = 0;

	/* Find reply conference active information */
	for (i = 0; i < numActive; i++)
	{
		if (strcmp(activeTable[i].name,REPLY) == 0)
		{
			replyConf = &activeTable[i];
			break;
		}
	}
	/* Reply conference missing??? */
	if (replyConf == NULL)
	{
		fprintf(stderr,"SpoolToReply: No Reply Conference!\n");
		exit(1);
	}
	/* Create message file */
	MSGOut = fopen(msgfile,"wb");
	if (MSGOut == NULL)
	{
		int err = errno;
		perror("fopen: msgfile");
		exit(err);
	}
	/* Initialize message file header */
	memset(buffer,0x20, sizeof(buffer));
	for (p=(char*)spoolName,q=buffer;*p != '\0';p++,q++)
	{
		*q = toupper(*p);
	}
	if (fwrite(buffer,sizeof(buffer),1,MSGOut) != 1)
	{
		int err = errno;
		perror("fwrite: 1st header");
		exit(err);
	}
	/* For every new reply message... */
	for (messageNumber = replyConf->first; messageNumber <= replyConf->last;messageNumber++)
	{
		/* Form reply message file name */
		sprintf(filename,"%s/%s/%d",spoolDirectory,REPLY,messageNumber);
		/* If file missing, skip it. */
		if (access(filename,R_OK) != 0) continue;
		/* Open reply message file, skip if open fails */
		messageIn = fopen(filename,"r");
		if (messageIn == NULL) continue;
		/* Initialize reply header */
		ResetHeader(&OutHeader);
		current = NULL;
		/* Read in three 'magic' header lines: Security, Group, and
		   Date. Transfer this info to the QWK reply header. */
		for (i = 0;i < 3;i++)
		{
			if (fgets(buffer,128,messageIn) == NULL)
			{
				fclose(messageIn);
				break;
			}
			if (strncmp(buffer,"Security: ",10) == 0)
			{
				/* Public or private? */
				if (strcmp(buffer+10,"public\n") == 0) OutHeader.Status = (char) 0x20 ;
				else if (strcmp(buffer+10,"private\n") == 0) OutHeader.Status = (char) 0x2A ;
				else
				{
					fclose(messageIn);
					break;
				}
			} else if (strncmp(buffer,"Group: ",7) == 0)
			{
				/* Group name? */
				p = buffer+7;
				q = strchr(p,'\n');
				if (q != NULL) *q = '\0';
				for (iconf = 0;iconf < numActive;iconf++)
				{
					if (strcmp(activeTable[iconf].name,p) == 0)
					{
						current = &activeTable[iconf];
						break;
					}
				}
				if (current == NULL)
				{
					fclose(messageIn);
					break;
				}
				RealConfN = current->confNumber;
				sprintf(qbuf, "%-7d", RealConfN);
				str2mem((char *) (OutHeader.ConfNum), qbuf);
				word16[0] = (byte) (RealConfN & 0x00ff);
				word16[1] = (byte) ((RealConfN & 0xff00) >> 8);
				memcpy( (void *) &(OutHeader.BinConfN), (void *) word16, 2);
			} else if (strncmp(buffer,"Date: ",6) == 0)
			{
				/* QWK date */
				p = buffer+6;
				q = strchr(p,'\n');
				if (q != NULL) *q = '\0';
				str2mem((char *) (OutHeader.MsgDate), p);
			} else
			{
				fclose(messageIn);
				current = NULL;
				break;
			}
		}
		/* If QWK header lines are missing, skip message */
		if (current == NULL) continue;
		/* Initialize other header fields.
		str2mem((char *) (OutHeader.ForWhom),(char*) "ALL");
		str2mem((char *) (OutHeader.Author), (char*) author);
		/* Remember start of message proper */
		topOfFile = ftell(messageIn);
		/* Fill in rest of header from standard RFC822 headers */
		while (1)
		{
			if (fgets(buffer,128,messageIn) == NULL) break;
			if (strcmp(buffer,"\n") == 0) break; /* End of header */
			if (strncasecmp(buffer,"Subject: ",9) == 0)
			{
				strncpy(qbuf,buffer+9,25);
				qbuf[24] = '\0';
				str2mem((char *) (OutHeader.Subject), qbuf);
			} else if (strncasecmp(buffer,"From: ",6) == 0)
			{
				strncpy(qbuf,buffer+6,25);
				qbuf[24] = '\0';
				str2mem((char *) (OutHeader.Author), qbuf);
			} else if (strncasecmp(buffer,"To: ",4) == 0)
			{
				strncpy(qbuf,buffer+4,25);
				qbuf[24] = '\0';
				str2mem((char *) (OutHeader.ForWhom), qbuf);
			} else if (strncasecmp(buffer,"X-Comment-To: ",14) == 0)
			{
				strncpy(qbuf,buffer+14,25);
				qbuf[24] = '\0';
				str2mem((char *) (OutHeader.ForWhom), qbuf);
			}
		}
		/* Compute message size */
		fseek(messageIn,0L,SEEK_END);
		bottomOfFile = ftell(messageIn);
		/* Reset message file position */
		fseek(messageIn,topOfFile,SEEK_SET);
		/* Compute message size and stash block count in header */
		numBytes = bottomOfFile - topOfFile;
		numBlocks = ((numBytes+127)/128) + 1;
		sprintf(qbuf,"%d",numBlocks);
		str2mem((char *) (OutHeader.SizeMsg), qbuf);
		printf("%s [%s] ",filename,current->name); fflush(stdout);
		/* Write header */
		if (fwrite((void*)&(OutHeader.Status),sizeof(OutHeader),1,MSGOut) != 1)
		{
			int err = errno;
			perror("fwrite: header");
			exit(err);
		}
		/* Copy message to reply packet */
		for (i=1;i < numBlocks;i++)
		{
			memset(buffer,' ',128);
			ib = fread(buffer,sizeof(char),128,messageIn);
			/* Replace hard LFs with magic newline */
			for (ic=0,p=buffer;ic < ib;ic++,p++)
			{
				if (*p == '\n') *p = (char) 227;
			}
			if (fwrite(buffer,sizeof(buffer),1,MSGOut) != 1)
			{
				int err = errno;
				perror("fwrite: block");
				exit(err);
			}
		}
		/* Close input message */
		fclose(messageIn);
		/* Mark message as 'sent' by renaming it */
		sprintf(sentname,"%s/%s/%d.sent",spoolDirectory,REPLY,messageNumber);
		if (rename(filename,sentname) != 0)
		{
			int err = errno;
			perror("rename: filename => sentname");
		}
		/* Update count */
		NumPacked++;
		printf(" => packed for area %d, message # %d\n",
			RealConfN,NumPacked);
	}
	printf("\nNumPacked:%d\n",NumPacked);
	fclose(MSGOut);
}
				
			
/* Main program.  Gather CLI arguments and call helper functions. */
/* active spoolD spoolName fromuser msg */

int main(int argc,char *argv[])
{
	char *active,*spoolD, *spoolName, *fromuser, *msg;

	if (argc != 6)
	{
		fprintf(stderr,"usage: SpoolToReply active spoolD spoolName fromuser msg\n");
		exit(1);
	}
	active = argv[1];
	spoolD = argv[2];
	spoolName = argv[3];
	fromuser = argv[4];
	msg = argv[5];
	ReadActive(active);
	ProcessReplies(msg,spoolD,spoolName,fromuser);
	exit(0);
}
	
