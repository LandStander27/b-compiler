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

i32 string_to_f64(const u8* s) {
	@c return atof(__s__);
}

const u8* fmt.color.red = "\x1b[31m";
const u8* fmt.color.green = "\x1b[32m";
const u8* fmt.color.yellow = "\x1b[33m";
const u8* fmt.color.blue = "\x1b[34m";
const u8* fmt.color.magenta = "\x1b[35m";
const u8* fmt.color.cyan = "\x1b[36m";
const u8* fmt.color.white = "\x1b[37m";
const u8* fmt.color.reset = "\x1b[0m";

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
