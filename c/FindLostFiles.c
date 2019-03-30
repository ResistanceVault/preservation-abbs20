/***************************************************************************
*									FindLostFiles 1.0 (28/08-94)
*
*	Find lost files laying in abbs filedir path's.
*
*	Usage : 
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>
#include <dos/rdargs.h>
#include <dos/exall.h>

#include <proto/exec.h>
#include <proto/dos.h>

#include <stdio.h>
#include <string.h>
#include <ctype.h>

struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct ExAllControl *eac = NULL;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);
unsigned char *upstring (unsigned char *string);
unsigned char upchar (unsigned char c);

#define TEMPLATE "Fix/S"
#define OPT_COUNT 1

#ifdef __SASC
__regargs int _CXBRK(void) { return(0); }  /* Disable Lattice CTRL/C handling */
__regargs int __chkabort(void) { return(0); }  /* really */
#endif

char *vers = "\0$VER: FindLostFiles v1.0 (1.4.94)\n\r";	/* day,month,year */

#define BUFFERSIZE 2048

struct ConfigRecord *config;
UBYTE	buffer[BUFFERSIZE];
ULONG matchbuffer[1024/4];

int main(int argc, char **argv)
{
	int	ret = 10,n,r,k,kk;
	int	err,more,dobreak = 0;
	BPTR	lock = NULL;
	struct Fileentry fentry;
	struct RDArgs *RDArg;
	struct ExAllData *ead;
	LONG	*result[OPT_COUNT] = {0};
	char	string[258],*ptr;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			while (1) {
				for (n = 0; n < config->ActiveDirs; n++) {
					r = config->FileOrder[n]-1;

					if (!(*config->DirNames[r]))
						continue;

					if (!(lock = Lock (config->DirPaths[r],ACCESS_READ))) {
						printf ("Error getting lock in %s's filedirpath (%s)\n",
							config->DirNames[r],config->DirPaths[r]);
						break;
					}

					eac->eac_LastKey = 0;
					do {
						more = ExAll (lock,(struct ExAllData *) buffer,sizeof (buffer),ED_COMMENT,eac);
						if ((!more) && (IoErr() != ERROR_NO_MORE_ENTRIES)) {
							printf ("Got Error from ExAll..\n");
/* ExAll failed abnormally */
							break;
						}
						if (eac->eac_Entries == 0) {
/* ExAll failed normally with no entries */
							continue;						/* ("more" is *usually* zero) */
						}
						ead = (struct ExAllData *) buffer;
						do {
							if ((dobreak) || (ead->ed_Type > 0))
								continue;

							msg.Command = Main_findfile;
							msg.Name = ead->ed_Name;
							msg.arg = (ULONG) matchbuffer;
							matchbuffer[2] = 0;
							msg.UserNr = r;
							msg.Data = (ULONG) &fentry;
							err = HandleMsg (&msg);

							if (err == Error_Not_Found) {
								printf ("file \"%s\" was not found in filedir \"%s\"\n",
									ead->ed_Name,config->DirNames[r]);
								for (k = 0,kk = 0; kk < config->ActiveDirs; k++) {
									if (!(*config->DirNames[k]))
										continue;
									else
										kk += 1;

									if (k == r)
										continue;

									if (!strcmp (config->DirPaths[r],config->DirPaths[k])) {
										printf ("(This may be because more than one filedir"
											" share this filedir path..)\n");
										break;
									}
								}
								if ((!ead->ed_Comment) || (!(*ead->ed_Comment)))
									printf ("No comment..\n");
								else {
									if (isalnum (*ead->ed_Comment))
										ptr = ead->ed_Comment;
									else
										ptr = ead->ed_Comment + 1;

									printf ("comment = %s\n",ptr);
								}
								printf ("Do you want me to add it to filedir %s ? (Y/n)",
									config->DirNames[r]);

								while (1) {
									kk = getch();
									if (kk == 3 || (SetSignal(0L,SIGBREAKF_CTRL_C) &
										SIGBREAKF_CTRL_C)) {
										dobreak = 1;
										break;
									} else if ((kk == '\n') || (kk == '\r') || 'Y' == upchar (kk)) {
										printf (" Yes\n");

										if (strlen (ead->ed_Name) > Sizeof_FileName) {
											printf ("Sorry, filename to long..\n");
											break;
										}

										if ((!ead->ed_Comment) || (!(*ead->ed_Comment))) {
											printf ("Enter comment :");
											if (gets (string) && (strlen (string)))
												strncpy (fentry.Filedescription,string,
													sizeof(fentry.Filedescription));
											else
												strcpy (fentry.Filedescription,"Auto comment");
										} else {
											if (isalnum (*ead->ed_Comment))
												ptr = ead->ed_Comment;
											else
												ptr = ead->ed_Comment + 1;

											strncpy (fentry.Filedescription,ptr,
												sizeof(fentry.Filedescription));
										}

										strcpy (fentry.Filename,ead->ed_Name);
										fentry.Fsize				= ead->ed_Size;
										fentry.Uploader			= config->SYSOPUsernr;
										fentry.PrivateULto		= 0L;
										fentry.AntallDLs			= 0L;
										fentry.Infomsgnr			= 0L;
										fentry.ULdate.ds_Days	= ead->ed_Days;
										fentry.ULdate.ds_Minute	= ead->ed_Mins;
										fentry.ULdate.ds_Tick	= ead->ed_Ticks;

										if (r == 0) {
											fentry.Filestatus		= FILESTATUSF_PrivateUL;	/* Tmp hack.. */
											fentry.PrivateULto	= config->SYSOPUsernr;
										} else
											fentry.Filestatus		= 0;


										msg.Command = Main_addfile;
										msg.Data = (ULONG) &fentry;
										msg.UserNr = r;

										err = HandleMsg (&msg);

										if (err != Error_OK)
											printf ("Error adding file %s to dir %s\n",
												ead->ed_Name,config->DirNames[r]);

										break;
									} else if ('N' == upchar(kk)) {
										printf (" No\n");
										break;
									}
								}
								printf ("\n");
	
							} else
								if (err != Error_OK) {
									printf ("Error reading fileentry for file %s\n",ead->ed_Name);
									break;
								}
						} while (ead = ead->ed_Next);

					} while (more);

					UnLock (lock);
					lock = NULL;
				}
				break;
			}
			if (lock)
				UnLock (lock);
			Cleanup();
		}
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	return (ret);
}

int HandleMsg (struct ABBSmsg *msg)
{
	struct MsgPort *mainport,*inport;
	struct ABBSmsg *inmsg;
	int	ret;

	inport = msg->msg.mn_ReplyPort;
	Forbid();
	if (mainport = FindPort(MainPortName)) {
		PutMsg(mainport,msg);
		Permit();
		while (1) {
			if (!WaitPort(inport))
				continue;

			if (inmsg = (struct ABBSmsg *) GetMsg (inport))
				break;
		}
		ret = inmsg->Error;
	} else {
		Permit();
		ret = Error_NoPort;
	}

	return (ret);
}
unsigned char *upstring (unsigned char *string)
{
	char	*ptr = string;

	while (*ptr) {
		*ptr = upchar (*ptr);
		ptr += 1;
	}

	return (string);
}
unsigned char upchar (unsigned char c)
{
	if (c < 'a')
		return (c);

	if (c <= 'z')
		return ((unsigned char) (c - 32));

	if (c < 0xe0)
		return (c);

	return ((unsigned char) (c - 32));
}

int Setup (void)
{
	int	ret = 0;

	if (FindPort (MainPortName)) {
		if (eac = AllocDosObject(DOS_EXALLCONTROL,NULL)) {
			if (msg.msg.mn_ReplyPort = CreateMsgPort()) {
/* Get access to config structure
*/
				msg.Command = Main_testconfig;
				if (HandleMsg (&msg) || !msg.UserNr) {
					printf ("Error talking to ABBS\n");
				} else {
					config = (struct ConfigRecord *) msg.Data;
					ret = 1;
				}
			} else
				printf ("Error creating message port\n");
		} else
			printf ("Error allocating EAC\n");
	} else
		printf ("ABBS must be running for FindLostFiles to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
	if (eac) FreeDosObject(DOS_EXALLCONTROL,eac);
}
