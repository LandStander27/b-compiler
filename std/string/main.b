!c #include <string.h>

use "std/heap";
use "std/fmt";

struct String {
	u64 cap,
	u64 len,
	u8* data,
};

String String.new() {
	u8* s = alloc(sizeof(u8)*16);
	s[0] = 0;
	String v = {
		16,
		0,
		s,
	};
	return v;
}

nulltype String.free(String* v) {
	free((*v)->data);
}

nulltype String.resize(String* v, u64 len) {
	(*v)->cap = len;
	(*v)->data = realloc((*v)->data, (*v)->cap * sizeof(u8));
}

nulltype String.append(String* v, const u8* s);

String String.from(const u8* s) {
	String v = String.new();
	String.append(&v, s);
	return v;
}

String String.with_data(u8* s) {
	String v = {
		!c strlen(__s__),
		0,
		s,
	};
	return v;
}

nulltype String.append_char(String* v, u8 c) {
	if ((*v)->len+1 >= (*v)->cap) {
		(*v)->cap *= 2;
		(*v)->data = realloc((*v)->data, (*v)->cap * sizeof(u8));
	}

	(*v)->data[(*v)->len++] = c;
	(*v)->data[(*v)->len] = 0;
}

nulltype String.append(String* v, const u8* s) {
	while (*s != 0) {
		String.append_char(v, *s);
		s += sizeof(u8);
	}
}

u8* String.get(String* v);

nulltype String.append_format(String* s, const u8* format, ...) {
	String buf = String.new();

	defer {
		String.free(&buf);
	}

	i64 ret = 0;
	{
		!c va_list args;
		!c va_start(args, __format__);

		ret = !c vsnprintf (__String__get__(&__buf__), __buf__.__cap__, __format__, args);

		!c va_end(args);
	}

	if ((u64)ret >= buf->cap) {
		String.resize(&buf, ret + 1);

		{
			println("here");
			!c va_list args;
			!c va_start(args, __format__);

			ret = !c vsnprintf (__String__get__(&__buf__), __buf__.__cap__, __format__, args);

			!c va_end(args);
		}

	}

	String.append(s, String.get(&buf));

}

u8* String.getchar(String* v, u64 index) {
	if (index >= (*v)->len) {
		return 0;
	}
	return &((*v)->data[index]);
}

i64 String.find(String* v, const u8* s) {
	u8* i = !c strstr(
		String.get(v), s);
	if (i == 0) {
		return -1;
	}

	return (i - String.get(v)) / sizeof(u8);
}

bool String.contains(String* v, const u8* s) {
	return String.find(v, s) != -1;
}

bool String.compare(String* s, const u8* s2) {
	return !c strcmp(
		String.get(s), s2) == 0;
}

u8* String.get(String* v) {
	return (*v)->data;
}
