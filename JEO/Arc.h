/*
 *  Source machine generated by GadToolsBox V2.0b
 *  which is (c) Copyright 1991-1993 Jaba Development
 *
 *  GUI Designed by : Jan Erik Olausen
 */

#define GetString( g )      ((( struct StringInfo * )g->SpecialInfo )->Buffer  )
#define GetNumber( g )      ((( struct StringInfo * )g->SpecialInfo )->LongInt )

#define GD_Format                              0

#define GDX_Format                             0

#define Arc_CNT 1

extern struct IntuitionBase *IntuitionBase;
extern struct Library       *GadToolsBase;

extern struct Screen        *Scr;
extern UBYTE                 *PubScreenName;
extern APTR                  VisualInfo;
extern struct Window        *ArcWnd;
extern struct Gadget        *ArcGList;
extern struct Gadget        *ArcGadgets[1];
extern UWORD                 ArcLeft;
extern UWORD                 ArcTop;
extern UWORD                 ArcWidth;
extern UWORD                 ArcHeight;
extern UBYTE                *ArcWdt;
extern struct TextAttr       topaz8;
extern UWORD                 ArcGTypes[];
extern struct NewGadget      ArcNGad[];
extern ULONG                 ArcGTags[];


extern int SetupScreen( void );
extern void CloseDownScreen( void );
extern int OpenArcWindow( void );
extern void CloseArcWindow( void );
