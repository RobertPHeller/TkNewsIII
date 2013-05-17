/* 
 * ------------------------------------------------------------------
 * headList.c - generate header listing from spool area
 * Created by Robert Heller on Sat Dec  2 14:27:37 1995
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
 * Simple C program to extract article headers for fast processing*
 * of article list insertion.                                     *
 *                                                                *
 ******************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <regex.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#ifndef FALSE
#define FALSE (0)
#endif
#ifndef TRUE
#define TRUE (1)
#endif


/******************************************************************
 *                                                                *
 * Extract a RFC822 name from a From: header line                 *
 *                                                                *
 ******************************************************************/

void GetRFC822Name(char *from_line,char *from_buffer,int from_buffer_size)
{
	static regex_t rxcorner,rxparens;
	static int rxinit = FALSE;
	static regmatch_t matched[5];
	int plen;
	char *pmatch,*q;
	int status;
	static char errbuffer[512];

	/* Initialize compiled regular expressions */
	if (!rxinit)
	{
            status = regcomp(&rxcorner,"^(.*)(<.+>)(.*)$",
                             REG_NEWLINE|REG_EXTENDED);
		if (status != 0)
		{
			regerror(status,&rxcorner,errbuffer,512);
			fprintf(stderr,"GetRFC822Name: regcomp(rxcorner): %s\n",errbuffer);
			exit(status);
		}
		status = regcomp(&rxparens,"^(.*\\()(.+)(\\).*)$",REG_NEWLINE|REG_EXTENDED);
		if (status != 0)
		{
			regerror(status,&rxcorner,errbuffer,512);
			fprintf(stderr,"GetRFC822Name: regcomp(rxparens): %s\n",errbuffer);
			exit(status);
		}
		rxinit = TRUE;
	}

	/* Look for a '<...>' element (E-Mail address) */
	if ((status = regexec(&rxcorner,from_line,5,matched,0)) == 0)
	{
		/* Found the '<...>'. Grab the  text before or after it.
		 * This will be the author's real name. */
		pmatch = matched[1].rm_so + from_line;
		plen = matched[1].rm_eo - matched[1].rm_so;
		if (plen <= 1)
		{
			pmatch = matched[3].rm_so + from_line;
			plen = matched[3].rm_eo - matched[3].rm_so;
		}
		/* Trim leading space */
		while (isspace(*pmatch) && plen > 0)
		{
			pmatch++;
			plen--;
		}
		/* Trim trailing space */
		q = pmatch+plen-1;
		while (isspace(*q) && plen > 0)
		{
			q--;
			plen--;
		}
		/* Copy name to from_buffer and return */
		if (plen >= from_buffer_size) plen = from_buffer_size - 1;
		strncpy(from_buffer,pmatch,plen);
		from_buffer[plen] = '\0';
		return;
	} else if (status != REG_NOMATCH)
	{
		regerror(status,&rxcorner,errbuffer,512);
		fprintf(stderr,"GetRFC822Name: regexec(rxcorner): %s\n",errbuffer);
		exit(status);
	}
	/* Look for parens... */
	if ((status = regexec(&rxparens,from_line,4,matched,0)) == 0)
	{
		/* Extract name from the parens. */
		pmatch = matched[2].rm_so + from_line;
		plen = matched[2].rm_eo - matched[2].rm_so;
		/* Trim white space. */
		while (isspace(*pmatch) && plen > 0)
		{
			pmatch++;
			plen--;
		}
		q = pmatch+plen-1;
		while (isspace(*q) && plen > 0)
		{
			q--;
			plen--;
		}
		/* Return results.* */
		if (plen >= from_buffer_size) plen = from_buffer_size - 1;
		strncpy(from_buffer,pmatch,plen);
		from_buffer[plen] = '\0';
		return;
	} else if (status != REG_NOMATCH)
	{
		regerror(status,&rxparens,errbuffer,512);
		fprintf(stderr,"GetRFC822Name: regexec(rxparens): %s\n",errbuffer);
		exit(status);
	}
	/* Otherwise, just trim whitespace from the input line and return it. */
	plen = strlen(from_line);
	pmatch = from_line;
	while (isspace(*pmatch) && plen > 0)
	{
		pmatch++;
		plen--;
	}
	q = pmatch+plen-1;
	while (isspace(*q) && plen > 0)
	{
		q--;
		plen--;
	}
	if (plen >= from_buffer_size) plen = from_buffer_size - 1;
	strncpy(from_buffer,pmatch,plen);
	from_buffer[plen] = '\0';
}
	

/******************************************************************
 *                                                                *
 * Process one article, fetching header lines and printing out    *
 * a header line (to be read in by the Tcl code and inserted into *
 * a ListBox widget).                                             *
 *                                                                *
 ******************************************************************/

void LoadArticleHead(char *spooldir, char *grouppath, int artnumber,
		     regex_t *compPattern, char *nread)
{
    static regex_t rxheader;
    static int rxinit = FALSE;
    static char filename[512], linebuffer[4096], hbuffer[16384];
    static char errbuffer[512];
    FILE *file;
    
    static char subject[256], fromline[256], from[22], date[256],
          matchsubj[256], messageid[256], inreplyto[256], key[64];
    int plen;
    char *pmatch1, *pmatch2, *p, *q;
    int lines;
    long size;
    int status,i;
    
    /* Initialize compiled regular expressions */
    if (!rxinit)
    {
        status = regcomp(&rxheader,"^[^[:space:]]+:[[:space:]]+.*$",
                         REG_NEWLINE|REG_EXTENDED);
        if (status != 0)
        {
            regerror(status,&rxheader,errbuffer,512);
            fprintf(stderr,"LoadArticleHead: regcomp(rxheader): %s\n",errbuffer);
            exit(status);
        }
        rxinit = TRUE;
    }
    /* Form article file name. */	
    sprintf(filename,"%s/%s/%d",spooldir,grouppath,artnumber);
    /*fprintf(stderr,"*** LoadArticleHead: filename is |%s|\n",filename);*/
    /* Exists and readable? If not, skip it. */
    /*fprintf(stderr,"*** LoadArticleHead: access(filename,R_OK) = %d\n",access(filename,R_OK));*/
    if (access(filename,R_OK) != 0) return;
    /* Open file.  */
    file = fopen(filename,"r");
    /* Initially, no header info. */
    subject[0] = '\0';
    from[0] = '\0';
    date[0] = '\0';
    lines = 0;
    hbuffer[0] = '\n';
    hbuffer[1] = '\0';
    /* Read lines, until end of header (empty line). */
    while ((p = fgets(linebuffer,4096,file)) != NULL)
    {
        if (*p == ' ' || *p == '\t') {
            q = strchr(hbuffer,'\n');
            strcpy(q,p);
            continue;
        } else if (hbuffer[0] != '\n') {
            q = strchr(hbuffer,'\n');
            /**q = '\0';*/
            /*fprintf(stderr,"*** LoadArticleHead: hbuffer = |%s|\n",hbuffer);*/
            status = regexec(&rxheader,hbuffer,0,NULL,0);
            /*fprintf(stderr,"*** LoadArticleHead: regexec status is %d\n",status);*/
            if (status == 0)
            {
                pmatch1 = hbuffer;
                for (pmatch2 = pmatch1; *pmatch2 != ':'; pmatch2++) ;
                plen = pmatch2 - pmatch1;
                if (plen > 64) plen = 64;
                strncpy(key,pmatch1,plen);
                key[plen] = '\0';
                /*fprintf(stderr,"*** LoadArticleHead: key = |%s|\n",key);*/
                pmatch1 = pmatch2+1;
                while (isspace(*pmatch1)) pmatch1++;
                pmatch2 = strchr(pmatch1,'\n');
                plen = pmatch2 - pmatch1;
                /*fprintf(stderr,"*** LoadArticleHead: value is |%s|\n",pmatch1);*/
                if (strcasecmp(key,"x-qwk-subject") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(subject,pmatch1,plen);
                    subject[plen] = '\0';
                } else if (strcasecmp(key,"subject") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(subject,pmatch1,plen);
                    subject[plen] = '\0';
                } else if (strcasecmp(key,"x-qwk-from") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(fromline,pmatch1,plen);
                    fromline[plen] = '\0';
                } else if (strcasecmp(key,"from") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(fromline,pmatch1,plen);
                    fromline[plen] = '\0';
                } else if (strcasecmp(key,"x-qwk-date") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(date,pmatch1,plen);
                    date[plen] = '\0';
                } else if (strcasecmp(key,"date") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(date,pmatch1,plen);
                    date[plen] = '\0';
                } else if (strcasecmp(key,"lines") == 0)
                {
                    lines = atoi(pmatch1);
                } else if (strcasecmp(key,"message-id") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(messageid,pmatch1,plen);
                    messageid[plen] = '\0';
                } else if (strcasecmp(key,"in-reply-to") == 0)
                {
                    if (plen > 256) plen = 256;
                    strncpy(inreplyto,pmatch1,plen);
                    inreplyto[plen] = '\0';
                } 
            }
        }
        strcpy(hbuffer,p);
        /*fprintf(stderr,"*** LoadArticleHead: p = |%s|\n",p);*/
        if (*p == '\n') break;
    }
    fseek(file,0L,SEEK_END);
    size = ftell(file);
    /* Close file. */
    fclose(file);
    /* Extract author's real name. */
    GetRFC822Name(fromline,from,20);
    for (p = subject, q = matchsubj; *p != '\0';p++,q++)
    {
        if (isalpha(*p)) *q = tolower(*p);
        else *q = *p;
    }
    /*fprintf(stderr,"*** LoadArticleHead: artnumber = %d, nread = |%s|, subject = |%s|, from = |%s|, date = |%s|, lines = %d, size = %d, messageid = |%s|, inreplyto = |%s|\n",
            artnumber,nread,subject,from,date,lines,size,messageid,inreplyto);*/
    /* Check subject against supplied pattern.*/
    if (regexec(compPattern,matchsubj,0,NULL,0) != 0) return;
    /* Spit out header line. */
    printf("%d {%s} {%s} {%s} {%s} %d %d {%s} {%s}\n",
           artnumber, nread, subject, from, date, lines, size, messageid, 
           inreplyto);
}

/******************************************************************
 *                                                                *
 * Process all of the articles in the specified group.            *
 *                                                                *
 ******************************************************************/

void InsertArticleList (char *spoolDir, char *groupPath, char *pattern, int unreadp, int firstMessage, int lastMessage, int Nranges, char *rangeList[])
{
	
	static char unreadFlag[2];
	int nextload = 1;
	int irange;
	regex_t patt;
	int status;
	static char errbuffer[512];

	/* Compile the match pattern. */
	status = regcomp(&patt,pattern,REG_NOSUB);
	if (status != 0)
	{
		regerror(status,&patt,errbuffer,512);
		fprintf(stderr,"InsertArticleList: regcomp(pattern): %s\n",errbuffer);
		exit(status);
	}
	/* Fill in unreadFlag. */
	if (unreadp)
	{
		unreadFlag[0] = 'U';
		unreadFlag[1] = '\0';
	} else unreadFlag[0] = '\0';
	/* Process selected ranges of messages. */
	for (irange = 0; irange < Nranges; irange++)
	{
		int first,last;
		char *dash;
		dash = strchr(rangeList[irange],'-');
		if (dash == NULL)
		{
			first = atoi(rangeList[irange]);
			last = first;
		} else
		{
			first = atoi(rangeList[irange]);
			last = atoi(dash+1);
		}
		if (first < firstMessage) first = firstMessage;
		if (last > lastMessage) last = lastMessage;
		if (first > last) continue;
		/* First a batch of unread messages (always processed).*/
		while (nextload < first)
		{
			LoadArticleHead(spoolDir,groupPath,nextload,&patt,unreadFlag);
			nextload++;
		}
		/* Then (optional) unread messages. */
		if (unreadp)
		{
			 while (nextload <= last)
			 {
				LoadArticleHead(spoolDir,groupPath,nextload,&patt,"R ");
				nextload++;
			 }
		} else nextload = last + 1;
	}
/*        fprintf(stderr,"*** InsertArticleList: nextload = %d, lastMessage = %d\n",
            nextload,lastMessage); */
	/* Trailing unread messages. */
	while (nextload <= lastMessage)
	{
		LoadArticleHead(spoolDir,groupPath,nextload,&patt,unreadFlag);
		nextload++;
	}
}

/******************************************************************
 *                                                                *
 * Main program: gather command line option and then call main    *
 * processing function.                                           *
 *                                                                *
 ******************************************************************/

int main(int argc,char *argv[])
{
	char *spoolDir, *groupPath, *pattern;
	int unreadp, firstMessage, lastMessage;
	char *p, *q;

	if (argc < 7)
	{
		fprintf(stderr,"usage: headList spoolDir groupPath pattern unreadp firstMessage lastMessage [ranges...]\n");
		exit(99);
	}
	spoolDir = argv[1];
	groupPath = argv[2];
	pattern = (char*) malloc(strlen(argv[3])+1);
	if (pattern == NULL)
	{
		int err = errno;
		perror("headList: malloc");
		exit(err);
	}
	for (p = argv[3], q = pattern;*p != '\0';p++,q++)
	{
		if (isalpha(*p)) *q = tolower(*p);
		else *q = *p;
	}
	unreadp = atoi(argv[4]);
	firstMessage = atoi(argv[5]);
	lastMessage = atoi(argv[6]);
/*        fprintf(stderr,"*** main(): spoolDir = %s, groupPath = %s, pattern = %s, unreadp = %d, firstMessage = %d, lastMessage = %d, argc = %d\n",
            spoolDir,groupPath,pattern,unreadp,firstMessage,lastMessage,argc);*/
        InsertArticleList(spoolDir,groupPath,pattern,unreadp,firstMessage,lastMessage,argc-7,&(argv[7]));
	exit(0);
}
