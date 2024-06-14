build:
	zig build --release=fast
	rm -rf zig-out
	cp -r builtin std bin

clean:
	rm -rf .zig-cache zig-out

cleanall:
	make clean
	rm -rf bin
