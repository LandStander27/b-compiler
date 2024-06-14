@c #include <stddef.h>
@c #include <stdio.h>
@c #include <stdarg.h>
@c #include <string.h>
@c #include <stdlib.h>

@c typedef int __i32__;
@c typedef float __f32__;
@c typedef double __f64__;
@c typedef char __u8__;
@c typedef signed char __i8__;
@c typedef unsigned int __u32__;
@c typedef unsigned long long __u64__;
@c typedef long long __i64__;
@c typedef size_t __usize__;
@c typedef __u8__* __str__;

@c typedef __i32__ __bool__;
@c #define __true__ 1
@c #define __false__ 0

noreturn exit(i32 code) {
	@c exit(__code__);
}

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

i32 input(u8* s, usize max) {
	usize max2 = max;
	@c __i64__ __chars__ = getline(
		&s, &max2,
		@c stdin
	);

	if (chars == -1 or chars >= (i64)max) {
		return -1;
	}

	if (chars != 0 and chars < (i64)max and s[chars-1] == '\n') {
		s[chars-1] = 0;
	}

	return 0;

}

noreturn panic(u8* format, ...) {
	print("%s     panic%s ", "\x1b[31m", "\x1b[0m");

	@c va_list args;
	@c va_start(args, __format__);
	@c vprintf(__format__, args);
	@c va_end(args);
	@c printf("\n");

	exit(1);

}

use "std/heap";
use "std/args";

nulltype main();

@c __i32__ main(__i32__ argc, __u8__** argv)
{
	@c init_args(argc, argv);
	main();
	@c free_args();

	if (Heap.amount_allocated != 0) {
		// println("%s     error%s Memory leaks: %d", "\x1b[31m", "\x1b[0m", Heap.amount_allocated);
		panic("Memory leaks: %d", Heap.amount_allocated);
		return 1;
	}

	return 0;
}
