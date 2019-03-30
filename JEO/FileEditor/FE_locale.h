#include <exec/types.h>

struct LocText {
  ULONG id;
  char *text;
};

#ifdef LOCALE_TEXT

#define LOCALE_START

/*
	CATALOG	 FileEditor
	VERSION  0.16d
	CATDATE  06-05-98
*/

// Fe.c
struct LocText txt_001 = { 0, "Enter user:"};
struct LocText txt_002 = { 1, "Error loading user: '%s'!\nPlease try again..."};
struct LocText txt_003 = { 2, "Ok|Quit FileEditor" };
struct LocText txt_004 = { 3,  "Error saving user: '%s'!"};
struct LocText txt_005 = { 4,  "%s - User: %s"};
struct LocText txt_OK  = { 5,  "Ok"};
struct LocText txt_MESSAGE = { 6,  "Message"};
struct LocText txt_READY = { 7,  "Ready."};
struct LocText txt_PLEASE = { 8,  "Please wait..."};
struct LocText txt_NOT_YET = { 9, "Not yet ;)" };
struct LocText txt_ERROR = { 10, "Error!"};
struct LocText txt_012 = { 11, "Sure you want to delete file '%s'?" };
struct LocText txt_DELETE_CANCEL = { 12,  "Delete|Cancel"};
struct LocText txt_014 = { 13, "Error deleting fileentry!"};
struct LocText txt_015 = { 14,  "Error writing configfile!"};
struct LocText txt_016 = { 15,  " Downloads:"};
struct LocText txt_017 = { 16,  "      Size:"};
struct LocText txt_018 = { 17,  "      Date:"};
struct LocText txt_019 = { 18,  "      From:"};
struct LocText txt_020 = { 19,  "        To:"};
struct LocText txt_021 = { 20,  "Conference:"};
struct LocText txt_022 = { 21,  "ALL"};
struct LocText txt_023 = { 22,  "N/A                           "};
struct LocText txt_024 = { 23,  "File not found:\n\n%s"};
struct LocText txt_025 = { 24,  "Delete file|Cancel"};
struct LocText txt_026 = { 25,  "Sure you want to make this file public?"};
struct LocText txt_027 = { 26,  "Make public|Cancel"};
struct LocText txt_028 = { 27,  "Error saving '%s'"};
struct LocText txt_029 = { 28,  "Error reading fileentry!\n"};
struct LocText txt_030 = { 29,  "Not enough memory!"};
struct LocText txt_031 = { 30,  "Enter directory name:"};
struct LocText txt_032 = { 31,  "Select path for: '%s'"};
struct LocText txt_033 = { 32,  "Error creating new directory!"};
struct LocText txt_034 = { 33,  "Path name too long!"};
struct LocText txt_035 = { 34,  "Illegal characters in filedir name!"};
struct LocText txt_036 = { 35,  "Enter new directory path for '%s'..."};
struct LocText txt_037 = { 36,  "Scanning dir %s..."};
struct LocText txt_038 = { 37,  "Delete file|Continue"};
struct LocText txt_039 = { 38,  "Delete file '%s'"};
struct LocText txt_040 = { 39,  "Delete|Skip file"};
struct LocText txt_041 = { 40,  "You can't delete '%s!'"};
struct LocText txt_042 = { 41,  "Sure you want to delete directory '%s'?"};
struct LocText txt_043 = { 42,  "Error deleting directory!"};
struct LocText txt_044 = { 43,  "Counting: %6ld files, %6ld (MB)..."};
struct LocText txt_045 = { 44,  "Total innstalled: %6ld files\n      Total size: %6ld (MB)"};
struct LocText txt_046 = { 45,  "File count result"};
struct LocText txt_047 = { 46,  "Please select a directory to edit."};
struct LocText txt_048 = { 47,  "Please select a directory to delete."};
struct LocText txt_049 = { 48,  "Please select a directory."};
struct LocText txt_050 = { 49,  "Please select a file to edit."};
struct LocText txt_051 = { 50,  "Please select a file to delete."};
struct LocText txt_052 = { 51,  "FileEditor needs '%s' v%ld +"};
struct LocText txt_053 = { 52,  "Error talking to ABBS!"};
struct LocText txt_054 = { 53,  "Error creating message port!"};
struct LocText txt_055 = { 54,  "Error opening utility.library!"};
struct LocText txt_056 = { 55,  "ABBS must be running for FileEditor to work!"};

// Test_arc.c
struct LocText txt_057 = { 56,  "Test LHA, LZH, ARC, DMS and GIF files for errors?"};
struct LocText txt_058 = { 57,  "New files|All files|Cancel"};
struct LocText txt_059 = { 58,  "Tested %ld %s."};
struct LocText txt_060 = { 59,  "file"};
struct LocText txt_061 = { 60,  "files"};
struct LocText txt_062 = { 61,  " Found %ld %s\n\nPlease take a look in the '%s' file."};
struct LocText txt_063 = { 62,  "error"};
struct LocText txt_064 = { 63,  "errors"};
struct LocText txt_065 = { 64,  "\n\nEverything seems to be ok."};

// Install.c
struct LocText txt_066 = { 65,  "Couldn't find C:LHA!"};
struct LocText txt_067 = { 66,  "Couldn't find C:LZX!"};
struct LocText txt_068 = { 67,  "File name too long: '%s'"};
struct LocText txt_069 = { 68,  "File %s allready exists!\n\nFILE ALLREADY IN ABBS:\nShort: %s\n Size: %ld\n\nNEW FILE:\nShort: %s\n Size: %ld\n\nSize differance: %ld"};
struct LocText txt_070 = { 69,  "Replace|Skip"};
struct LocText txt_071 = { 70,  "Create ABBS directory '%s'?"};
struct LocText txt_072 = { 71,  "Yes|No"};
struct LocText txt_073 = { 72,  "Found"};
struct LocText txt_074 = { 73,  "Not found"};
struct LocText txt_075 = { 74,  "Install this file to directory"};
struct LocText txt_076 = { 75,  "Install|"};
struct LocText txt_077 = { 76,  "Move this file to directory"};
struct LocText txt_078 = { 77,  "Move|"};
struct LocText txt_079 = { 78,  "%s '%s'?\n\n        Name: %s\n        Size: %s bytes\n%s Readme file: %s"};
struct LocText txt_080 = { 79,  "AUTO INSTALL|Skip file|Cancel"};
struct LocText txt_081 = { 80,  "Error creating/locking directory:\n%s"};
struct LocText txt_082 = { 81,  "Enter file description for '%s'..."};
struct LocText txt_083 = { 82,  "No new files found in directory '%s'."};

// GUI.c
struct LocText txt_084 = { 83,  "Edit file... <Esc> to cancel"};
struct LocText txt_085 = { 84,  "Project"};
struct LocText txt_086 = { 85,  "About"};
struct LocText txt_087 = { 86,  "Quit"};
struct LocText txt_088 = { 87,  "Directories"};
struct LocText txt_089 = { 88,  "New"};
struct LocText txt_090 = { 89,  "Change name"};
struct LocText txt_091 = { 90,  "Change path"};
struct LocText txt_092 = { 91,  "Delete"};
struct LocText txt_093 = { 92,  "Update"};
struct LocText txt_094 = { 93,  "File"};
struct LocText txt_095 = { 94,  "Auto install"};
struct LocText txt_096 = { 95,  "Edit"};
struct LocText txt_097 = { 96,  "Update file sizes"};
struct LocText txt_098 = { 97,  "Count files"};
struct LocText txt_099 = { 98,  "File comments"};
struct LocText txt_100 = { 99,  "Load new file-list"};
struct LocText txt_101 = {100,  "Make comments"};
struct LocText txt_102 = {101,  "Checking"};
struct LocText txt_103 = {102,  "Test archives"};
struct LocText txt_104 = {103,  "Virus check"};
struct LocText txt_105 = {104,  "Delete/move not installed files"};

// Diverse etterpå slengere
struct LocText txt_ABOUT = { 105, "About"};
struct LocText txt_TRANSLATION = { 106, "English translation by Jan Erik Olausen"};
struct LocText txt_TESTING = { 107, "Testing: %s"};
struct LocText txt_108 = { 108, "Move or delete not installed files from disk."};
struct LocText txt_109 = { 109, "Move|Delete|Cancel"};
struct LocText txt_110 = { 110, "Updated %ld file %s"};
struct LocText txt_111 = { 111,  "size"};
struct LocText txt_112 = { 112,  "sizes"};

// Edit window
struct LocText txt_113 = { 113, "Cancel"};
struct LocText txt_114 = { 114, "Name"};
struct LocText txt_115 = { 115, "Description"};
struct LocText txt_116 = { 116, "Info"};

// Gadgets and stuff
struct LocText txt_117 = { 117, "File directories"};
struct LocText txt_118 = { 118, "Files"};
struct LocText txt_119 = { 119, "File name"};
struct LocText txt_120 = { 120, "File description"};
struct LocText txt_121 = { 121, "File info"};
struct LocText txt_122 = { 122, "Remove conf"};
struct LocText txt_123 = { 123, "Update size"};

// Liste_base.c
struct LocText txt_124 = { 124, "Select file-list"};
struct LocText txt_125 = { 125, "Load"};
struct LocText txt_126 = { 126, "Loading file-list..."};
struct LocText txt_127 = { 127, "Converting file-list..."};
struct LocText txt_128 = { 128, "Error in file-list!"};
struct LocText txt_129 = { 129, "Not a text file!"};
struct LocText txt_130 = { 130, "Not a file-list!"};
struct LocText txt_131 = { 131, "Error loading!"};
struct LocText txt_132 = { 132, "Do comments from '%s'?\n(Found %ld files)"};
struct LocText txt_133 = { 133, "Scanning dir: %s"};
struct LocText txt_134 = { 134, "Updated %ld %s with new comment."};
struct LocText txt_135 = { 135, "Analyzing file-list..."};

// Diverse preview
struct LocText txt_136 = { 136, "Update preview files"};
struct LocText txt_137 = { 137, "Updated %ld preview %s."};

// Diverse igjen

struct LocText txt_138 = { 138, "Install files private to conference '%s'?"};

/*
struct LocText txt_139 = { 139, };
struct LocText txt_140 = { 140, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };
struct LocText txt_137 = { 137, };

*/

#define LOCALE_END
#endif
