/***************************************************************************
*									UserEditor 1.0 (1/05-94)
*
*	Edits userlists
*
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>

#include <libraries/gadtools.h>
#include <intuition/gadgetclass.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/intuition.h>
#include <proto/gadtools.h>
#include <clib/alib_protos.h>

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>

#include "UserEditorGui.h"

int	main(int argc, char **argv);
int	Setup (void);
void	Cleanup (void);
int	HandleMsg (struct ABBSmsg *msg);
int	setuplistview(void);
int	setupconflistview(void);
BOOL	handleidcmp(void);
void	UpdateDisplayNewUser (char *name);
void	updateconflistview(void);
void	dosaveuser(void);

char *vers = "\0$VER: UserEditor 0.1 (1.4.94)\n\r";	/* day,month,year */

struct IntuitionBase *IntuitionBase = NULL;
struct GfxBase *GfxBase = NULL;
struct DiskfontBase *DiskfontBase = NULL;
struct Library *GadToolsBase = NULL;
struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct Mainmemory *Mainmem;
struct UserRecord curuser,curuserback;
struct DateTime dt;

short	screenok = 0;
short	windowok = 0;
UWORD	numconfs = 0;
extern struct Window         *ABBSUserEditorWnd;
extern struct Gadget         *ABBSUserEditorGadgets[];
extern struct Menu           *ABBSUserEditorMenus;

static struct Node *list = NULL,*conflist = NULL;
struct List listheader,conflistheader;

struct EasyStruct aboutereq = {
	sizeof (struct EasyStruct),0,
	"ABBS Usereditor Info",
	"ABBS Usereditor v0.1.\nProgrammed by Geir Inge Høsteng.\n(c) 1994",
	"I know"
},saveerrorreq = {
	sizeof (struct EasyStruct),0,
	"Save Error!",
	"Error saving user!",
	"I know"
},loaderrorreq = {
	sizeof (struct EasyStruct),0,
	"Load Error!",
	"Error loading user!",
	"I know"
};

struct coNode {
	struct Node node;
	char	text[sizeof (NameT) + 10];
};

int main(int argc, char **argv)
{
	int	ret = 0;
	int	quit = 1;
	ULONG	waitsigs,gotsigs;

	if (Setup()) {
		waitsigs = ((1L << ABBSUserEditorWnd->UserPort->mp_SigBit) | SIGBREAKF_CTRL_C);
		memcpy (&curuserback,&curuser,sizeof (struct UserRecord));

		msg.Command = Main_testconfig_dontuse;
		if (HandleMsg (&msg) || !msg.UserNr) {
			printf ("Error talking to ABBS\n");
		} else {
			Mainmem = (struct Mainmemory *) msg.Data;
			if (setuplistview())
				if (setupconflistview())
					quit = 0;
		}
		while (!quit) {
			gotsigs = Wait (waitsigs);

			quit = (!(handleidcmp()));

			if (gotsigs & SIGBREAKF_CTRL_C)
				quit = 1;
		}

		Cleanup();
	}

	return (ret);
}

void updateconflistview(void)
{
	struct coNode *nodes;
	int	n;
	UWORD	acc;
	char	bits[10],*ptr,*ptr2;

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_conference_listview],
		ABBSUserEditorWnd,NULL,GTLV_Labels,NULL,TAG_DONE,0);

	nodes = (struct coNode *) conflist;

	for (n = 0; n < numconfs; n++) {
		ptr = bits;
		ptr2 = "RWUDFISZ";
		acc = curuser.ConfAccess[Mainmem->config.ConfOrder[n]-1];

		while (*ptr2) {
			if (acc & 1)
				*(ptr++) = *(ptr2++);
			else {
				*(ptr++) = ' ';
				ptr2 += 1;
			}
			acc = acc >> 1;
		}
		bits[8] = '\0';
		sprintf (nodes[n].text,"%s-%s",bits,
			Mainmem->config.ConfNames[Mainmem->config.ConfOrder[n]-1]);
	}

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_conference_listview],
		ABBSUserEditorWnd,NULL,GTLV_Labels,&conflistheader,TAG_DONE,0);
}

void	UpdateDisplayNewUser (char *name)
{
	int	n;
	char	string[80],string2[40];

	msg.Command	= Main_loaduser;
	msg.Name		= name;
	msg.Data		= (ULONG) &curuser;
	n = HandleMsg (&msg);

	if (n != Error_OK) {
		EasyRequestArgs(ABBSUserEditorWnd,&loaderrorreq,NULL,NULL);
		return;
	}

	memcpy (&curuserback,&curuser,sizeof (struct UserRecord));

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_username],
		ABBSUserEditorWnd,NULL,GA_Disabled,TRUE,GTST_String,&curuser.Name,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_address],
		ABBSUserEditorWnd,NULL,GTST_String,&curuser.Address,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_citystate],
		ABBSUserEditorWnd,NULL,GTST_String,&curuser.CityState,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_passwd],
		ABBSUserEditorWnd,NULL,GTST_String,&curuser.Password,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_homephone],
		ABBSUserEditorWnd,NULL,GTST_String,&curuser.HomeTelno,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_workphone],
		ABBSUserEditorWnd,NULL,GTST_String,&curuser.WorkTelno,TAG_DONE,0);

	dt.dat_Stamp.ds_Days		= curuser.LastAccess.ds_Days;
	dt.dat_Stamp.ds_Minute	= curuser.LastAccess.ds_Minute;
	dt.dat_Stamp.ds_Tick		= curuser.LastAccess.ds_Tick;
	dt.dat_Format	= FORMAT_DOS;
	dt.dat_Flags	= DTF_SUBST;
	dt.dat_StrDate	= string;
	dt.dat_StrTime	= string2;
	if (DateToStr (&dt)) {
		strcat (string," at ");
		strcat (string,string2);
	} else
		string[0] = '0';

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_lastontext],
		ABBSUserEditorWnd,NULL,GTTX_Text,string,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_charset],
		ABBSUserEditorWnd,NULL,GTCY_Active,curuser.Charset,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_scratchformat],
		ABBSUserEditorWnd,NULL,GTCY_Active,curuser.ScratchFormat,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_xpertlevel],
		ABBSUserEditorWnd,NULL,GTCY_Active,curuser.XpertLevel,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_protocol],
		ABBSUserEditorWnd,NULL,GTCY_Active,curuser.Protocol,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_timelimit],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.TimeLimit,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_filelimit],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.FileLimit,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_pagelength],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.PageLength,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_resymemsgnr],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.ResymeMsgNr,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_timeused],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.TimeUsed,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_ftimeused],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.FTimeUsed,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_byteratio],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.u_ByteRatiov,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_fileratio],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.u_FileRatiov,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_uploaded],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.Uploaded,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_downloaded],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.Downloaded,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_kbupload],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.KbUploaded,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_kbdownload],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.KbDownloaded,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_timeson],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.TimesOn,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_msgread],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.MsgsRead,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_msgdumped],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.MsgaGrab,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_totaltime],
		ABBSUserEditorWnd,NULL,GTIN_Number,curuser.Totaltime,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_grabformat],
		ABBSUserEditorWnd,NULL,GTMX_Active,curuser.GrabFormat,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_Killed],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_Killed,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_usefse],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_FSE,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_ansimenus],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_ANSIMenus,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_colormsg],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_ColorMessages,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_g_r],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_G_R,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_reviewown],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_KeepOwnMsgs,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_ansi],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_ANSI,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_clearscreen],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_ClearScreen,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_raw],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_RAW,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_filter],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_Filter,TAG_DONE,0);

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_sendbulletins],
		ABBSUserEditorWnd,NULL,GTCB_Checked,curuser.Userbits & USERF_SendBulletins,TAG_DONE,0);

	updateconflistview();
}

void dosaveuser(void)
{
	int	n;

/* Save'r bare hvis det er gjort forandringer
*/
	if (!(memcmp (&curuserback,&curuser,sizeof (struct UserRecord))))
		return;

	msg.Command	= Main_saveuser;
	msg.Name		= curuser.Name;
	msg.Data		= (ULONG) &curuser;
	msg.arg		= 0;
	n = HandleMsg (&msg);

	if (n != Error_OK) {
		EasyRequestArgs(ABBSUserEditorWnd,&saveerrorreq,NULL,NULL);
	}
}

BOOL handleidcmp(void)
{
	struct IntuiMessage	*m;
	BOOL	running = TRUE;
	int	n;
	UWORD	code;
	struct IntuiMessage	tmpmsg;
	struct Node *node;
	struct MenuItem		*mi;

	while (m = GT_GetIMsg (ABBSUserEditorWnd->UserPort)) {
		CopyMem ((char *) m, (char *) &tmpmsg, (long) sizeof(struct IntuiMessage));
		GT_ReplyIMsg(m);

		switch (tmpmsg.Class) {
			case	IDCMP_REFRESHWINDOW:
				GT_BeginRefresh (ABBSUserEditorWnd);
				ABBSUserEditorRender();
				GT_EndRefresh (ABBSUserEditorWnd,TRUE);
				break;

			case	IDCMP_MENUPICK:
				code = tmpmsg.Code;
				while (code != MENUNULL) {
					switch (MENUNUM(code)) {
						case 0:
							switch (ITEMNUM(code)) {
								case 0:	/* About */
									EasyRequestArgs(ABBSUserEditorWnd,&aboutereq,NULL,NULL);
									break;

								case 1:	/* Save */
									dosaveuser();
									break;

								case 3:	/* Quit */
/*									if (memcmp (&noderecordback,&noderecord,sizeof (struct NodeRecord))) {
										if (1 == EasyRequestArgs(ABBSUserEditorWnd,&quitreq,NULL,NULL))
											running = FALSE;
									} else
*/										running = FALSE;
									break;
							}
							break;
					}

					mi = ItemAddress(ABBSUserEditorMenus,code);
					code = mi->NextSelect;
				}
				break;

			case	IDCMP_CLOSEWINDOW:
				running = FALSE;
				break;

			case	IDCMP_GADGETUP:
				switch (((struct Gadget *) tmpmsg.IAddress)->GadgetID) {
					case GD_Users_ListView:
						node = listheader.lh_Head;
						for (n = 0; n < tmpmsg.Code; n++)
							node = node->ln_Succ;
						UpdateDisplayNewUser (node->ln_Name);
						break;

					case GD_saveuser :
						dosaveuser();
						break;

/*					case GD_username :
						strncpy (curuser.Name,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;
*/
					case GD_address:
						strncpy (curuser.Address,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_citystate:
						strncpy (curuser.CityState,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_passwd:
						strncpy (curuser.Password,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_homephone:
						strncpy (curuser.HomeTelno,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_workphone:
						strncpy (curuser.WorkTelno,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_charset:
						curuser.Charset = tmpmsg.Code;
						break;

					case GD_scratchformat:
						curuser.ScratchFormat = tmpmsg.Code;
						break;

					case GD_xpertlevel:
						curuser.XpertLevel = tmpmsg.Code;
						break;

					case GD_protocol :
						curuser.Protocol = tmpmsg.Code;
						break;

					case GD_timelimit :
						curuser.TimeLimit = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

					case GD_filelimit :
						curuser.FileLimit = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_pagelength:
						curuser.PageLength = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_resymemsgnr:
						curuser.ResymeMsgNr = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_timeused:
						curuser.TimeUsed = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_ftimeused:
						curuser.FTimeUsed = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_byteratio:
						curuser.u_ByteRatiov = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_fileratio:
						curuser.u_FileRatiov = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_uploaded:
						curuser.Uploaded = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_downloaded:
						curuser.Downloaded = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_kbupload:
						curuser.KbUploaded = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_kbdownload:
						curuser.KbDownloaded = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_timeson:
						curuser.TimesOn = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_msgread:
						curuser.MsgsRead = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_msgdumped:
						curuser.MsgaGrab = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_totaltime:
						curuser.Totaltime = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_grabformat:
						curuser.GrabFormat = tmpmsg.Code;
						break;

					case GD_Killed:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_Killed;
						else
							curuser.Userbits &= ~USERF_Killed;
						break;

					case GD_usefse:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_FSE;
						else
							curuser.Userbits &= ~USERF_FSE;
						break;

					case GD_ansimenus:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_ANSIMenus;
						else
							curuser.Userbits &= ~USERF_ANSIMenus;
						break;

					case GD_colormsg:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_ColorMessages;
						else
							curuser.Userbits &= ~USERF_ColorMessages;
						break;

					case GD_g_r:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_G_R;
						else
							curuser.Userbits &= ~USERF_G_R;
						break;

					case GD_reviewown:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_KeepOwnMsgs;
						else
							curuser.Userbits &= ~USERF_KeepOwnMsgs;
						break;

					case GD_ansi:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_ANSI;
						else
							curuser.Userbits &= ~USERF_ANSI;
						break;

					case GD_clearscreen:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_ClearScreen;
						else
							curuser.Userbits &= ~USERF_ClearScreen;
						break;

					case GD_raw:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_RAW;
						else
							curuser.Userbits &= ~USERF_RAW;
						break;

					case GD_filter:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_Filter;
						else
							curuser.Userbits &= ~USERF_Filter;
						break;

					case GD_sendbulletins:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							curuser.Userbits |= USERF_SendBulletins;
						else
							curuser.Userbits &= ~USERF_SendBulletins;
						break;
				}
				break;
		}
	}

	return (running);
}

int setupconflistview (void)
{
	static struct coNode *nodes;
	int	n;

	numconfs = Mainmem->config.ActiveConf;
	if (!(nodes = AllocVec (numconfs * (sizeof (struct coNode)), MEMF_CLEAR)))
		return (0);

	if (conflist)
		FreeVec (conflist);
	conflist = nodes;

	NewList (&conflistheader);

	for (n = 0; n < numconfs; n++) {
		nodes[n].node.ln_Name = (char *) &nodes[n].text;
		sprintf (nodes[n].text,"        -%s",
			Mainmem->config.ConfNames[Mainmem->config.ConfOrder[n]-1]);
		AddTail (&conflistheader,&nodes[n].node);
	}

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_conference_listview],
		ABBSUserEditorWnd,NULL,GTLV_Labels,&conflistheader,TAG_DONE,0);

	return (1);
}

int setuplistview(void)
{
	static struct ueNode {
		struct Node node;
		NameT	name;
	} *nodes;
	int	n,num;
	struct Log_entry *logs;

	num = Mainmem->config.Users;
	if (!(nodes = AllocVec (num * (sizeof (struct ueNode)), MEMF_CLEAR)))
		return (0);

	if (list)
		FreeVec (list);
	list = nodes;

	logs = (struct Log_entry *) Mainmem->LogTabelladr;
	NewList (&listheader);

	Forbid();

	for (n = 0; n < num; n++) {
		nodes[n].node.ln_Name = (char *) &nodes[n].name;
		strcpy (nodes[n].name,(char *) logs[n].l_Name);
		AddTail (&listheader,&nodes[n].node);
	}
	Permit();

	GT_SetGadgetAttrs (ABBSUserEditorGadgets[GD_Users_ListView],
		ABBSUserEditorWnd,NULL,GTLV_Labels,&listheader,TAG_DONE,0);

	return (1);
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

int Setup (void)
{
	int	ret = 0;

	if (FindPort (MainPortName)) {
		if (IntuitionBase = (struct IntuitionBase *) OpenLibrary("intuition.library",37)) {
			if (GfxBase = (struct GfxBase *) OpenLibrary("graphics.library",36L)) {
				if (DiskfontBase = (struct DiskfontBase *) OpenLibrary ("diskfont.library",0L)) {
					if (GadToolsBase = OpenLibrary("gadtools.library",37)) {
						if (msg.msg.mn_ReplyPort = CreateMsgPort()) {
							if (!(SetupScreen())) {
								screenok = 1;
								if (!(OpenABBSUserEditorWindow())) {
									ABBSUserEditorRender();
									windowok = 1;
									ret = 1;
								} else {
									CloseABBSUserEditorWindow();
									printf ("Error opening window\n");
								}
							} else {
								printf ("No screen\n");
							}
						} else {
							printf ("Error creating message port\n");
						}
					} else {
						printf ("No gadtools lib\n");
					}
				} else {
					printf ("No diskfont lib\n");
				}
			} else {
				printf ("No gfx lib\n");
			}
		} else {
			printf ("No intuition lib\n");
		}
	} else {
		printf ("ABBS must be running for Usereditor to work\n");
	}

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (windowok) CloseABBSUserEditorWindow();
	if (screenok) CloseDownScreen();
	if (conflist) FreeVec (conflist);
	if (list) FreeVec (list);
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
	if (GadToolsBase)	CloseLibrary (GadToolsBase);
	if (DiskfontBase) CloseLibrary((struct Library *) DiskfontBase);
	if (GfxBase) CloseLibrary((struct Library *) GfxBase);
	if (IntuitionBase) CloseLibrary ((struct Library *) IntuitionBase);
}
