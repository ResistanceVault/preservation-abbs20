char *GLS (struct LocText *loctext);

typedef struct
{
  struct List list;
} Liste_Sjef;

extern Liste_Sjef Liste_sjef;

typedef struct
{
  struct Node nd;
  UBYTE Name[19];
  UBYTE Comment[37];
  ULONG flags;
} Listebase;

typedef struct
{
  struct Node nd;
  UBYTE Filename[108];
  UBYTE Comment[37];
  ULONG size;
  struct DateStamp stamp;
} Filbase;

typedef struct
{
  struct List list;
} fib_Sjef;

extern fib_Sjef fib_sjef;

extern UBYTE selected;
extern struct ConfigRecord *config;
extern struct ABBSmsg msg;
extern char *Dummy;
extern char Message[];
extern WORD filedir_order, filedir_number, filedir_view;
extern WORD file_order;
extern struct Fileentry tempfentry, fentry;
extern struct UserRecord *ur;
extern char Comment_string[];

VOID Lag_beskrivelse (VOID);
VOID Hent_filliste (VOID);

VOID Status (char *Streng);
BOOL Delete_fentry (VOID);
VOID Do_fl (char *Name);
VOID All (BOOL mode);
int HandleMsg (struct ABBSmsg *msg);
BOOL SetupFiles (VOID);
VOID Do_slash (UBYTE *Navn);
BOOL Create_dir (char *Dirname);
VOID CleanUp (VOID);
int HandleMsg (struct ABBSmsg *msg);
BOOL Setup (void);
BOOL SetupFiles (VOID);
VOID ActivateEditGD (UWORD nr);
int Load_fentry (VOID);
VOID Install_files (ULONG path);
VOID Install_preview_files (ULONG path);
VOID Save_user (VOID);
VOID Do_slash (UBYTE *Navn);
BOOL SaveFileEntry (VOID);
VOID Test_arc (VOID);
WORD CheckKey (struct Window *w, UWORD key);
VOID ErrorMsg (char *Text);
ULONG fib_read_files (UBYTE *Skuff, BOOL mode);
BOOL Find_file (UBYTE *Name);
VOID fib_Open (VOID);
VOID fib_Close (VOID);

VOID Liste_Open (VOID);
VOID Liste_Close (VOID);
BOOL FE_GetFileName (UBYTE *Dir, UBYTE *Name, UBYTE *Message, UBYTE *OkText);
VOID Hent_filliste (VOID);

extern struct LocText txt_OK;
extern struct LocText txt_MESSAGE;
extern struct LocText txt_READY;
extern struct LocText txt_PLEASE;
extern struct LocText txt_NOT_YET;
extern struct LocText txt_ERROR;
extern struct LocText txt_029;
extern struct LocText txt_030;		// Memory

// Test_arc.c
extern struct LocText txt_057;
extern struct LocText txt_058;
extern struct LocText txt_059;
extern struct LocText txt_060;
extern struct LocText txt_061;
extern struct LocText txt_062;
extern struct LocText txt_063;
extern struct LocText txt_064;
extern struct LocText txt_065;

// Install.c
extern struct LocText txt_066;
extern struct LocText txt_067;
extern struct LocText txt_068;
extern struct LocText txt_069;
extern struct LocText txt_070;
extern struct LocText txt_071;
extern struct LocText txt_072;
extern struct LocText txt_073;
extern struct LocText txt_074;
extern struct LocText txt_075;
extern struct LocText txt_076;
extern struct LocText txt_077;
extern struct LocText txt_078;
extern struct LocText txt_079;
extern struct LocText txt_080;
extern struct LocText txt_081;
extern struct LocText txt_082;
extern struct LocText txt_083;


// Diverse
extern struct LocText txt_103;
extern struct LocText txt_TESTING;

// Liste_base.c
extern struct LocText txt_124;
extern struct LocText txt_125;
extern struct LocText txt_126;
extern struct LocText txt_127;
extern struct LocText txt_128;
extern struct LocText txt_129;
extern struct LocText txt_130;
extern struct LocText txt_131;
extern struct LocText txt_132;
extern struct LocText txt_133;
extern struct LocText txt_134;
extern struct LocText txt_135;
extern struct LocText txt_137;

extern struct LocText txt_138;
