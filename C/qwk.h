/* 
 * ------------------------------------------------------------------
 * qwk.h - QWK structures
 * Created by Robert Heller on Sun Nov 12 12:59:13 1995
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

#ifndef _QWK_H_
#define _QWK_H_

typedef unsigned char byte;

/*--------- FILES RECEIVED in *.QWK.-- Warning : DOS is not case-sensitive */

#define MSG_FILE    "messages.dat" /* Message filename prepared by Qmail */
#define CNTRL_FILE  "control.dat"  /* List of conferences by Qmail       */
#define MSG_EXT     ".msg"         /* Extension of reply file            */

/* typedef */
struct MsgHeaderType         /* RECEIVED MESSAGE HEADER STRUCTURE      */
       {
           byte Status        ,   /* ??? */
                NumMsg   [7 ] ,   /* Numero du message,envoi = conf !  */
                MsgDate  [8 ] ,   /* mm-dd-yy                          */
                MsgTime  [5 ] ,   /* HH:MM                             */
                ForWhom  [25] ,   /* Destinataire                      */
                Author   [25] ,   /* Nous mme...                      */
                Subject  [25] ,   /*                                   */
                PassWord [12] ,   /* Si sender ou group password       */
                RefMsg   [8 ] ,   /* Message rfrenc                 */
                SizeMsg  [6 ] ,   /* en ascii, nb blocs de 128 bytes   */
                MsgActive     ,   /* 0xE1 = active  0xE2 = inactive    */
                BinConfN [2 ] ,   /* 16 bit unsigned binary word       */
                Unused1       ,   /* space                             */
                Unused2       ,   /* space                             */
				NetTag        ;   /* space                             */
       } ;

/* typedef */
struct QmailRepType   /* SEND MESSAGE HEADER STRUCTURE. */
       {
           byte Status;            /* '+' = private  ' ' = public     */
           byte ConfNum  [7] ;     /* Numero de la confrence concerne */
           byte MsgDate  [13];     /* mm-dd-yyHH:MM                     */
           byte ForWhom  [25];     /* Destinataire                      */
           byte Author   [25];     /* Nous mme...                      */
           byte Subject  [25];     /*                                   */
           byte PassWord [12];     /* Si sender ou group password       */
           byte RefMsg   [8] ;     /* Message rfrenc                 */
           byte SizeMsg  [6] ;     /* en ascii, nb blocs de 128 bytes   */
           byte MsgActive    ;     /* 0xE1 = active                     */
           byte BinConfN [2] ;     /* 16 bit conference number binary.  */
           byte Unused1      ;     /* space                             */
           byte Unused2      ;     /* space                             */
           byte NetTag       ;     /* space                             */
       } ;
                        /* Variables used to read Control.dat         */

typedef struct {
	char name[64];
	long int last,first,confNumber;
	int newsrcFlag;
} Active;


typedef struct {
	int number;
	char name[64];
	char directory[256];
	Active *activeEntry;
} Conferences;


#define REPLY "reply" 	/* reply conference */
#define REPLYCNUM 9000
	
#endif // _QWK_H_

