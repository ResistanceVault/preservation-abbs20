#include <JEO:JEO.h>
#include <proto/dos.h>

VOID Multi_create_dir (char *Dir)
{
	int i;
	BPTR lock;
	char Dir[] = "RAM:Test/JEO/Ellinor";

	for (i = 0; Dir[i] != 0; i++)
	{
		if (Dir[i] == '/')
		{
			Dir[i] = 0;
		  lock = CreateDir (Dir);
		  if (lock)
		    UnLock (lock);
			Dir[i] = '/';
		}
	}
  lock = CreateDir (Dir);
  if (lock)
		UnLock (lock);
}
