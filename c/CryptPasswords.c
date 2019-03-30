/***************************************************************************
*									CryptPasswords 1.1 (15/07-95)
*
*	Recreates the index files
*
*	Usage : [USER=<userfile>]
*
*  1.1 Fikset bug i renameing etter konvertering...
*
***************************************************************************/
#include <bbs.h>

char *vers = "\0$VER: CryptPasswords 1.1 (15.7.95)\n\r";	/* day,month,year */

#include <dos/dos.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>

int	main(int argc, char **argv);

struct UserRecord user;

#define TEMPLATE "USERFILE/A"
#define OPT_COUNT 1

/* STRPTR ACrypt( STRPTR, STRPTR, STRPTR); */

int main(int argc, char **argv)
{
	BPTR	fil = NULL,fil2 = NULL;
	int	n;
	char	*ptr, *ptr2;
	int	ret = 10;
	char	newuserfilename[60];
	char	passwd[14];
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0};
	char	*userfname;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		userfname = result[0] ? (char *) result[0] : "userfile";

		while (1) {
			if (FindPort(MainPortName)) {
				printf ("CryptPasswords won't work if abbs is running..\n");
				break;
			}

			printf ("remember: CryptPasswords should only be run once..\n");

			if (!(fil = Open (userfname,MODE_OLDFILE))) {
				printf ("Error opening userfile\n");
				break;
			}

			sprintf (newuserfilename,"%s.new",userfname);
			if (!(fil2 = Open (newuserfilename,MODE_NEWFILE))) {
				printf ("Error opening new userfile\n");
				break;
			}

			do {
				n = Read (fil,&user,sizeof (struct UserRecord));

				if (!n) {
					ret = 0;
					break;	/* Ferdig */
				}

				if (n != sizeof (struct UserRecord)) {
					printf ("Error reading userfile\n");
					break;
				}

				memset (passwd,'\0',sizeof (passwd));

				if (!(ACrypt (passwd, user.Password, user.Name))) {
					printf ("Acrypt failed for user %s\n",user.Name);
					break;
				}

				ptr = passwd;
				ptr2 = user.Password;
				for (n = 0; n < sizeof (PassT); n++)
					*(ptr2++) = *(ptr++);
				user.pass_10 = *(ptr++);
				user.pass_11 = *(ptr++);

				n = Write (fil2,&user,sizeof (struct UserRecord));

				if (n != sizeof (struct UserRecord)) {
					printf ("Error writing userfile\n");
					break;
				}

			} while (n == sizeof (struct UserRecord));

			break;
		}

		if (fil) Close (fil);
		if (fil2) Close (fil2);

		if (!ret) {
			sprintf (newuserfilename,"%s.old",userfname);
			if (Rename (userfname,newuserfilename)) {
				sprintf (newuserfilename,"%s.new",userfname);
				if (Rename (newuserfilename,userfname)) {
				} else {
					printf ("Error installing new userfile. %s should be renamed to %s\n",
						newuserfilename,userfname);
					ret = 1;
				}
			} else {
				printf ("Error installing new userfile. Old userfile (%s) still active\n",userfname);
				ret = 1;
			}
		}

		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	return (ret);
}
