// Base

const std = @import("std");
const out = std.io.getStdOut().writer();
const log = std.log;

const clap = @import("clap");
const defs = @import("defs.zig");

const print = defs.print;
const println = defs.println;

const alloc_with_default = defs.alloc_with_default;
const alloc_with_default_slice = defs.alloc_with_default_slice;

pub const std_options: std.Options = .{
	.log_level = .debug,
	.logFn = defs.logger,
};

const parse = @import("parsers.zig");
const Token = parse.Token;

// End Base

pub fn main() !void {

	defer log.info("Exiting", .{});

	log.info("Init heap alloc", .{});
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	var alloc = gpa.allocator();
	defer _ = gpa.deinit();
	defer log.info("Free heap alloc", .{});

	log.debug("Parsing arguments", .{});
	const params = comptime clap.parseParamsComptime(
		\\-h, --help						Display this help and exit.
		\\-v, --verbose						Increase output verbosity.
		\\--keepc <output_file>				Output generated C code to file.
		\\-o, --output <output_file>		Specify the output file.
		\\<input_file>						Input file. (file.b)
		\\
	);

	const parsers = comptime .{
		.output_file = clap.parsers.string,
		.input_file = clap.parsers.string,
	};

	var res = try clap.parse(clap.Help, &params, parsers, .{
		.allocator = alloc,
	});
	defer res.deinit();

	if (res.args.help != 0) {
		const args = try std.process.argsAlloc(alloc);
		defer std.process.argsFree(alloc, args);

		try println("BC, the B Compiler.", .{});
		try print(defs.colors.bold ++ defs.colors.white ++ "Usage: " ++ defs.colors.reset ++ "{s} ", .{args[0]});
		try clap.usage(out, clap.Help, &params);
		try print("\n", .{});
		try clap.help(out, clap.Help, &params, .{
			.spacing_between_parameters = 0,
		});
		std.process.exit(0);
	}

	if (res.args.verbose != 0) {
		defs.log_level = .debug;
	}

	log.debug("Opening file", .{});

	if (res.positionals.len == 0) {
		return error.NoInputFile;
	}
	const filepath: []const u8 = res.positionals[0];

	var file = std.fs.cwd().openFile(filepath, .{}) catch |e| {
		if (e == error.FileNotFound) {
			log.err("Failed to open file: File does not exist", .{});
		}
		log.err("Failed to open file: {s}", .{@errorName(e)});
		return e;
	};
	defer file.close();

	try defs.log_with_prefix(defs.colors.green ++ " Compiling" ++ defs.colors.reset, "{s}", .{filepath});

	const source = blk: {
		const source = try file.readToEndAlloc(alloc, 1024 * 1024 * 1024);
		defer alloc.free(source);

		var source2 = try alloc.alloc(u8, source.len + "use builtin;\n".len);
		std.mem.copyForwards(u8, source2, "use builtin;\n");
		std.mem.copyForwards(u8, source2["use buildin;\n".len..], source);
		break :blk source2;
	};

	defer alloc.free(source);

	parse.imported_libs = std.ArrayList([]u8).init(alloc);
	defer {
		for (parse.imported_libs.items) |lib| {
			alloc.free(lib);
		}
		parse.imported_libs.deinit();
	}

	log.info("Parsing source", .{});
	var tokens = try parse.parse_source(alloc, source, filepath);

	defer {
		for (tokens.items) |token| {
			alloc.free(token.value);
		}
		tokens.deinit();
	}

	for (tokens.items) |token| {
		log.debug("Found token: Type: {any} Value: {s}", .{token.typ, token.value});
	}

	log.info("Translating tokens", .{});

	const ending_token = Token { .typ = .End, .value = try alloc_with_default_slice(u8, 3, "END", alloc), .line_num = 0 };
	defer alloc.free(ending_token.value);

	const struc = try parse.format_tokens(alloc, &tokens, 0, ending_token, 0, filepath, .Normal);

	const s = struc.s;
	defer s.deinit();

	if (res.args.keepc) |name| {
		log.info("Writing to {s}", .{name});
		var f = try std.fs.cwd().createFile(name, .{});
		try f.writeAll(s.items);
		f.close();
	}

	// log.debug("Result:\n{s}", .{s.items});

	const output = if (res.args.output) |name| name else "a.out";

	try defs.log_with_prefix(defs.colors.green ++ "  Building" ++ defs.colors.reset, "{s}", .{output});

	var argv = std.ArrayList([]const u8).init(alloc);
	defer argv.deinit();

	try argv.appendSlice(&[_][]const u8{ "gcc", "-Wall", "-Wextra", "-static", "-x", "c", "-" });

	if (res.args.output) |_| {
		try argv.append("-o");
		try argv.append(output);
	}

	var gcc = std.process.Child.init(argv.items, alloc);

	gcc.stdin_behavior = .Pipe;
	gcc.stdout_behavior = .Pipe;
	gcc.stderr_behavior = .Inherit;

	try gcc.spawn();

	try gcc.stdin.?.writeAll(s.items);
	gcc.stdin.?.close();
	gcc.stdin_behavior = .Ignore;
	gcc.stdin = null;

	switch (try gcc.wait()) {
		.Exited => |code| {
			if (code != 0) {
				log.warn("GCC exited with code: {d}", .{code});
			}
		},
		else => |err| {
			log.err("Error: {any}", .{err});
			return error.ProcessFailed;
		}
	}

	_ = try gcc.kill();

}
