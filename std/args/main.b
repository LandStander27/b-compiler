use "std/heap";

!c __u8__** cmdline_args = NULL;

!c void init_args(int argc, __u8__** argv)
{
	!c cmdline_args = __alloc__(sizeof(__u8__*) * (argc+1));
	!c for (int i = 0; i < argc; i++)
	{
		!c cmdline_args[i] = __alloc__(sizeof(__u8__) * (strlen(argv[i]) + 1));
		!c strcpy(cmdline_args[i], argv[i]);
	}
	!c cmdline_args[argc] = NULL;
}

!c void free_args()
{
	i32 i = 0;
	!c while (cmdline_args[__i__] != NULL)
	{
		!c __free__(cmdline_args[__i__]);
		i++;
	}
	!c __free__(cmdline_args);
}

u8** Args.get() {
	!c return cmdline_args;
}
