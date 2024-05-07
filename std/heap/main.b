!c #include <stdlib.h>

any alloc(u64 size) {
	!c void* __ptr__ = malloc(__size__);
	return ptr;
}

any realloc(any ptr, u64 size) {
	!c void* __new_ptr__ = realloc(__ptr__, __size__);
	return new_ptr;
}

nulltype free(any ptr) {
	!c free(__ptr__);
}
