@c #include <stdlib.h>

u64 Heap.amount_allocated = 0;

any alloc(u64 size) {
	@c void* __ptr__ = malloc(__size__);
	Heap.amount_allocated += 1;
	return ptr;
}

any realloc(any ptr, u64 size) {
	@c void* __new___ptr__ = realloc(__ptr__, __size__);
	return new_ptr;
}

nulltype free(any ptr) {
	@c free(__ptr__);
	Heap.amount_allocated -= 1;
}
