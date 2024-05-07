const std = @import("std");
const out = std.io.getStdOut().writer();
const log = std.log;

pub const colors = struct {
	pub const bold = "\x1b[1m";
	pub const red = "\x1b[31m";
	pub const green = "\x1b[32m";
	pub const yellow = "\x1b[33m";
	pub const blue = "\x1b[34m";
	pub const magenta = "\x1b[35m";
	pub const cyan = "\x1b[36m";
	pub const white = "\x1b[37m";
	pub const reset = "\x1b[0m";
};

pub var log_level: std.log.Level = .warn;

pub fn logger(comptime level: std.log.Level, comptime _: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {

	if (@intFromEnum(level) > @intFromEnum(log_level)) return;

	const col = switch (level) {
		.debug => colors.bold ++ colors.white,
		.info => colors.cyan ++ colors.bold,
		.warn => colors.yellow ++ colors.bold,
		.err => colors.red ++ colors.bold,
	};

	const pre = switch (level) {
		.debug => "     debug",
		.info =>  "      info",
		.warn =>  "   warning",
		.err =>   "     error",
	};

	const prefix = col ++ pre ++ colors.reset;
	nosuspend log_with_prefix(prefix, format, args) catch return;

	if (level == .err) std.process.exit(1);
}

pub fn log_with_prefix(comptime prefix: []const u8, comptime format: []const u8, args: anytype) !void {
	try nosuspend println(prefix ++ " " ++ format, args);
}

pub inline fn print(comptime fmt: []const u8, args: anytype) !void {
	try out.print(fmt, args);
}

pub inline fn println(comptime fmt: []const u8, args: anytype) !void {
	try print(fmt ++ "\n", args);
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, a: ?usize) noreturn {
	_ = stack_trace;
	_ = a;
	log.err("panic: {s}\n", .{msg});
	std.process.exit(1);
}

pub fn alloc_with_default(comptime T: type, n: usize, default: T, alloc: std.mem.Allocator) ![]T {
	var arr = try alloc.alloc(T, n);
	errdefer alloc.free(arr);

	for (0..arr.len) |i| {
		arr[i] = default;
	}
	return arr;
}

pub fn alloc_with_default_slice(comptime T: type, n: usize, default_slice: []const T, alloc: std.mem.Allocator) ![]T {
	var arr = try alloc.alloc(T, n);
	errdefer alloc.free(arr);

	for (0..@min(arr.len, default_slice.len)) |i| {
		arr[i] = default_slice[i];
	}
	return arr;
}