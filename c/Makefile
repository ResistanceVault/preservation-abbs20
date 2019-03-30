#
# SAS smake makefile, for SAS C V6.0
#

CFLAGS		= noversion nomultipleincludes parameters=register stringmerge structequivalence incdirectory=include: incdir=dabbs:include/ debug=full #optimize
LIBS		= lib:sc.lib lib:amiga.lib
STARTUP		= lib:c.o

NetTestObjs = NetTest.o

AddMsgObjs = AddMsg.o

KillMsgObjs = KillMsg.o

CryptPasswordsObjs = CryptPasswords.o

FindUnreadObjs = FindUnread.o

FixIndexObjs = FixIndex.o

CheckIndexObjs = CheckIndex.o

AddFileObjs = AddFile.o

QWKObjs = QWK.o

ConvertConfigObjs = ConvertConfig.o

ShowuserfileObjs = Showuserfile.o

ConfigNodeObjs = ConfigNode.o ConfigNodegui.o Boopsi.o

UserEditorObjs = UserEditor.o UserEditorgui.o

FrontDoorObjs = FrontDoor.o

FrontTestObjs = FrontTest.o

BroadcastObjs = Broadcast.o

ListFilesObjs = ListFiles.o

FindLostFilesObjs = FindLostFiles.o

RexxObjs = rexx.o

all:	NetTest AddMSg AddFile Broadcast QWK FrontDoor FrontTest ConfigNode Rexx FixIndex CheckIndex ListFiles UserEditor FindLostFiles ShowConfig FindUnread KillMsg CryptPasswords ConvertConfig Showuserfile

.c.o:
	; Compiling $*
	@ sc $(CFLAGS) $*

.s.o:
	arg $* -iinclude: -q -o$*.o

RUN: NetTest AddMsg AddFile FixIndex CheckIndex Listfiles FindLostFiles ShowConfig FindUnread KillMsg CryptPasswords
	slink NetTest to ram:NetTest NODEBUG QUIET NOICONS
	slink AddMsg to ram:AddMsg NODEBUG QUIET NOICONS
	slink AddFile to ram:AddFile NODEBUG QUIET NOICONS
	slink QWK to ram:QWK NODEBUG QUIET NOICONS
	slink ConfigNode to ram:ConfigNode NODEBUG QUIET NOICONS
	slink UserEditor to ram:UserEditor NODEBUG QUIET NOICONS
	slink FrontDoor to ram:FrontDoor NODEBUG QUIET NOICONS
	slink FrontTest to ram:FrontTest NODEBUG QUIET NOICONS
	slink Rexx to ram:Rexx NODEBUG QUIET NOICONS
	slink FixIndex to ram:FixIndex NODEBUG QUIET NOICONS
	slink CheckIndex to ram:CheckIndex NODEBUG QUIET NOICONS
	slink Listfiles to ram:Listfiles NODEBUG QUIET NOICONS
	slink FindLostFiles to ram:FindLostFiles NODEBUG QUIET NOICONS
	slink ShowConfig to ram:ShowConfig NODEBUG QUIET NOICONS
	slink FindUnread to ram:FindUnread NODEBUG QUIET NOICONS
	slink KillMsg to ram:KillMsg NODEBUG QUIET NOICONS
	slink CryptPasswords to ram:CryptPasswords NODEBUG QUIET NOICONS
	slink ConvertConfig to ram:ConvertConfig NODEBUG QUIET NOICONS
	slink Showuserfile to ram:Showuserfile NODEBUG QUIET NOICONS

AddMsg:	$(AddMsgObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(AddMsgObjs)
LIBRARY $(LIBS)
TO AddMsg
NOICONS
QUIET
<

AddFile:	$(AddFileObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(AddFileObjs)
LIBRARY $(LIBS)
TO AddFile
NOICONS
QUIET
<

Broadcast:	$(BroadcastObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(BroadcastObjs)
LIBRARY $(LIBS)
TO Broadcast
NOICONS
QUIET
<

FixIndex:	$(FixIndexObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(FixIndexObjs)
LIBRARY $(LIBS)
TO FixIndex
NOICONS
QUIET
<

CheckIndex:	$(CheckIndexObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(CheckIndexObjs)
LIBRARY $(LIBS)
TO CheckIndex
NOICONS
QUIET
<

NetTest:	$(NetTestObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(NetTestObjs)
LIBRARY $(LIBS)
TO NetTest
NOICONS
QUIET
<

QWK:	$(QWKObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(QWKObjs)
LIBRARY $(LIBS)
TO QWK
NOICONS
QUIET
<

ConfigNode:	$(ConfigNodeObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(ConfigNodeObjs)
LIBRARY $(LIBS)
TO ConfigNode
NOICONS
QUIET
<

UserEditor:	$(UserEditorObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(UserEditorObjs)
LIBRARY $(LIBS)
TO UserEditor
NOICONS
QUIET
<

FrontDoor:	$(FrontDoorObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(FrontDoorObjs)
LIBRARY $(LIBS)
TO FrontDoor
NOICONS
QUIET
<

FrontTest:	$(FrontTestObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(FrontTestObjs)
LIBRARY $(LIBS)
TO FrontTest
NOICONS
QUIET
<

Rexx:	$(RexxObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(RexxObjs)
LIBRARY $(LIBS)
TO Rexx
NOICONS
QUIET
<

ListFiles:	$(ListFilesObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(ListFilesObjs)
LIBRARY $(LIBS)
TO ListFiles
NOICONS
QUIET
<

FindLostFiles:	$(FindLostFilesObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(FindLostFilesObjs)
LIBRARY $(LIBS)
TO FindLostFiles
NOICONS
QUIET
<

ShowConfig:	ShowConfig.o
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) ShowConfig.o
LIBRARY $(LIBS)
TO ShowConfig
NOICONS
QUIET
<

FindUnread:	$(FindUnreadObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(FindUnreadObjs)
LIBRARY $(LIBS)
TO FindUnread
NOICONS
QUIET
<

KillMsg:	$(KillMsgObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(KillMsgObjs)
LIBRARY $(LIBS)
TO KillMsg
NOICONS
QUIET
<

CryptPasswords:	$(CryptPasswordsObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(CryptPasswordsObjs)
LIBRARY $(LIBS)
TO CryptPasswords
NOICONS
QUIET
<

ConvertConfig:	$(ConvertConfigObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(ConvertConfigObjs)
LIBRARY $(LIBS)
TO ConvertConfig
NOICONS
QUIET
<

Showuserfile:	$(ShowuserfileObjs)
		; Linking $*
		@ slink <WITH <
FROM $(STARTUP) $(ShowuserfileObjs)
LIBRARY $(LIBS)
TO Showuserfile
NOICONS
QUIET
<
