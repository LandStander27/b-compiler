@c #include <string.h>
@c #include <stdio.h>
@c #include <stdarg.h>

use "std/heap";

i32 format(u8* s, u64 max, const u8* format, ...) {
	@c va_list args;
	@c va_start(args, __format__);

	i32 ret = @c vsnprintf (__s__, __max__, __format__, args);

	@c va_end(args);

	return ret;
}

i32 string_to_i32(const u8* s) {
	@c return atoi(__s__);
}

u8* format_alloc(const u8* format, ...) {
	u8* s = 0;

	i32 ret = 0;
	{
		@c va_list args;
		@c va_start(args, __format__);

		ret = @c vsnprintf (__s__, 0, __format__, args);

		@c va_end(args);
	}

	if (ret >= 0) {
		s = alloc(ret + 1);
		@c va_list args;
		@c va_start(args, __format__);
		ret = @c vsnprintf (__s__, __ret__+1, __format__, args);

		@c va_end(args);
	}

	return s;
}
