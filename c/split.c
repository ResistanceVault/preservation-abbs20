#include <stdio.h>

void main (int argc, char **argc)
{
	FILE *fil;
	int	c,state = 0;

	if (argc < 2) {
		printf ("Usage: %s <filename>\n",argv[0]);
		return;
	}

	if (!(fil = fopen (argv[1],"r"))) {
		printf ("Error opening file : %s\n",argv[1]);
		return;
	}

	while (1) {
		c = fgetc
	}

	fclose (fil);
}
