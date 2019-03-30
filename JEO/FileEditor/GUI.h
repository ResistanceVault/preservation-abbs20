/*
 *  Source machine generated by GadToolsBox V2.0b
 *  which is (c) Copyright 1991-1993 Jaba Development
 *
 *  GUI Designed by : Jan Erik Olausen
 */

#define GetString( g )      ((( struct StringInfo * )g->SpecialInfo )->Buffer  )
#define GetNumber( g )      ((( struct StringInfo * )g->SpecialInfo )->LongInt )

#define GD_LIST_1                              0
#define GD_LIST_2                              1

#define GDX_LIST_1                             0
#define GDX_LIST_2                             1

#define GD_FILE_NAME                           0
#define GD_COMMENT                             1
#define GD_FILEINFO                            2
#define GD_REMOVE_CONF                         3
#define GD_UPDATE_SIZE                         4

#define GDX_FILE_NAME                          0
#define GDX_COMMENT                            1
#define GDX_FILEINFO                           2
#define GDX_REMOVE_CONF                        3
#define GDX_UPDATE_SIZE                        4

#define FileEditor_CNT 2
#define Edit_CNT 5

extern struct IntuitionBase *IntuitionBase;
extern struct Library       *GadToolsBase;

extern struct Screen        *Scr;
extern UBYTE                 *PubScreenName;
extern APTR                  VisualInfo;
extern struct Window        *FileEditorWnd;
extern struct Window        *EditWnd;
extern struct Gadget        *FileEditorGList;
extern struct Gadget        *EditGList;
extern struct Menu          *FileEditorMenus;
extern struct Menu          *EditMenus;
extern struct Gadget        *FileEditorGadgets[2];
extern struct Gadget        *EditGadgets[5];
extern UWORD                 FileEditorLeft;
extern UWORD                 FileEditorTop;
extern UWORD                 FileEditorWidth;
extern UWORD                 FileEditorHeight;
extern UWORD                 EditLeft;
extern UWORD                 EditTop;
extern UWORD                 EditWidth;
extern UWORD                 EditHeight;
extern UBYTE                *FileEditorWdt;
extern UBYTE                *EditWdt;
extern struct TextAttr       topaz8;
extern struct NewMenu        FileEditorNewMenu[];
extern struct NewMenu        EditNewMenu[];
extern UWORD                 FileEditorGTypes[];
extern UWORD                 EditGTypes[];
extern struct NewGadget      FileEditorNGad[];
extern struct NewGadget      EditNGad[];
extern ULONG                 FileEditorGTags[];
extern ULONG                 EditGTags[];


extern int SetupScreen( void );
extern void CloseDownScreen( void );
extern int OpenFileEditorWindow( void );
extern void CloseFileEditorWindow( void );
extern void EditRender( void );
extern int OpenEditWindow( void );
extern void CloseEditWindow( void );
