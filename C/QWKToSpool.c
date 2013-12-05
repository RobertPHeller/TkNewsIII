/* 
 * ------------------------------------------------------------------
 * QWKToSpool.c - Convert QWK file to news spool
 * Created by Robert Heller on Sun Nov 12 13:11:02 1995
 * ------------------------------------------------------------------
 * Modification History:
 * ------------------------------------------------------------------
 * Contents:
 * ------------------------------------------------------------------
 *  
 * 
 * Copyright (c) 1995 by Robert heller
 *        All Rights Reserved
 * 
 */

/******************************************************************
 *                                                                *
 * This program is mostly plagerized from parts of the ATP package*
 * which is a CLI Unix/POSIX/OSK QWK off-line reader. This code   *
 * processes the control.dat and messages.dat files from the QWK  *
 * and unpacks messages into a 'tradionional style' usenet-like   *
 * news spool. It creates/updates an 'active' file and distributes*
 * messages into a newsgroup spool tree, with group names split   *
 * into a directory hierarchy that matches the newsgroup hierarchy*
 * with each message stored as a single text file with a decimal  *
 * number as the file name. The text files are in standard RCF822 *
 * format.                                                        *
 *                                                                *
 ******************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <regex.h>
#include <errno.h>
#include <sys/stat.h>
#include "qwk.h"

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

/* Username from control.dat.  Passed up to the Tcl code.*/
static char userName[50];

/* Get a CRLF terminated line. */
static char *fgetscrlf(char *buffer,int bsize,FILE *fp)
{
	char *result = buffer;
	while (bsize > 2)
	{
		/* Get one character. */
		int c = getc(fp);
		if (c < 0)	/* Error? EOF? */
		{
			/* If at BOF, return NULL. */
			if (result == buffer) return(NULL);
			/* Else terminate buffer and return buffer. */
			*buffer = '\0';
			return (result);
		} else if (c == '\r')	/* CR? */
		{
			/* Yes, get next character. */
			c = getc(fp);
			if (c == '\n')	/* LF? */
			{
				/* Yes, insert a newline, and NUL byte and
				   return. */
				*buffer++ = '\n';
				bsize--;
				if (bsize > 0) *buffer = '\0';
				return (result);
			} else if (c != '\n')
			{
				/* CR NOT followed by a LF, insert CR */
				*buffer++ = '\r';
				bsize--;
			} else if (c < 0)
			{
				/* EOF marker. Terminate buffer and return */
				*buffer = '\0';
				return (result);
			}
			/* Else just insert it and continue. */
			*buffer++ = c;
			bsize--;
		} else
		{
			/* Not a CR or LF: insert and continue. */
			*buffer++ = c;
			bsize--;
		}
	}
	return (result);
}

/* Make a conference directory, given a group name. Will make the base
 * spool directory if it does not already exist. */
void mkConfDir(const char *spoolDirectory,const char *group,char *dirbuffer)
{
	char *p,*g,*d;

	/* Make spool directory. */
	strcpy(dirbuffer,spoolDirectory);
	if (mkdir(dirbuffer,S_IREAD|S_IWRITE|S_IEXEC) < 0)
	{
		int err = errno;
		if (err != EEXIST)	/* Ignore 'directory exists' error. */
		{
			perror("mkdir");
			exit(err);
		}
	}
	/* Initialze pointers. */
	g = (char*)group;
	d = dirbuffer + strlen(dirbuffer);
	/* While group name continues... */
	while (*g != '\0')
	{
		/* Insert directory separator */
		*d++ = '/';
		/* Copy group segment (up to a dot). */
		while (*g != '.' && *g != '\0') *d++ = *g++;
		*d = '\0';
		/* Make directory at this level */
		if (mkdir(dirbuffer,S_IREAD|S_IWRITE|S_IEXEC) < 0)
		{
			int err = errno;
			/* Ignore 'directory exists' error. */
			if (err != EEXIST)
			{
				perror("mkdir");
				exit(err);
			}
		}
		/* Skip over the dot. */
		if (*g == '.') g++;
	}
}

/* Convert 13-bit little-endian conference number to an int. */
int
readCnum(const byte * ptr)
{
	unsigned char   p, q;
	unsigned int    j;

	p = *ptr;
	ptr++;
	q = *ptr;
	q = q & 0x1f;
	j = (unsigned int) q;
	j <<= 8;
	j += (unsigned int) p;

	return (j);
}

/* Conference list */
Conferences *confs = NULL;

/* Last conference index */
int lastconf = -1;

/* Read Control.dat file, create conference (group) directories */
void ReadControl(const char *controlFile, const char *spoolDirectory)
{
	FILE *ctrlIn;
	static char lineBuffer[256];
	char *lp, *p;
	int iconf, i;
	int mm,dd,year,hh,mn,sec;

	/* Open control.dat file */
	if ((ctrlIn = fopen(controlFile,"rb")) == NULL)
	{
		int err = errno;
		perror("fopen: controlFile");
		exit(err);
	}
	/* Get BBS name */
	lp = fgetscrlf(lineBuffer,256,ctrlIn);	/* board name */
	if (lp == NULL)
	{
		int err = errno;
		perror("fgetscrlf: board name");
		exit(err);
	}
	/* Skip 4 lines (junk we don't need) and fetch time stamp */
	for (i = 0;i < 5;i++)
	{
		lp = fgetscrlf(lineBuffer,256,ctrlIn);
		if (lp == NULL)
		{
			int err = errno;
			perror("fgetscrlf: skip lines");
			exit(err);
		}
	}
	/* Extract time stamp */
	sscanf(lineBuffer,"%d-%d-%d,%d:%d:%d", &mm, &dd, &year, &hh, &mn, &sec);
	/* Fetch username */
	lp = fgetscrlf(lineBuffer,256,ctrlIn);  /* user name */
	if (lp == NULL)
	{
		int err = errno;
		perror("fgetscrlf: user name");
		exit(err);
	}
	/* Clear username buffer */
	memset(userName,'\0',50);
	/* Copy username (upto 49 characters) */
	strncpy(userName,lineBuffer,50);
	/* Terminate and  trim username */
	userName[49] = '\0';
	p = strchr(userName,'\n');
	if (p != NULL) *p-- = '\0';
	else p = userName+strlen(userName)-1;
	while (*p == ' ') *p-- = '\0';
	/* Skip three lines. */
	for (i = 0;i < 3;i++)
	{
		lp = fgetscrlf(lineBuffer,256,ctrlIn);
		if (lp == NULL)
		{
			int err = errno;
			perror("fgetscrlf: skip lines 2");
			exit(err);
		}
	}
	/* Get last conference index */
	lp = fgetscrlf(lineBuffer,256,ctrlIn);  /* last conf */
	if (lp == NULL)
	{
		int err = errno;
		perror("fgetscrlf: last conf");
		exit(err);
	}
	lastconf = atoi(lp);
	/* Allocate conference array (one special conferences is added:
         * reply). lastconf is the last (zero-based) conference index, not a
	 * conference count. */
	confs = (Conferences*) malloc(sizeof(Conferences) * (lastconf+2));
	if (confs == NULL)
	{
		int err = errno;
		perror("malloc: Conferences");
		exit(err);
	}
	/* Read in confernce names and numbers and insert into conference
	 * struct vector. */
	for (i = 0; i <= lastconf;i++)
	{
		lp = fgetscrlf(lineBuffer,256,ctrlIn);
		if (lp == NULL)
		{
			int err = errno;
			perror("fgetscrlf: conf number");
			exit(err);
		}
		confs[i].number = atoi(lp);
		lp = fgetscrlf(lineBuffer,256,ctrlIn);
		if (lp == NULL)
		{
			int err = errno;
			perror("fgetscrlf: conf name");
			exit(err);
		}
		p = strchr(lp,'\n');
		if (p != NULL) *p = '\0';
		strncpy(confs[i].name,lp,64);
		confs[i].name[63] = '\0';
		confs[i].activeEntry = NULL;
	}
	fclose(ctrlIn);
	/* Add in Reply conference */
	confs[lastconf+1].number = REPLYCNUM;
	strcpy(confs[lastconf+1].name,REPLY);
	/* Convert from last index to count. */
	lastconf += 2;
	/* Make directories */
	for (i = 0; i < lastconf; i++)
	{
		mkConfDir(spoolDirectory,confs[i].name,confs[i].directory);
	}
}

/* Active table */
Active *activeTable = NULL;
int numActive = 0,maxActive = 0;

/* Check for a blank line. */
static int blankLine(const char *lp)
{
	if (lp == NULL) return 1;
	while (*lp <= ' ' && *lp != '\0' && *lp != '\n') lp++;
	if (*lp == '\n' || *lp == '\0') return 1;
	return 0;
}

/* Read in existing active file (if any) into active table. */
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
	/* Compute the maximum number of active groups: number of conferences
	 *  in control.dat PLUS number of non-blank lines in active file.
	 * (probably an over count, but harmless and *safe*). */
	maxActive = lastconf;
	if (maxActive < 0) maxActive = 0;
	while (fgets(lineBuffer,256,activeIn) != NULL &&
	       !blankLine(lineBuffer)) maxActive++;
	rewind(activeIn);
	/* Allocate table */
	activeTable = (Active *) malloc(sizeof(Active)*maxActive);
	if (activeTable == NULL)
	{
		int err = errno;
		perror("malloc: Active");
		exit(err);
	}
	/* Read in active table */
	while ((lp = fgets(lineBuffer,256,activeIn)) != NULL)
	{
		if (blankLine(lp)) continue;
		while (*lp <= ' ' && *lp != '\0' && *lp != '\n') lp++;
		if (*lp == '\n' || *lp == '\0') continue;
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

/* Read in control and active files, and merge control file info into the
 * active table. */

void BuildActiveAndConfs(const char *controlFile, const char *spoolDirectory,const char *activeFile)
{
	int ic,ia;

	ReadControl(controlFile,spoolDirectory);
	ReadActive(activeFile);
	if (maxActive == 0)
	{
		maxActive = lastconf;
		activeTable = (Active *) malloc(sizeof(Active)*maxActive);
 		if (activeTable == NULL)
		{
			int err = errno;
			perror("malloc: Active");
			exit(err);
		}
	}
	for (ic = 0; ic < lastconf; ic++)
	{
		for (ia = 0;ia < numActive; ia++)
		{
			if (strcmp(activeTable[ia].name,confs[ic].name) == 0)
			{
				confs[ic].activeEntry = &activeTable[ia];
				activeTable[ia].confNumber = confs[ic].number;
				break;
			}
		}
		if (ia == numActive)
		{
			numActive++;
			strcpy(activeTable[ia].name,confs[ic].name);
			activeTable[ia].last = 0;
			activeTable[ia].first = 1;
			confs[ic].activeEntry = &activeTable[ia];
			activeTable[ia].confNumber = confs[ic].number;
			activeTable[ia].newsrcFlag = FALSE;
		}
	}
}

/* Return size of message file. */
long SizeOfFile(const char *messageDatFile)
{
	FILE *tmp;
	long EOFPos;

	if ((tmp = fopen(messageDatFile,"rb")) == NULL) return 0L;
	if (fseek(tmp,0L,SEEK_END) < 0) {
		fclose(tmp);
		return 0L;
	}
	EOFPos = ftell(tmp);
	fclose(tmp);
	return EOFPos;
}

/******************************************************************
 *                                                                *
 * Kill file processing.  Load kill patterns into a vector to be  *
 * used later to match from or subject lines.                     *
 *                                                                *
 ******************************************************************/

/* Kill pattern vector elements */
typedef struct {
	enum {FROM,SUBJECT} field;
	char *patternBuffer;
	regex_t pattern;
} KillPattern;

#define KILLPATTERNALLOCSIZE 100

/* Read in kill file, into a Kill pattern vector. */

int ReadKillFile(const char *killfile,KillPattern **patterns)
{
	static regex_t commentPattern, linePattern;
	static regmatch_t matched[3];
	int patternCount = 0, patternAlloc = 0;
	char *pattern,*q,*p;
	int status;
	static char errbuffer[512];
	FILE *kfp;
	static char oline[2048],line[2048];

	/* Comment pattern */
	status = regcomp(&commentPattern,"(^|[^\\])#.*$",REG_NEWLINE|REG_EXTENDED);
	if (status != 0)
	{
		regerror(status,&commentPattern,errbuffer,512);
		fprintf(stderr,"ReadKillFile: regcomp(commentPattern): %s\n",errbuffer);
		exit(status);
	}
	/* Kill pattern line pattern */
	status = regcomp(&linePattern,"^(from|subject):[[:space:]]*(.*)$",REG_NEWLINE|REG_EXTENDED|REG_ICASE);
	if (status != 0)
	{
		regerror(status,&linePattern,errbuffer,512);
		fprintf(stderr,"ReadKillFile: regcomp(linePattern): %s\n",errbuffer);
		exit(status);
	}
	/* Open file */
	kfp = fopen(killfile,"r");
	/* If no kill file, then no kill patterns. */
	if (kfp == NULL) return 0;
	while (fgets(oline,sizeof(oline),kfp) != NULL) {
		/* Blank out comments. */
		if ((status = regexec(&commentPattern,oline,2,matched,0)) == 0) {
			if (matched[1].rm_eo > matched[1].rm_so) {
				strncpy(line,oline,matched[1].rm_eo);
				line[matched[1].rm_eo] = '\n';
				line[matched[1].rm_eo+1] = '\0';
			} else {
				strncpy(line,oline,matched[0].rm_so);
				line[matched[0].rm_so] = '\n';
				line[matched[0].rm_so+1] = '\0';
			}
			while ((q = strchr(line,'#')) != NULL) {
				for (p = q-1;*q != '\0';p++,q++) *p = *q;
				*p = '\0';
			}
		} else {
			strcpy(line,oline);
		}
		/* Trim white space. */
		for (q = line; *q != '\0' && *q <= ' '; q++) ;
		if (q > line) {
			p = line;
			while (*q != '\0') {*p++ = *q++;}
		}
		q = strrchr(line,'\n');
		if (q != NULL) {
			for (q--;q >= line && *q <= ' '; q--) ;
			*++q = '\n';
			*++q = '\0';
		}
		/* Blank line? Skip it. */
		if (line[0] == '\n' || line[0] == '\0') continue;
		/* Break line into field (from: or subject:) and pattern. */
		if ((status = regexec(&linePattern,line,3,matched,0)) == 0) {
			line[matched[1].rm_eo] = '\0'; /* End of field */
			p = &(line[matched[2].rm_so]); /* Start of pattern */
			q = strrchr(p,'\n');	       /* End of pattern */
			if (q != NULL) *q = '\0';
			/* Grow vector as needed. */
			if (++patternCount > patternAlloc) {
				if (patternAlloc == 0) {
					*patterns = malloc(sizeof(KillPattern)*KILLPATTERNALLOCSIZE);
					if (*patterns == NULL) {
						int err = errno;
						perror("ReadKillFile: malloc(KillPattern)");
						exit(err);
					}
					patternAlloc = KILLPATTERNALLOCSIZE;
				} else {
					*patterns = realloc(*patterns,sizeof(KillPattern)*(KILLPATTERNALLOCSIZE+patternAlloc));
					if (*patterns == NULL) {
						int err = errno;
						perror("ReadKillFile: malloc(KillPattern)");
						exit(err);
					}
					patternAlloc += KILLPATTERNALLOCSIZE;
				}
			}
			/* Fill in pattern structure. */
			/* Set field type (from or subject). */
			if (line[0] == 'f' || line[0] == 'F') {
				(*patterns)[patternCount-1].field = FROM;
			} else {
				(*patterns)[patternCount-1].field = SUBJECT;
			}
			/* Copy pattern string. */
			(*patterns)[patternCount-1].patternBuffer = malloc(sizeof(char)*(strlen(p)+1));
			if ((*patterns)[patternCount-1].patternBuffer == NULL) {
				int err = errno;
				perror("ReadKillFile: malloc(patternBuffer)");
				exit(err);
			}
			strcpy((*patterns)[patternCount-1].patternBuffer,p);
			/* Compile pattern. */
			status = regcomp(&((*patterns)[patternCount-1].pattern),
					 (*patterns)[patternCount-1].patternBuffer,
					 REG_EXTENDED);
			if (status != 0) {
				fprintf(stderr,"ReadKillFile: %s: Bad regular expression at  %s",
					killfile,oline);
			}
		} else {
			/* Error message.*/
			fprintf(stderr,"ReadKillFile: %s: Syntax error at %s",
				killfile,oline);
		}
	}
	/* Close file and free patterns. */
	fclose(kfp);
	regfree(&commentPattern);
	regfree(&linePattern);
	/* Return pattern count. */
	return patternCount;
}

/* Apply kill patterns to file. If any pattern matches return FALSE, otherwise
 * return TRUE.*/
int PassKillFile(const char *messageFile,int patternCount,KillPattern *patterns)
{
	FILE *mfp;
	int kpindex,status;
	char headerline[2048];
	
	mfp = fopen(messageFile,"r");
	if (mfp == NULL) return FALSE;
	/* Get header lines. */
	while (fgets(headerline,sizeof(headerline),mfp) != NULL) {
		if (headerline[0] == '\n') break;	/* End of headers. */
		/* From: header -- apply FROM kill patterns. */
		if (strncasecmp("from: ",headerline,6) == 0) {
			for (kpindex = 0;kpindex < patternCount;kpindex++) {
				if (patterns[kpindex].field != FROM) continue;
				status = regexec(&(patterns[kpindex].pattern),&headerline[6],0,NULL,0);
				if (status == 0) {
					fclose(mfp);
#ifdef DEBUG
					fprintf(stderr,"*** PassKillFile: failed: %s",headerline);
#endif
					return FALSE;
				}
			}
		/* Subject: header -- apply SUBJECT kill patterns. */
		} else if (strncasecmp("subject: ",headerline,9) == 0) {
			for (kpindex = 0;kpindex < patternCount;kpindex++) {
				if (patterns[kpindex].field != SUBJECT) continue;
				status = regexec(&(patterns[kpindex].pattern),&headerline[9],0,NULL,0);
				if (status == 0) {
					fclose(mfp);
#ifdef DEBUG
					fprintf(stderr,"*** PassKillFile: failed: %s",headerline);
#endif
					return FALSE;
				}
			}
		}
	}
	fclose(mfp);
#ifdef DEBUG
	fprintf(stderr,"*** PassKillFile: passed: %s\n",messageFile);
#endif
	return TRUE;					
}

static int checkValidMHead(struct MsgHeaderType *MessageHeader)
{
	int cnum, iconf;
        char *p;
        int sawspace = FALSE;

	/*fprintf(stderr,"*** MessageHeader->SizeMsg = '%s'\n",MessageHeader->SizeMsg);*/
	for (p = MessageHeader->SizeMsg; p < (MessageHeader->SizeMsg)+6; p++) {
		if (*p >= '0' && *p <= '9' && !sawspace) continue;
		if (*p == ' ') {sawspace = TRUE;continue;}
		return FALSE;
	}
	return TRUE;
}

static int LooksLikeHeader(const unsigned char *buffer)
{
    struct MsgHeaderType *MessageHeader = (struct MsgHeaderType *) buffer;
    if ((MessageHeader->MsgActive == 0xE1 || MessageHeader->MsgActive == 0xE2) &&
        checkValidMHead(MessageHeader)) {
        return TRUE;
    } else {
        return FALSE;
    }
}
        

/* Process messages.dat file (messages). */

int ProcessMESSAGESDAT(const char *messageDatFile,const char *killfile)
{
	FILE *messageDatIn, *spoolFileOut;
	KillPattern *killPatterns = NULL;
	int numberOfKillPatterns = 0;
	struct MsgHeaderType MessageHeader;
	static char buffer[128], filename[256], errorbufer[256];
	char *p,*colon;
	int count, oldcount, kcount;
	int conf = -1, cnum, iconf,i;
	int iconference,numBlocks, headerP;
	Active *current;
	int messageNumber;
	double SizeOfmessageDatFile, PosOfmessageDatFile;
	double Percent;

	/* Read in kill file, if supplied. */
	if (strlen(killfile) > 0) {
		numberOfKillPatterns = ReadKillFile(killfile,&killPatterns);
	}	

	/* Get size of messages.dat file.  */
	SizeOfmessageDatFile = (double) SizeOfFile(messageDatFile);

	/* Open messages.dat file. */
	if ((messageDatIn = fopen(messageDatFile,"rb")) == NULL)
	{
		int err = errno;
		perror("fopen: messageDatFile");
		return(err);
	}
	/* Read header block. */
	if (fread(buffer,sizeof(buffer),1,messageDatIn) != 1)
	{
		int err = errno;
		perror("fread: header0");
		return(err);
	}
	while (1)
	{
		/* Read in a message header. */
		if (fread(&MessageHeader.Status,sizeof(struct MsgHeaderType),1,messageDatIn) != 1)
		{
			break;
		}
                /*fprintf(stderr,"*** ProcessMESSAGESDAT: MessageHeader.Status = %d\n",MessageHeader.Status);*/
		if (!LooksLikeHeader(&MessageHeader)) continue;
		/* Message Status is zero, at EOF. */
                if (MessageHeader.Status == 0) break;
		
		/* Get conference number */
		cnum = readCnum((byte*)&(MessageHeader.BinConfN));
		/* If conference  is different from previous conference,
		   print previous conference (if any) stats and reset 
		   counters. */
		if (cnum != conf)
		{
			if (conf >= 0)
			{
				printf("Conference %d \t[ %-63s ] %3ld New Message%s\n",
					confs[iconf].number,confs[iconf].name,
					count - oldcount,(count - oldcount != 1)?"s":"");
				if (kcount > 0) {
					printf("\t(%d articles killed)\n",kcount);
				}
			}
			count = 0;
			kcount = 0;
			oldcount = 0;
			conf = cnum;
			for (iconf = 0;iconf < lastconf;iconf++)
			{
				if (conf == confs[iconf].number) break;
			}
			if (iconf == lastconf)
			{
				MessageHeader.BinConfN[1] = 0;
				cnum = readCnum((byte*)&(MessageHeader.BinConfN));
				for (iconf = 0;iconf < lastconf;iconf++)
				{
					if (conf == confs[iconf].number) break;
				}
				if (iconf == lastconf)
				{
					iconf = 0;
					conf = confs[iconf].number;
				}
			}
			current = confs[iconf].activeEntry;
			oldcount = current->last;
			count = oldcount;
		}
		/* Increment message index. */
		messageNumber = ++current->last;
		/* Count messages. */
		count++;
		/* Create message filename. */
		sprintf(filename,"%s/%d",confs[iconf].directory,messageNumber);
		/* Open message file. */
		spoolFileOut = fopen(filename,"w");
		if (spoolFileOut == NULL)
		{
			int err = errno;
			perror("fopen: spoolFileOut");
			return(err);
		}
		/* Fill in QWK header fields.
		   [commented out for real Usenet news feed.] */
		strncpy(buffer,MessageHeader.ForWhom,25);
		buffer[25] = '\0';
		for (p = &buffer[24]; *p == ' ' && p > buffer; p--) *p = '\0';
		/*fprintf(spoolFileOut,"X-QWK-To: %s\n",buffer);*/
		strncpy(buffer,MessageHeader.Author,25);
		buffer[25] = '\0';
		for (p = &buffer[24]; *p == ' ' && p > buffer; p--) *p = '\0';
		/*fprintf(spoolFileOut,"X-QWK-From: %s\n",buffer);*/
		strncpy(buffer,MessageHeader.Subject,25);
		buffer[25] = '\0';
		for (p = &buffer[24]; *p == ' ' && p > buffer; p--) *p = '\0';
		/*fprintf(spoolFileOut,"X-QWK-Subject: %s\n",buffer);*/
		strncpy(buffer,MessageHeader.MsgDate,8);
		buffer[8] = ' ';
		strncpy(buffer+9,MessageHeader.MsgTime,5);
		buffer[8+1+5] = '\0';
		/*fprintf(spoolFileOut,"X-QWK-Date: %s\n",buffer);*/
		headerP = FALSE;
		colon = NULL;
		/* Convert message text to plain text file. */
		numBlocks = atoi(MessageHeader.SizeMsg) - 1;
		/*fprintf(stderr,"*** MessageHeader.SizeMsg = '%s', numBlocks = %d\n",MessageHeader.SizeMsg,numBlocks);*/
		for (i = 0; i < numBlocks; i++)
		{
                        if (fread(buffer,sizeof(buffer),1,messageDatIn) != 1)
			{
                                int err = errno;
                                sprintf(errorbufer,"fread: message (block=%d/%d)",i,numBlocks);
                                errno = err;
				perror(errorbufer);
                                return(err);
			}
                        if (LooksLikeHeader(buffer)) {
                            fseek(messageDatIn,-sizeof(buffer),SEEK_CUR);
                            break;
                        }
			for (p = buffer;p != NULL;)
			{
				/* Convert magic 8-bit char to LF */
				p = strchr(p,(char) 227);
				if (p != NULL) *p = '\n';
			}
			if (!headerP)
			{
				if (colon == NULL) colon = strchr(buffer,':');
				else colon -= sizeof(buffer);
				p = strchr(buffer,'\n');
				if (colon != NULL && p != NULL && colon > p)
				{
					fputc('\n',spoolFileOut);
					headerP = TRUE;
				} else if (p != NULL && colon == NULL)
				{
					fputc('\n',spoolFileOut);
					headerP = TRUE;
				}
			}
			if (fwrite(buffer,sizeof(buffer),1,spoolFileOut) != 1)
			{
				int err = errno;
				perror("fwrite: message");
				return(err);
			}
		}
		fclose(spoolFileOut);
		/* Process killfile filter. */
		if (!PassKillFile(filename,numberOfKillPatterns,killPatterns)) {
		  current->last--;
		  count--;
		  kcount++;
		}
		/* Update stats. */
		PosOfmessageDatFile = (double) ftell(messageDatIn);
		Percent = PosOfmessageDatFile / SizeOfmessageDatFile;
		printf("###%f\n",Percent);
	}
	if (Percent < 1.0) printf("###1.0\n");
	fclose(messageDatIn);
	if (conf >= 0)
	{
		printf("Conference %d \t[ %-63s ] %3ld New Message%s\n",
			confs[iconf].number,confs[iconf].name,
			count - oldcount,(count - oldcount != 1)?"s":"");
	}
        return 0;
}

/* Write updated active and newsrc files. */
void WriteActive(const char *activeFile,const char *newsrc)
{
	static char newFile[256],backupFile[256];
	FILE *in,*out;
	static char line[256];
	char *p;
	int i;

	sprintf(newFile,"%s.new",activeFile);
	sprintf(backupFile,"%s~",activeFile);
	out = fopen(newFile,"w");
	if (out == NULL)
	{
		int err = errno;
		perror("fopen: newActive");
		exit(err);
	}
	for (i = 0; i < numActive; i++)
	{
		fprintf(out,"%d %0.10d %05d =%s\n%s %0.10d %05d %c\n",
			    activeTable[i].confNumber,activeTable[i].last,
			    activeTable[i].first,activeTable[i].name,
			    activeTable[i].name,activeTable[i].last,
			    activeTable[i].first,
			    (strcmp(activeTable[i].name,REPLY) == 0)?'n':'y');
	}
	fclose(out);
	if (access(activeFile,F_OK) == 0)
	{
		rename(activeFile,backupFile);
	}
	if (rename(newFile,activeFile) != 0)
	{
		int err = errno;
		perror("rename: newActive=>activeFile");
		exit(err);
	}
	if (access(newsrc,F_OK) < 0)
	{
		out = fopen(newsrc,"w");
		if (out == NULL)
		{
			int err = errno;
			perror("fopen: newsrc");
			exit(err);
		}
		for (i = 0; i < numActive; i++)
		{
			fprintf(out,"%s:\n",activeTable[i].name);
		}
		fclose(out);
	} else
	{
		sprintf(newFile,"%s.new",newsrc);
		sprintf(backupFile,"%s~",newsrc);
		in = fopen(newsrc,"r");
		if (in == NULL)
		{
			int err = errno;
			perror("fopen: oldnewsrc");
			exit(err);
		}
		out = fopen(newFile,"w");
		if (out == NULL)
		{
			int err = errno;
			perror("fopen: newnewsrc");
			exit(err);
		}
		while (fgets(line,256,in) != NULL)
		{
			fputs(line,out);
			p = strchr(line,':');
			if (p == NULL) p = strchr(line,'!');
			if (p == NULL) continue;
			*p = '\0';
			for (i = 0; i < numActive; i++)
			{
				if (strcmp(activeTable[i].name,line) == 0)
				{
					activeTable[i].newsrcFlag = TRUE;
					break;
				}
			}
		}
		fclose(in);
		for (i = 0; i < numActive; i++)
		{
			if (!activeTable[i].newsrcFlag)
			{
				fprintf(out,"%s:\n",activeTable[i].name);
			}
		}
		fclose(out);
		rename(newsrc,backupFile);
		if (rename(newFile,newsrc) < 0)
		{
			int err = errno;
			perror("rename: newnewsrc=>newsrc");
			exit(err);
		}
	}
}

/* Main program. Fetch command line args and call processing functions. */
int main(int argc,char *argv[])
{
        char *control, *messages, *active, *spool, *newsrc, *killfile;
        int err;

	if (argc < 6 || argc > 7)
	{
		fprintf(stderr,"usage: QWKToSpool control messages active spool newsrc [killfile]\n");
		exit(1);
	}
	control = argv[1];
	messages = argv[2];
	active = argv[3];
	spool = argv[4];
	newsrc = argv[5];
	if (argc == 7) {
		killfile = argv[6];
	} else {
		killfile = "";
	}
	BuildActiveAndConfs(control,spool,active);
	err = ProcessMESSAGESDAT(messages,killfile);
	WriteActive(active,newsrc);
	printf("\nUsername:%s\n",userName);
	exit(err);
}

