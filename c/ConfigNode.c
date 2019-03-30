/***************************************************************************
*									ConfigNode 2.2 (24/09-93)
*
*	Configures node config files
*
*	2.2: Fikset bug med dironly i load/save etter at man valgte en tmpdir/holddir
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>
#include <dos/rdargs.h>
#include <dos/exall.h>
#include <libraries/gadtools.h>
#include <intuition/gadgetclass.h>
#include <libraries/asl.h>
#include <dos/rdargs.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/asl.h>
#include <proto/intuition.h>
#include <proto/gadtools.h>

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>

#include "ConfigNodegui.h"
#include "ConfigNodegui.c"

int	main(int argc, char **argv);
int	Setup (void);
void	Cleanup (void);
BOOL	handleidcmp(void);
void	handlemaxidcmp(void);
void	handlebetidcmp(void);
void	disable (int num,...);
void	enable (int num,...);
void	updatebetweengadgets(void);
void	updatemaxtimegadgets(void);
void	updatemaingadgets(void);
void	updateghosting (int nodetypeval);
void	converttocformat (char *dest,char *source);
void	convertfromcformat (char *dest,char *source);

char *vers = "\0$VER: ConfigNode 2.2 (29.1.94)\n\r";	/* day,month,year */

extern struct Window         *ConfignodeWnd;
extern struct Menu           *ConfignodeMenus;
extern struct Gadget         *ConfignodeGadgets[37];
extern struct Gadget         *Max_loginGadgets[25];
extern struct Gadget         *Time_betweenGadgets[25];
extern struct Window         *Max_loginWnd;
extern struct Window         *Time_betweenWnd;

struct IntuitionBase *IntuitionBase = NULL;
struct GfxBase *GfxBase = NULL;
struct DiskfontBase *DiskfontBase = NULL;
struct Library *GadToolsBase = NULL;
struct Library *AslBase = NULL;

struct FileRequester *freq = NULL;
struct FontRequester *fontreq = NULL;
struct IntuiMessage	tmpmsg;
char	screenok = 0;
char	windowok = 0;
char	between = 0;
char	maxtime = 0;
int	waitsigs = 0;

int	comport = 0;

struct NodeRecord noderecord = {
	0,1,30,NodeSetupF_UseABBScreen,300,SETUPF_RTSCTS|SETUPF_Lockedbaud,38400,"serial.device",
	"ATZ","ATA","ATH1","ATH0","ATDT","RING","CONNECT","OK","AT","NO CARRIER",0,
	60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	"","ABBS:Hold/node1","T:Node1tmpdir","topaz.font",8,
	0,11,244,640,0,11},noderecordback;

struct EasyStruct aboutereq = {
	sizeof (struct EasyStruct),0,
	"ConfigNode Info",
	"Confignode v2.2.\nDesign by Andreas Dobloug.\nProgrammed by Geir Inge Høsteng.\n(c) 1993",
	"I know"
},quitreq = {
	sizeof (struct EasyStruct),0,
	"Want to quit ?",
	"Config not saved.\nSure you want to quit ?",
	"Yes|No"
},loadreq = {
	sizeof (struct EasyStruct),0,
	"Want to Load ?",
	"Config not saved.\nSure you want to load ?",
	"Yes|No"
},saveerrorreq = {
	sizeof (struct EasyStruct),0,
	"Save Error!",
	"Error saving config!",
	"I know"
},loaderrorreq = {
	sizeof (struct EasyStruct),0,
	"Load Error!",
	"Error loading config!",
	"I know"
};

#define TEMPLATE "FILE"
#define OPT_COUNT 1

int main(int argc, char **argv)
{
	int	quit = 0;
	int	gotsigs,tmpval;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0};
	BPTR	file;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			waitsigs = ((1L << ConfignodeWnd->UserPort->mp_SigBit) | SIGBREAKF_CTRL_C);

			if (result[0]) {
				memcpy (&noderecordback,&noderecord,sizeof (struct NodeRecord));
				if (file = Open ((char *) result[0],MODE_OLDFILE)) {
					tmpval =  Read (file,&noderecord,sizeof (struct NodeRecord));
					if (sizeof (struct NodeRecord) != tmpval) {
						EasyRequestArgs(ConfignodeWnd,&loaderrorreq,NULL,NULL);
						if (tmpval != 272)	/* 272 er gammel size, skal være kompatibel.. */
							memcpy (&noderecord,&noderecordback,sizeof (struct NodeRecord));
						else {
							noderecord.NodeRecord_pad = 0;
							noderecord.NodeSetup &= NodeSetupF_TinyMode;
							noderecord.MinBaud = 0;
						}
					} else
						memcpy (&noderecordback,&noderecord,sizeof (struct NodeRecord));
					Close (file);

					comport = (noderecord.CommsPort ? noderecord.CommsPort - 1 : 0);
				}
			}

			updatemaingadgets();
			memcpy (&noderecordback,&noderecord,sizeof (struct NodeRecord));

			while	(!quit) {
				gotsigs = Wait (waitsigs);

				quit = (!(handleidcmp()));

				handlemaxidcmp();
				handlebetidcmp();

				if (gotsigs & SIGBREAKF_CTRL_C)
					quit = 1;
			}

			Cleanup();
		}

		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);
}

void disable (int num,...)
{
	va_list			ap;
	struct Gadget	*gad;

	va_start(ap,num);

	for ( ; num; num--) {
		gad = va_arg (ap,struct Gadget *);
		GT_SetGadgetAttrs (gad,ConfignodeWnd,NULL,GA_Disabled,TRUE,TAG_END);
	}
}

void enable (int num,...)
{
	va_list			ap;
	struct Gadget	*gad;

	va_start(ap,num);

	for ( ; num; num--) {
		gad = va_arg (ap,struct Gadget *);
		GT_SetGadgetAttrs (gad,ConfignodeWnd,NULL,GA_Disabled,FALSE,TAG_END);
	}
}

void handlemaxidcmp(void)
{
	struct IntuiMessage	*m;
	int	nr;
	UBYTE	index[24] = {19,20,21,22,23,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18};

	if (!Max_loginWnd)
		return;

	while (m = GT_GetIMsg (Max_loginWnd->UserPort)) {
		CopyMem ((char *) m, (char *) &tmpmsg, (long) sizeof(struct IntuiMessage));
		GT_ReplyIMsg(m);

		switch (tmpmsg.Class) {
			case	IDCMP_REFRESHWINDOW:
				GT_BeginRefresh (Max_loginWnd);
				Max_loginRender();
				GT_EndRefresh (Max_loginWnd,TRUE);
				break;

			case	IDCMP_CLOSEWINDOW:
				waitsigs &= ~(1L << Max_loginWnd->UserPort->mp_SigBit);
				CloseMax_loginWindow ();
				maxtime = 0;
				break;

			case	IDCMP_GADGETUP:
				switch (nr = ((struct Gadget *) tmpmsg.IAddress)->GadgetID) {
					case GD_Max_time_read_gadgets:
						waitsigs &= ~(1L << Max_loginWnd->UserPort->mp_SigBit);
						CloseMax_loginWindow ();
						maxtime = 0;
						break;

					default:
						noderecord.HourMaxTime[index[nr]] = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.HourMaxTime[index[nr]] > 60) {
							DisplayBeep (NULL);
							noderecord.HourMaxTime[index[nr]] = 60;
							GT_SetGadgetAttrs ((struct Gadget *) tmpmsg.IAddress,
							Max_loginWnd,NULL,GTIN_Number,60,TAG_END);
						}
						break;

				}
				break;
		}
		if (!Max_loginWnd)
			break;
	}

	return;
}

void handlebetidcmp(void)
{
	struct IntuiMessage	*m;
	int	nr;
	UBYTE	index[24] = {19,20,21,22,23,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18};

	if (!Time_betweenWnd)
		return;

	while (m = GT_GetIMsg (Time_betweenWnd->UserPort)) {

		CopyMem ((char *) m, (char *) &tmpmsg, (long) sizeof(struct IntuiMessage));
		GT_ReplyIMsg(m);

		switch (tmpmsg.Class) {
			case	IDCMP_REFRESHWINDOW:
				GT_BeginRefresh (Time_betweenWnd);
				Time_betweenRender();
				GT_EndRefresh (Time_betweenWnd,TRUE);
				break;

			case	IDCMP_CLOSEWINDOW:
				waitsigs &= ~(1L << Time_betweenWnd->UserPort->mp_SigBit);
				CloseTime_betweenWindow();
				between = 0;
				break;

			case	IDCMP_GADGETUP:
				switch (nr = ((struct Gadget *) tmpmsg.IAddress)->GadgetID) {
					case GDX_Max_time_read_gadgets:
						waitsigs &= ~(1L << Time_betweenWnd->UserPort->mp_SigBit);
						CloseTime_betweenWindow();
						between = 0;
						break;

					default:
						noderecord.HourMinWait[index[nr]] = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.HourMinWait[index[nr]] > 60) {
							DisplayBeep (NULL);
							noderecord.HourMinWait[index[nr]] = 60;
							GT_SetGadgetAttrs ((struct Gadget *) tmpmsg.IAddress,
							Time_betweenWnd,NULL,GTIN_Number,60,TAG_END);
						}
						break;
				}
				break;
		}
		if (!Time_betweenWnd)
			break;
	}

	return;
}

BOOL handleidcmp(void)
{
	struct IntuiMessage	*m;
	struct MenuItem		*n;
	BOOL	running = TRUE;
	UWORD	code;
	struct Gadget *gad;
	BPTR	file;
	char	string[256],c;
	int	tmpval;

	while (m = GT_GetIMsg (ConfignodeWnd->UserPort)) {

		CopyMem ((char *) m, (char *) &tmpmsg, (long) sizeof(struct IntuiMessage));
		GT_ReplyIMsg(m);

		switch (tmpmsg.Class) {
			case	IDCMP_REFRESHWINDOW:
				GT_BeginRefresh (ConfignodeWnd);
				ConfignodeRender();
				GT_EndRefresh (ConfignodeWnd,TRUE);
				break;

			case	IDCMP_CLOSEWINDOW:
				running = FALSE;
				break;

			case	IDCMP_GADGETUP:
				switch (((struct Gadget *) tmpmsg.IAddress)->GadgetID) {
					case GD_get_font:
						if (AslRequestTags (fontreq,ASLFO_TitleText,"Node font",
								ASLFO_FixedWidthOnly,TRUE,ASLFR_Window,ConfignodeWnd,
								ASLFR_SleepWindow,TRUE,TAG_DONE)) {

							GT_SetGadgetAttrs (ConfignodeGadgets[GD_font_name],
								ConfignodeWnd,NULL,GTTX_Text,fontreq->fo_Attr.ta_Name,TAG_END);
							GT_SetGadgetAttrs (ConfignodeGadgets[GD_font_size],
								ConfignodeWnd,NULL,GTNM_Number,fontreq->fo_Attr.ta_YSize,TAG_END);

							strncpy (noderecord.Font,fontreq->fo_Attr.ta_Name,Sizeof_NameT);
							noderecord.FontSize = fontreq->fo_Attr.ta_YSize;
						}
						break;

					case GD_Holdpath:
						strncpy (noderecord.HoldPath,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							Sizeof_NameT);
						break;

					case GD_get_hold_path:
						gad = (struct Gadget *) ConfignodeGadgets[GD_Holdpath];
						if (AslRequestTags (freq,ASLFR_TitleText,"Choose hold dir",
								ASLFR_DrawersOnly,TRUE,ASLFR_RejectIcons,TRUE,
								ASLFR_InitialDrawer,((struct StringInfo *)gad->SpecialInfo)->Buffer,
								ASLFR_Window,ConfignodeWnd,ASLFR_SleepWindow,TRUE,TAG_DONE)) {

							if (freq->fr_Drawer[strlen(freq->fr_Drawer)-1] == '/')
								freq->fr_Drawer[strlen(freq->fr_Drawer)-1] = '\0';

							GT_SetGadgetAttrs (gad,ConfignodeWnd,NULL,GTST_String,freq->fr_Drawer,TAG_END);
							strncpy (noderecord.HoldPath,freq->fr_Drawer,Sizeof_NameT);
						}
						break;

					case GD_tmppath:
						strncpy (noderecord.TmpPath,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							Sizeof_NameT);
						break;

					case GD_get_tmpdir_path:
						gad = (struct Gadget *) ConfignodeGadgets[GD_tmppath];
						if (AslRequestTags (freq,ASLFR_TitleText,"Choose tmp dir",
								ASLFR_DrawersOnly,TRUE,ASLFR_RejectIcons,TRUE,
								ASLFR_InitialDrawer,((struct StringInfo *)gad->SpecialInfo)->Buffer,
								ASLFR_Window,ConfignodeWnd,ASLFR_SleepWindow,TRUE,TAG_DONE)) {

							if (freq->fr_Drawer[strlen(freq->fr_Drawer)-1] == '/')
								freq->fr_Drawer[strlen(freq->fr_Drawer)-1] = '\0';

							GT_SetGadgetAttrs (gad,ConfignodeWnd,NULL,GTST_String,freq->fr_Drawer,TAG_END);
							strncpy (noderecord.TmpPath,freq->fr_Drawer,Sizeof_NameT);
						}
						break;

					case GD_Nodetype:
						updateghosting (m->Code);
						switch (m->Code) {
							case 0:		/* Serial */
								noderecord.CommsPort = comport + 1;
								noderecord.Setup &= ~(SETUPF_Lockedbaud|SETUPF_NullModem);
								break;

							case 1:		/* local	*/
								noderecord.CommsPort = 0;
								noderecord.Setup &= ~SETUPF_Lockedbaud;
								break;

							case 2:		/* NullModem */
								noderecord.CommsPort = comport + 1;
								noderecord.Setup |= SETUPF_Lockedbaud | SETUPF_NullModem;
								break;
						}
						break;

					case GD_screenmode:
						switch (m->Code) {
							case 2:
								enable (1,ConfignodeGadgets[GDX_publicscren]);
								noderecord.NodeSetup &= ~NodeSetupF_UseABBScreen;
								break;

							default:
								disable (1,ConfignodeGadgets[GDX_publicscren]);
								if (m->Code == 1)
									noderecord.NodeSetup |= NodeSetupF_UseABBScreen;
								else {
									*noderecord.PublicScreenName = 0;
									noderecord.NodeSetup &= ~NodeSetupF_UseABBScreen;
								}
								break;
						}
						break;

					case GD_node_type:
						switch (m->Code) {
							case 0:	/* Backdrop */
								disable (4,
									ConfignodeGadgets[GDX_Window_x],
									ConfignodeGadgets[GDX_Window_y],
									ConfignodeGadgets[GDX_Window_height],
									ConfignodeGadgets[GDX_Window_width]);
								noderecord.NodeSetup &= ~NodeSetupF_TinyMode;
								noderecord.NodeSetup |= NodeSetupF_BackDrop;
								break;

							case 1:	/* Tiny */
								enable (2,
									ConfignodeGadgets[GDX_Window_x],
									ConfignodeGadgets[GDX_Window_y]);
								disable (2,
									ConfignodeGadgets[GDX_Window_height],
									ConfignodeGadgets[GDX_Window_width]);

								GT_SetGadgetAttrs (ConfignodeGadgets[GD_Window_x],ConfignodeWnd,
										NULL,GTIN_Number,noderecord.win_tiny_x,TAG_END);
								GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_y],ConfignodeWnd,
										NULL,GTIN_Number,noderecord.win_tiny_y,TAG_END);
								noderecord.NodeSetup &= ~NodeSetupF_BackDrop;
								noderecord.NodeSetup |= NodeSetupF_TinyMode;
								break;

							case 2:	/* Normal */
								enable (4,
									ConfignodeGadgets[GDX_Window_x],
									ConfignodeGadgets[GDX_Window_y],
									ConfignodeGadgets[GDX_Window_height],
									ConfignodeGadgets[GDX_Window_width]);

								GT_SetGadgetAttrs (ConfignodeGadgets[GD_Window_x],ConfignodeWnd,
										NULL,GTIN_Number,noderecord.win_big_x,TAG_END);
								GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_y],ConfignodeWnd,
										NULL,GTIN_Number,noderecord.win_big_y,TAG_END);

								noderecord.NodeSetup &=
										~(NodeSetupF_TinyMode|NodeSetupF_BackDrop);

								break;
						}
						break;

					case GD_Min_between_login:
						if (Time_betweenWnd)
							break;
						if (!(OpenTime_betweenWindow())) {
							Time_betweenRender();
							updatebetweengadgets();
							waitsigs |= (1L << Time_betweenWnd->UserPort->mp_SigBit);
							between = 1;
						}
						break;

					case GD_Max_login_time:
						if (Max_loginWnd)
							break;
						if (!(OpenMax_loginWindow())) {
							Max_loginRender();
							updatemaxtimegadgets();
							waitsigs |= (1L << Max_loginWnd->UserPort->mp_SigBit);
							maxtime = 1;
						}
						break;

					case GD_Modem_Init:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemStrT));
						convertfromcformat (noderecord.ModemInitString,string);
						break;

					case GD_Modem_on_hook:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemOnHookString,string);
						break;

					case GD_Modem_off_hook:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemOffHookString,string);
						break;

					case GD_Modem_answer:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemAnswerString,string);
						break;

					case GD_Modem_dial:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemCallString,string);
						break;

					case GD_Modem_ring:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemRingString,string);
						break;

					case GD_Modem_connect:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemConnectString,string);
						break;

					case GD_Modem_no_carrier:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemNoCarrierString,string);
						break;

					case GD_Modem_at_string:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemATString,string);
						break;

					case GD_modem_ok_string:
						strncpy (string,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemSStrT));
						convertfromcformat (noderecord.ModemOKString,string);
						break;

					case GD_Connect_wait:
						noderecord.ConnectWait = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.ConnectWait < 10) {
							DisplayBeep (NULL);
							noderecord.ConnectWait = 10;
							GT_SetGadgetAttrs ((struct Gadget *) tmpmsg.IAddress,
							ConfignodeWnd,NULL,GTIN_Number,10,TAG_END);
						}
						break;

					case GD_Minimum_baud:
						noderecord.MinBaud = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.MinBaud < 300) {
							DisplayBeep (NULL);
							noderecord.MinBaud = 300;
							GT_SetGadgetAttrs ((struct Gadget *) tmpmsg.IAddress,
							ConfignodeWnd,NULL,GTIN_Number,300,TAG_END);
						}
						break;

					case GD_Modem_machine_baud:
						noderecord.NodeBaud = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.NodeBaud < 300) {
							DisplayBeep (NULL);
							noderecord.NodeBaud = 300;
							GT_SetGadgetAttrs ((struct Gadget *) tmpmsg.IAddress,
							ConfignodeWnd,NULL,GTIN_Number,300,TAG_END);
						}
						break;

					case GD_Comm_port_name:
						strncpy (noderecord.Serialdevicename,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (ModemStrT));
						break;

					case GD_Comm_port:
						comport = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						noderecord.CommsPort = comport + 1;
						break;

					case GD_CTS_RTS:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							noderecord.Setup |= SETUPF_RTSCTS;
						else
							noderecord.Setup &= ~SETUPF_RTSCTS;
						break;

					case GD_NoSleep:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							noderecord.Setup |= SETUPF_NoSleepTime;
						else
							noderecord.Setup &= ~SETUPF_NoSleepTime;
						break;

					case GD_Locked_baud_rate:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							noderecord.Setup |= SETUPF_Lockedbaud;
						else
							noderecord.Setup &= ~SETUPF_Lockedbaud;
						break;

					case GD_Open_at_Startup:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							noderecord.NodeSetup &= ~NodeSetupF_DontShow;
						else
							noderecord.NodeSetup |= NodeSetupF_DontShow;
						break;

					case GD_Hangup_mode:
						if (((struct Gadget *) tmpmsg.IAddress)->Flags & GFLG_SELECTED)
							noderecord.Setup |= SETUPF_SimpelHangup;
						else
							noderecord.Setup &= ~SETUPF_SimpelHangup;
						break;

					case GD_publicscren:
						strncpy (noderecord.PublicScreenName,((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->Buffer,
							sizeof (NameT));
						break;

					case GD_Window_x:
						tmpval = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.NodeSetup & NodeSetupF_TinyMode)
							noderecord.win_tiny_x = tmpval;
						else
							noderecord.win_big_x = tmpval;
						break;

					case GD_Window_y:
						tmpval = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;

						if (noderecord.NodeSetup & NodeSetupF_TinyMode)
							noderecord.win_tiny_y = tmpval;
						else
							noderecord.win_big_y = tmpval;
						break;

					case GD_Window_height:
						noderecord.win_big_height = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

					case GD_Window_width:
						 noderecord.win_big_width = ((struct StringInfo *)
							((struct Gadget *) tmpmsg.IAddress)->SpecialInfo)->LongInt;
						break;

				}
				break;

			case	IDCMP_MENUPICK:
				code = tmpmsg.Code;
				while (code != MENUNULL) {
					switch (MENUNUM(code)) {
						case 0:
							switch (ITEMNUM(code)) {
								case 0:	/* About */
									EasyRequestArgs(ConfignodeWnd,&aboutereq,NULL,NULL);
									break;

								case 2:	/* Open */
									if (memcmp (&noderecordback,&noderecord,sizeof (struct NodeRecord)))
										if (1 != EasyRequestArgs(ConfignodeWnd,&loadreq,NULL,NULL))
											break;

									if (AslRequestTags (freq,ASLFR_TitleText,"Load Config",
										ASLFR_DrawersOnly,FALSE,
										ASLFR_InitialDrawer,"ABBS:config/",
										ASLFR_InitialPattern,"#?.config",
										ASLFR_RejectIcons,TRUE,ASLFR_Window,ConfignodeWnd,
										ASLFR_SleepWindow,TRUE,TAG_DONE)) {

										c = freq->fr_Drawer[strlen(freq->fr_Drawer)-1];
										if (c == ':' || c == '/')
											sprintf (string,"%s%s",freq->fr_Drawer,freq->fr_File);
										else
											sprintf (string,"%s/%s",freq->fr_Drawer,freq->fr_File);
										if (file = Open (string,MODE_OLDFILE)) {

											tmpval =  Read (file,&noderecord,sizeof (struct NodeRecord));
											if (sizeof (struct NodeRecord) != tmpval) {
												EasyRequestArgs(ConfignodeWnd,&loaderrorreq,NULL,NULL);
												if (tmpval != 272)	/* 272 er gammel size, skal være kompatibel.. */
													memcpy (&noderecord,&noderecordback,sizeof (struct NodeRecord));
												else {
													noderecord.NodeRecord_pad = 0;
													noderecord.NodeSetup &= NodeSetupF_TinyMode;
													noderecord.MinBaud = 0;
												}
											} else
												memcpy (&noderecordback,&noderecord,sizeof (struct NodeRecord));
											Close (file);

											comport = (noderecord.CommsPort ? noderecord.CommsPort - 1 : 0);
											updatemaingadgets();
											updatebetweengadgets();
											updatemaxtimegadgets();
										}
									}
									break;

								case 3:	/* Save */
									if (AslRequestTags (freq,ASLFR_TitleText,"Save Config",
										ASLFR_DrawersOnly,FALSE,
										ASLFR_InitialDrawer,"ABBS:config/",
										ASLFR_InitialPattern,"#?.config",
										ASLFR_RejectIcons,TRUE,ASLFR_Window,ConfignodeWnd,
										ASLFR_SleepWindow,TRUE,TAG_DONE)) {

										c = freq->fr_Drawer[strlen(freq->fr_Drawer)-1];
										if (c == ':' || c == '/')
											sprintf (string,"%s%s",freq->fr_Drawer,freq->fr_File);
										else
											sprintf (string,"%s/%s",freq->fr_Drawer,freq->fr_File);
										if (file = Open (string,MODE_NEWFILE)) {
											if (sizeof (struct NodeRecord) != Write (file,
													&noderecord,sizeof (struct NodeRecord)))
												EasyRequestArgs(ConfignodeWnd,&saveerrorreq,NULL,NULL);
											else
												memcpy (&noderecordback,&noderecord,sizeof (struct NodeRecord));

											Close (file);
										}
									}
									break;

								case 5:	/* Quit */
									if (memcmp (&noderecordback,&noderecord,sizeof (struct NodeRecord))) {
										if (1 == EasyRequestArgs(ConfignodeWnd,&quitreq,NULL,NULL))
											running = FALSE;
									} else
										running = FALSE;
									break;
							}
							break;
					}

					n = ItemAddress(ConfignodeMenus,code);
					code = n->NextSelect;
				}
				break;
		}
	}

	return (running);
}

void updatemaingadgets(void)
{
	int	n;
	char	string[80];

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Holdpath],ConfignodeWnd,
		NULL,GTST_String,noderecord.HoldPath,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_tmppath],ConfignodeWnd,
		NULL,GTST_String,noderecord.TmpPath,TAG_END);

	converttocformat (string,noderecord.ModemInitString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_Init],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemOnHookString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_on_hook],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemOffHookString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_off_hook],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemAnswerString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_answer],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemCallString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_dial],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemRingString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_ring],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemConnectString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_connect],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemNoCarrierString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_no_carrier],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemATString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_at_string],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	converttocformat (string,noderecord.ModemOKString);
	GT_SetGadgetAttrs (ConfignodeGadgets[GD_modem_ok_string],ConfignodeWnd,
		NULL,GTST_String,string,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Comm_port_name],ConfignodeWnd,
		NULL,GTST_String,noderecord.Serialdevicename,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_publicscren],ConfignodeWnd,
		NULL,GTST_String,noderecord.PublicScreenName,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_font_name],ConfignodeWnd,
		NULL,GTTX_Text,noderecord.Font,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_font_size],ConfignodeWnd,
		NULL,GTNM_Number,noderecord.FontSize,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Comm_port],ConfignodeWnd,
		NULL,GTIN_Number,(noderecord.CommsPort ? noderecord.CommsPort-1 : 0),TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Minimum_baud],ConfignodeWnd,
		NULL,GTIN_Number,noderecord.MinBaud,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Connect_wait],ConfignodeWnd,
		NULL,GTIN_Number,noderecord.ConnectWait,TAG_END);

	GT_SetGadgetAttrs (ConfignodeGadgets[GD_Modem_machine_baud],ConfignodeWnd,
		NULL,GTIN_Number,noderecord.NodeBaud,TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_height],ConfignodeWnd,
		NULL,GTIN_Number,noderecord.win_big_height,TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_width],ConfignodeWnd,
		NULL,GTIN_Number,noderecord.win_big_width,TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Locked_baud_rate],ConfignodeWnd,
		NULL,GTCB_Checked,(noderecord.Setup & SETUPF_Lockedbaud ? TRUE : FALSE),TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Open_at_Startup],ConfignodeWnd,
		NULL,GTCB_Checked,(noderecord.NodeSetup & NodeSetupF_DontShow ? FALSE : TRUE),TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_CTS_RTS],ConfignodeWnd,
		NULL,GTCB_Checked,(noderecord.Setup & SETUPF_RTSCTS ? TRUE : FALSE),TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_NoSleep],ConfignodeWnd,
		NULL,GTCB_Checked,(noderecord.Setup & SETUPF_NoSleepTime ? TRUE : FALSE),TAG_END);

	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Hangup_mode],ConfignodeWnd,
		NULL,GTCB_Checked,(noderecord.Setup & SETUPF_SimpelHangup ? TRUE : FALSE),TAG_END);

	if (noderecord.Setup & SETUPF_NullModem)
		n = 2;
	else {
		if (noderecord.CommsPort)
			n = 0;
		else
			n = 1;
	}
	GT_SetGadgetAttrs(ConfignodeGadgets[GD_Nodetype],ConfignodeWnd,NULL,
		GTCY_Active,n,TAG_END);
	updateghosting (n);

	if (noderecord.NodeSetup & NodeSetupF_UseABBScreen)
		n = 1;
	else if (!(*noderecord.PublicScreenName))
		n = 0;
	else
		n = 2;

	if (n == 2)
		enable (1,ConfignodeGadgets[GDX_publicscren]);
	else
		disable (1,ConfignodeGadgets[GDX_publicscren]);
	GT_SetGadgetAttrs(ConfignodeGadgets[GD_screenmode],ConfignodeWnd,NULL,
		GTCY_Active,n,TAG_END);

	if (noderecord.NodeSetup & NodeSetupF_TinyMode)
		n = 1;
	else if (noderecord.NodeSetup & NodeSetupF_BackDrop)
		n = 0;
	else
		n = 2;
	GT_SetGadgetAttrs(ConfignodeGadgets[GD_node_type],ConfignodeWnd,NULL,
		GTCY_Active,n,TAG_END);

	switch (n) {
		case 0:
			GT_SetGadgetAttrs (ConfignodeGadgets[GD_Window_x],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_big_x,TAG_END);
			GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_y],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_big_y,TAG_END);

			disable (4,ConfignodeGadgets[GDX_Window_x],
				ConfignodeGadgets[GDX_Window_y],
				ConfignodeGadgets[GDX_Window_height],
				ConfignodeGadgets[GDX_Window_width]);
			break;

		case 1:
			GT_SetGadgetAttrs (ConfignodeGadgets[GD_Window_x],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_tiny_x,TAG_END);
			GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_y],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_tiny_y,TAG_END);

			enable (2,
				ConfignodeGadgets[GDX_Window_x],
				ConfignodeGadgets[GDX_Window_y]);
			disable (2,
				ConfignodeGadgets[GDX_Window_height],
				ConfignodeGadgets[GDX_Window_width]);
			break;

		case 2:
			GT_SetGadgetAttrs (ConfignodeGadgets[GD_Window_x],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_big_x,TAG_END);
			GT_SetGadgetAttrs(ConfignodeGadgets[GD_Window_y],ConfignodeWnd,
				NULL,GTIN_Number,noderecord.win_big_y,TAG_END);

			enable (4,
				ConfignodeGadgets[GDX_Window_x],
				ConfignodeGadgets[GDX_Window_y],
				ConfignodeGadgets[GDX_Window_height],
				ConfignodeGadgets[GDX_Window_width]);
			break;
	}
}

void updateghosting (int nodetypeval)
{
	switch (nodetypeval) {
		case 0:		/* Serial */
			enable (20,
				ConfignodeGadgets[GDX_Modem_Init],
				ConfignodeGadgets[GDX_Modem_on_hook],
				ConfignodeGadgets[GDX_Modem_off_hook],
				ConfignodeGadgets[GDX_Modem_answer],
				ConfignodeGadgets[GDX_Modem_dial],
				ConfignodeGadgets[GDX_Modem_ring],
				ConfignodeGadgets[GDX_Modem_connect],
				ConfignodeGadgets[GDX_Modem_no_carrier],
				ConfignodeGadgets[GDX_Modem_at_string],
				ConfignodeGadgets[GDX_modem_ok_string],
				ConfignodeGadgets[GDX_Minimum_baud],
				ConfignodeGadgets[GDX_Connect_wait],
				ConfignodeGadgets[GDX_Modem_machine_baud],
				ConfignodeGadgets[GDX_Locked_baud_rate],
				ConfignodeGadgets[GDX_CTS_RTS],
				ConfignodeGadgets[GDX_NoSleep],
				ConfignodeGadgets[GDX_Hangup_mode],
				ConfignodeGadgets[GDX_Comm_port_name],
				ConfignodeGadgets[GD_Min_between_login],
				ConfignodeGadgets[GD_Max_login_time],
				ConfignodeGadgets[GDX_Comm_port]);
				noderecord.CommsPort = comport + 1;
			break;

		case 1:		/* local	*/
			disable (20,
				ConfignodeGadgets[GDX_Modem_Init],
				ConfignodeGadgets[GDX_Modem_on_hook],
				ConfignodeGadgets[GDX_Modem_off_hook],
				ConfignodeGadgets[GDX_Modem_answer],
				ConfignodeGadgets[GDX_Modem_dial],
				ConfignodeGadgets[GDX_Modem_ring],
				ConfignodeGadgets[GDX_Modem_connect],
				ConfignodeGadgets[GDX_Modem_no_carrier],
				ConfignodeGadgets[GDX_Modem_at_string],
				ConfignodeGadgets[GDX_modem_ok_string],
				ConfignodeGadgets[GDX_Minimum_baud],
				ConfignodeGadgets[GDX_Connect_wait],
				ConfignodeGadgets[GDX_Modem_machine_baud],
				ConfignodeGadgets[GDX_Locked_baud_rate],
				ConfignodeGadgets[GDX_CTS_RTS],
				ConfignodeGadgets[GDX_NoSleep],
				ConfignodeGadgets[GDX_Hangup_mode],
				ConfignodeGadgets[GDX_Comm_port_name],
				ConfignodeGadgets[GD_Min_between_login],
				ConfignodeGadgets[GD_Max_login_time],
				ConfignodeGadgets[GDX_Comm_port]);
				noderecord.CommsPort = 0;
			break;

		case 2:		/* NullModem */
			enable (6,
				ConfignodeGadgets[GDX_Modem_machine_baud],
				ConfignodeGadgets[GDX_Locked_baud_rate],
				ConfignodeGadgets[GDX_CTS_RTS],
				ConfignodeGadgets[GDX_Hangup_mode],
				ConfignodeGadgets[GDX_Comm_port_name],
				ConfignodeGadgets[GDX_Comm_port]);

			disable (14,
				ConfignodeGadgets[GDX_Modem_Init],
				ConfignodeGadgets[GDX_Modem_on_hook],
				ConfignodeGadgets[GDX_Modem_off_hook],
				ConfignodeGadgets[GDX_Modem_answer],
				ConfignodeGadgets[GDX_Modem_dial],
				ConfignodeGadgets[GDX_Modem_ring],
				ConfignodeGadgets[GDX_Modem_connect],
				ConfignodeGadgets[GDX_Modem_no_carrier],
				ConfignodeGadgets[GDX_Modem_at_string],
				ConfignodeGadgets[GDX_modem_ok_string],
				ConfignodeGadgets[GDX_Minimum_baud],
				ConfignodeGadgets[GDX_Connect_wait],
				ConfignodeGadgets[GDX_NoSleep],
				ConfignodeGadgets[GD_Min_between_login],
				ConfignodeGadgets[GD_Max_login_time]);
				noderecord.CommsPort = comport + 1;
			break;
	}
}

void updatebetweengadgets(void)
{
	int	n;
	UBYTE	deindex[24] = {GD_b1,GD_b2,GD_b3,GD_b4,GD_b5,GD_b6,GD_b7,GD_b8,
		GD_b9,GD_b10,GD_b11,GD_b12,GD_b13,GD_b14,GD_b15,GD_b16,GD_b17,GD_b18,
		GD_b19,GD_b20,GD_b21,GD_b22,GD_b23,GD_b24};

	if (!Time_betweenWnd)
		return;

	for (n = 0; n < 24; n++)
		GT_SetGadgetAttrs (Time_betweenGadgets[deindex[n]],Time_betweenWnd,
			NULL,GTIN_Number,noderecord.HourMinWait[n],TAG_END);
}

void updatemaxtimegadgets(void)
{
	int	n;
	UBYTE	deindex[24] = {GD_m1,GD_m2,GD_m3,GD_m4,GD_m5,GD_m6,GD_m7,GD_m8,
		GD_m9,GD_m10,GD_m11,GD_m12,GD_m13,GD_m14,GD_m15,GD_m16,GD_m17,GD_m18,
		GD_m19,GD_m20,GD_m21,GD_m22,GD_m23,GD_m24};

	if (!Max_loginWnd)
		return;

	for (n = 0; n < 24; n++)
		GT_SetGadgetAttrs (Max_loginGadgets[deindex[n]],Max_loginWnd,
			NULL,GTIN_Number,noderecord.HourMaxTime[n],TAG_END);
}

void converttocformat (char *dest,char *source)
{
	char	c;

	while (c = *(source++))
		switch (c) {
			case '\n':
				*(dest++) = '\\';
				*(dest++) = 'n';
				break;

			case '\r':
				*(dest++) = '\\';
				*(dest++) = 'r';
				break;

			default:
				*(dest++) = c;
				break;
		}
	*dest = '\0';
}

void convertfromcformat (char *dest,char *source)
{
	char	c;

	while (c = *(source++)) {
		if (c == '\\') {
			if (c = *(source++)) {
				switch (c) {
					case '\\':
						*(dest++) = c;
						break;

					case 'r':
					case 'R':
						*(dest++) = '\r';
						break;

					case 'n':
					case 'N':
						*(dest++) = '\n';
						break;

					default:
						*(dest++) = '\\';
						*(dest++) = c;
						break;
				}
			} else {
				*(dest++) = '\\';
				break;
			}
		} else
			*(dest++) = c;
	}
	*dest = '\0';
}

int Setup (void)
{
	int	ret = 0;

	if (IntuitionBase = (struct IntuitionBase *) OpenLibrary("intuition.library",37))
	{
		if (GfxBase = (struct GfxBase *) OpenLibrary("graphics.library",36L))
		{
			if (DiskfontBase = (struct DiskfontBase *) OpenLibrary ("diskfont.library",0L))
			{
				if (GadToolsBase = OpenLibrary("gadtools.library",37))
				{
					if (AslBase = OpenLibrary("asl.library",37))
					{
						if (freq = AllocAslRequest (ASL_FileRequest,NULL))
						{
							if (fontreq = AllocAslRequest (ASL_FontRequest,NULL))
							{
								if (!(SetupScreen()))
								{
									screenok = 1;
									if (!(OpenConfignodeWindow()))
									{
										windowok = 1;
										ret = 1;
									}
									else
									{
										CloseConfignodeWindow();
										printf ("Error opening window\n");
									}
								}
								else
									printf ("No screen\n");
							}
							else
								printf ("No asl font req\n");
						}
						else
							printf ("No asl file req\n");
					}
					else
						printf ("No asl lib\n");
				}
				else
					printf ("No gadtools lib\n");
			}
			else
				printf ("No diskfont lib\n");
		}
		else
			printf ("No gfx lib\n");
	}
	else
		printf ("No intuition lib\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (maxtime) CloseMax_loginWindow();
	if (between) CloseTime_betweenWindow();
	if (windowok) CloseConfignodeWindow();
	if (screenok) CloseDownScreen();
	if (fontreq) FreeAslRequest(fontreq);
	if (freq) FreeAslRequest(freq);
	if (AslBase) CloseLibrary (AslBase);
	if (GadToolsBase)	CloseLibrary (GadToolsBase);
	if (DiskfontBase) CloseLibrary((struct Library *) DiskfontBase);
	if (GfxBase) CloseLibrary((struct Library *) GfxBase);
	if (IntuitionBase) CloseLibrary ((struct Library *) IntuitionBase);
}
