# D++

Extremely simple compiled language.
- Translates into C first and then into an executable.
- Auto memory leak checking.
- Not recommended for production use. As it does not even have proper error handling.

## Getting Started

### Building
- Linux
```
git clone https://github.com/LandStander27/b-compiler
cd b-compiler
make build
```
Add ./bin to PATH
### Usage
#### Examples

- Hello world
```
nulltype main() {
	println("Hello, world!"); // Hello, world!
}
```

- Stdin
```
use "std/heap";

nulltype main() {
	const usize max = 8;
	print("Input: ");

	str a = alloc(sizeof(u8) * max);
	defer { free(a); }

	if (input(a, max) == -1) {
		panic("Buffer too small");
	}

	println("%s", a);
}
```

<!-- - String formatting
```
i32 main() {
	i32 a = 6;
	str s = "Mine: {a}"; // Calls a.display() and embeds into string. This allows you to create a custom string formatter on an object.
	println("Number: {s}"); // Number: Mine: 6
}
``` -->

<!-- - Vectors
```
i32 main() {
	Vec<i32> a = { 1, 2 };
	a << 3;
	println("Vector: {a}"); // { 1, 2, 3 }
}
``` -->

- Command line arguments
```
use "std/args";

nulltype main() {
	u8** args = Args.get();

	if (args[1] != null) {
		println("First argument: %s.", args[1]);
	} else {
		println("No arguments.");
	}
}
```

<!-- - For loops
```
nulltype main() {
	for (i32 i = 0; i < 10; i++) {
		print("%d, ", i);
	} // 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,

	print("\n");
}
``` -->

- Panics
```
use "std/fmt";

f64 get_number() {
	u8* s = alloc(16);
	defer { free(s); }

	getline(s, 16);
	f64 num = string_to_f64(s);
	return num;
}

nulltype main() {
	f64 first = get_number();
	f64 second = get_number();

	if (second == 0) {
		panic("Cannot divide by zero.");
	}

	println("First / Second: %lf", first / second);
}
```

<!-- - Everything else is exactly like C++ -->
<!-- - For more in-depth examples take a look at [Examples](https://github.com/LandStander27/dpp/tree/master/examples) -->