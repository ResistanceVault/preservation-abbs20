;/*
sc5 -j73 b
copy b.c -J:b.c
slink LIB:c.o+"b.o" to b LIB LIB:sc.lib LIB:JEO.lib
Copy b ABBS:Utils
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>

struct ConfigRecord *config;

char *vers = "\0$VER: b v1.00 - 29.08.97";
char Dummy[1000];
char ConfigFName[] = "ABBS:Config/ConfigFile";
char string[10];
int	configsize = 0;
char Dummy[1000];

int user_len;
BPTR prt;

int cursor;

typedef struct
{
	char Name[31];
	BOOL flag;
	UWORD confnr;
} CB_header;

CB_header far head[500];

VOID Update_names (int active_conf, int max_lines, BOOL mode)
{
	int n;
	int start;

	if (mode)	// ned
		start = active_conf - max_lines;
	else
		start = active_conf - 1;

	sprintf (Dummy, "active_conf = %ld, max_lines = %ld, start = %ld\n", active_conf, max_lines, start);
//	Write (prt, Dummy, strlen (Dummy));
	printf ("[4;1H");
	for (n = start; n < start + max_lines; n++)	// Printer ut...
	{
		if (head[n].flag)
			printf ("[31m%-30s", head[n].Name);
		else
			printf ("[32m%-30s", head[n].Name);
		if (n < start + max_lines - 1)
			printf ("\n");
		else
			printf ("[%ld;1H", max_lines + 3);
	}
}

VOID Browse_confs (VOID)
{
	struct ConferenceRecord *confarray;
	int n;
	char c;
	BOOL flag = TRUE;
	int max_confs;
	int active_conf = 1;
	int max_lines = 0;

	if (prt = Open ("PRT:", MODE_NEWFILE));
//		Write (prt, "Start\n", 6);

	max_confs = 0;
	confarray = (struct ConferenceRecord *) (((int) config) + (SIZEOFCONFIGRECORD));
	for (n = 0; n < config->Maxconferences; n++)	// Finner antall konfer som er tilgjengelig
	{
		if (*(confarray[n].n_ConfName))
		{
			max_confs++;	// Fordi vi starter på 1
			strcpy (head[max_confs].Name, confarray[n].n_ConfName);
			head[max_confs].flag = FALSE;
			head[max_confs].confnr = n;
		}
	}

	printf ("[2J");	// Sletter skjerm
	printf ("[1;1H");	// Cursor på topp

	printf ("\n[0m[32mConference name\n");
	printf ("---------------\n[32m");

	max_lines = 0;
	cursor = 1; 
	for (n = 1; n <= max_confs; n++)	// Printer ut...
	{
		if (max_lines > user_len - 7)	// 7 = headere og slikt
			break;

		if (head[n + 1].flag)
			printf ("[31m%-30s\n", head[n].Name);
		else
			printf ("[32m%-30s\n", head[n].Name);
		max_lines++;
	}
	printf ("[0m<more>\n");
	printf ("[32mSpace tags/untags,Info,Quit(exit),Untag all");
	printf ("[4;1H");	// Cursor på topp

	while (flag)
	{
		c = getch ();
		switch (c)
		{
			case 27: flag = FALSE; break;	// ESC
			case 32:	// SPACE
			{
				if (!head[active_conf].flag)
				{
 					printf ("[31m%-30s", head[active_conf].Name);
					head[active_conf].flag = TRUE;
				}
				else
				{
					printf ("[32m%-30s", head[active_conf].Name);
					head[active_conf].flag = FALSE;
				}
				if (cursor < max_lines)
				{
					printf ("\n");
					cursor++;
					active_conf++;
				}
				else	// Kommer ikke lengere ned, start på linja...
					printf ("[%ld;1H", cursor + 3);
				break;
			}
			case 113: flag = FALSE; break;	// Q
			case -101:	// Piltaster
			{
				c = getch ();
				switch (c)
				{
					case 65:	// Pil opp
					{
						sprintf (Dummy, "%ld\n", active_conf);
//						Write (prt, Dummy, strlen (Dummy));

						if (cursor == 1)	// Er vi på topp???
						{
							if (active_conf > cursor)	// JA! Har vi flere tilbake?
							{
								Update_names (active_conf, max_lines, 0);	// Det hadde vi
								printf ("\n[0m<more> ");
								printf ("[4;1H");
								active_conf--;
							}
						}
						else	// NEI!
						{
							printf ("[1A"); 	// JA!
							cursor--;
							active_conf--;
						}
						break;
					}
					case 66:	// Pil ned
					{
						if (active_conf < max_confs)
						{
							if (cursor == max_lines)	// Slutt på lista men vi har flere
							{
								Update_names (active_conf + 2, max_lines, 1);
								if (active_conf == max_confs - 1)
								{
									printf ("\n[0m<end> ");
									printf ("[%ld;1H", max_lines + 3);
								}
							}
							else if (active_conf < max_confs)
							{
								printf ("[1B"); 
								cursor++;
							}
							active_conf++;
						}
						break;
					}
				}
				break;
			}
		}
	}
	printf ("[%ld;1H[0m", user_len);
	if (prt)
		Close (prt);
}

VOID main (int argc, char **argv)
{
	BPTR file;
	int n;

	if (argc == 2)
		user_len = atoi (argv[1]);

	if (user_len < 10)
		user_len = 10;

	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		n = Read (file, string, sizeof (string));
		if (n == sizeof (string))
			configsize = ((struct ConfigRecord *) &string)->Configsize;
		else
			printf ("\n Error reading file %s!\n\n", ConfigFName);
		if (configsize && (config = AllocVec (configsize,NULL)))
		{
			memcpy (config,string,sizeof (string));

			if ((configsize-sizeof (string)) == Read (file,
					((APTR) (((ULONG) config) + sizeof (string))),
					(configsize-sizeof (string))))
			{
				Close (file);
				file = NULL;
				Browse_confs ();
			}
			else
				printf ("\n Error reading file %s!\n\n", ConfigFName);
			if (file)
				 Close (file);
		}
		else
			printf ("\n Error allocating memory!\n\n");
	}
	else
		printf ("\n Error opening file %s! \n\n", ConfigFName);

	FreeVec (config);
}

// 31 rød
// 32 grønn
// 33 gul
// 34 blå
// 35 lilla
// 36 lyseblå
