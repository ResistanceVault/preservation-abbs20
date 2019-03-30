BOOL Load_userfile (VOID)
{
	int	n;
	BPTR fh;
	BOOL ret = FALSE;

	u_size = FileSize (UserFName);
	if (u_size != config->UserrecordSize * config->MaxUsers)
	{
		printf ("\n  Error in userfile!\n\n");
		return (FALSE);
	}

	if (U_buffer = AllocMem (u_size, MEMF_CLEAR))
	{
		if (fh = Open (UserFName, MODE_OLDFILE))
		{
			n = Read (fh, U_buffer, u_size);
			if (n == u_size)
				ret = TRUE;
			Close (fh);
		}
		else
			Err_opening_file (UserFName);
	}
	else
		Err_no_mem (u_size);

	if (!ret)	// Vi må lukke etter oss...
	{
		if (U_buffer)
			FreeMem (U_buffer, u_size);
	}

	return (ret);
}

BOOL Save_userfile (VOID)
{
	int	n;
	BPTR fh;
	BOOL ret = FALSE;

	if (u_save_flag)
	{
		if (fh = Open (UserFName, MODE_NEWFILE))
		{
			n = Write (fh, U_buffer, u_size);
			if (n == u_size)
				ret = TRUE;
			else
				Err_writing_file (UserFName);
			Close (fh);
		}
		else
			Err_opening_file (UserFName);
	}

	if (U_buffer)
		FreeMem (U_buffer, u_size);

	return (ret);
}
