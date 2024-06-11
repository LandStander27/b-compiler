@c #include <stddef.h>
@c #include <stdio.h>
@c #include <stdarg.h>
@c #include <string.h>

@c typedef int __i32__;
@c typedef float __f32__;
@c typedef double __f64__;
@c typedef char __u8__;
@c typedef signed char __i8__;
@c typedef unsigned int __u32__;
@c typedef unsigned long long __u64__;
@c typedef long long __i64__;

@c typedef __i32__ __bool__;
@c #define __true__ 1
@c #define __false__ 0

nulltype print(u8* format, ...) {
	@c va_list args;
	@c va_start(args, __format__);
	@c vprintf(__format__, args);
	@c va_end(args);
}

nulltype println(u8* format, ...) {
	@c va_list args;
	@c va_start(args, __format__);
	@c vprintf(__format__, args);
	@c va_end(args);
	@c printf("\n");
}

use "std/heap";
use "std/args";

nulltype main();

@c __i32__ main(__i32__ argc, __u8__** argv)
{
	@c init_args(argc, argv);
	main();
	@c free_args();

	u64 amount_allocated =
		@c amount_allocated;

	if (amount_allocated != 0) {
		println("Memory leak detected");
		return 1;
	}

	return 0;
}
