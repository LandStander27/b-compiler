
const std = @import("std");
const out = std.io.getStdOut().writer();
const log = std.log;

const defs = @import("defs.zig");

const print = defs.print;
const println = defs.println;

const alloc_with_default = defs.alloc_with_default;
const alloc_with_default_slice = defs.alloc_with_default_slice;

const keywords = [_][]const u8{ "return", "const", "struct", "use", "sizeof", "inline", "...", "if", "else", "for", "while", "defer", "null", "nulltype", "any", "noreturn" };

const TokenType = enum {
	Beggining,
	Number,
	Keyword,
	Seperator,
	Operator,
	Ident,
	Str,
	Char,
	Compare,
	CLiteral,
	Comment,
	Defer,
	End,
};

pub const Token = struct {
	typ: ?TokenType,
	value: []u8,
	line_num: u64,
};

fn parse_number(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !Token {

	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;

	var has_decimal = false;

	while (std.ascii.isDigit(source[i]) or source[i] == '.') : (i += 1) {

		if (source[i] == '.') {
			if (has_decimal) {
				return error.InvalidNumber;
			}
			has_decimal = true;
		}

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	return Token {
		.typ = .Number,
		.value = str,
		.line_num = 0,
	};

}

fn parse_c_literal(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !Token {
	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;

	if (source[i] != '@' or source[i+1] != 'c' or source[i+2] != ' ') {
		return error.InvalidCKeyword;
	}

	i += 3;

	while (i < source.len and source[i] != '\n') : (i += 1) {

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	return Token {
		.typ = .CLiteral,
		.value = str,
		.line_num = 0,
	};
}

fn parse_ident(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !Token {
	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;

	while (std.ascii.isAlphabetic(source[i]) or std.ascii.isDigit(source[i]) or source[i] == '_' or source[i] == '.') : (i += 1) {

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	for (keywords) |kw| {
		if (std.mem.eql(u8, kw, str)) {
			return Token {
				.typ = .Keyword,
				.value = str,
				.line_num = 0,
			};
		}
	}

	return Token {
		.typ = .Ident,
		.value = str,
		.line_num = 0,
	};
}

fn parse_string(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !Token {
	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;
	var back_slashes: u64 = 0;

	while (true) : (i += 1) {

		if (source[i] == '"') {
			if (back_slashes % 2 == 0) {
				break;
			} else {
				back_slashes = 0;
			}
		}

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		if (source[i] == '\\') {
			back_slashes += 1;
		} else {
			back_slashes = 0;
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	return Token {
		.typ = .Str,
		.value = str,
		.line_num = 0,
	};
}

fn parse_char(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !Token {
	var str: []u8 = try alloc.alloc(u8, 4);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;
	var back_slashes: u64 = 0;

	while (true) : (i += 1) {

		if (source[i] == '\'') {
			if (back_slashes % 2 == 0) {
				break;
			} else {
				back_slashes = 0;
			}
		}

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		if (source[i] == '\\') {
			back_slashes += 1;
		} else {
			back_slashes = 0;
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	return Token {
		.typ = .Char,
		.value = str,
		.line_num = 0,
	};
}

fn parse_defer(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !struct { t: Token, amount_processed: u64 } {
	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;

	if (!std.mem.startsWith(u8, source[i..], "defer")) {
		return error.InvalidDeferKeyword;
	}
	i += 5;

	while (source[i] != '{') {
		i += 1;
	}

	i += 1;

	var scope: u64 = 1;
	while (i < source.len) : (i += 1) {
		if (source[i] == '{') {
			scope += 1;
		} else if (source[i] == '}') {
			scope -= 1;
			if (scope == 0) {
				break;
			}
		}

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		str[len] = source[i];
		len += 1;
	}

	str = try alloc.realloc(str, len);

	return .{
		.t = Token {
			.typ = .Defer,
			.value = str,
			.line_num = 0,
		},
		.amount_processed = i - current_index + 1,
	};

}

fn parse_comment(alloc: std.mem.Allocator, source: []const u8, current_index: u64) !struct { t: Token, amount_processed: u64 } {
	var str: []u8 = try alloc.alloc(u8, 16);
	errdefer alloc.free(str);

	var len: u64 = 0;
	var i: u64 = current_index;

	while (true) : (i += 1) {

		if (len >= str.len) {
			str = try alloc.realloc(str, str.len * 2);
		}

		str[len] = source[i];
		len += 1;

		if (source[i] == '\n') {
			break;
		}
	}

	str = try alloc.realloc(str, len);

	return .{
		.t = Token {
			.typ = .Comment,
			.value = str,
			.line_num = 0,
		},
		.amount_processed = i - current_index,
	};
}

const ParseMode = enum {
	Normal,
	StructDef,
};

const DeferStatement = struct {
	t: Token,
	scope: u64,
};

pub var imported_libs: std.ArrayList([]u8) = undefined;

pub fn format_tokens(alloc: std.mem.Allocator, tokens: *std.ArrayList(Token), current_index: u64, ending_token: Token, starting_indent: u64, source_name: []const u8, mode: ParseMode) !struct { s: std.ArrayList(u8), amount_processed: u64 } {

	var s = std.ArrayList(u8).init(alloc);
	errdefer s.deinit();

	var defers = std.ArrayList(DeferStatement).init(alloc);
	defer defers.deinit();

	var indent: u64 = starting_indent;

	var i = current_index;
	outer: while (i < tokens.items.len) : (i += 1) {

		const token = &tokens.items[i];

		if (token.typ == ending_token.typ and std.mem.eql(u8, token.value, ending_token.value)) {
			break;
		}

		if (s.items.len > 0 and s.items[s.items.len-1] == '\n') {
			for (0..indent) |_| {
				try s.appendSlice("\t");
			}
		}

		switch (token.typ.?) {
			.Defer => {
				try defers.append(.{ .t = token.*, .scope = indent });
			},
			.Keyword => {
				if (std.mem.eql(u8, token.value, "nulltype")) {
					try s.appendSlice("void");
				} else if (std.mem.eql(u8, token.value, "any")) {
					try s.appendSlice("void*");
				} else if (std.mem.eql(u8, token.value, "null")) {
					try s.appendSlice("((void*)0)");
				} else if (std.mem.eql(u8, token.value, "noreturn")) {
					try s.appendSlice("[[noreturn]] void");
				} else if (std.mem.eql(u8, token.value, "struct")) {
					if (tokens.items[i+1].typ.? == .Ident) {
						try s.appendSlice("typedef struct ");
						const name_of_struct = tokens.items[i+1].value;

						i += 2;
						const ending_struct = .{ .typ = .Seperator, .value = try alloc_with_default(u8, 1, ';', alloc), .line_num = 0 };
						defer alloc.free(ending_struct.value);

						const struc = try format_tokens(alloc, tokens, i, ending_struct, indent, source_name, .StructDef);
						defer struc.s.deinit();

						try s.appendSlice(struc.s.items);
						try s.appendSlice("__");
						try s.appendSlice(name_of_struct);
						try s.appendSlice("__;\n");

						i += struc.amount_processed;
					} else {
						try s.appendSlice("struct ");
						i += 1;
						const ending_struct = .{ .typ = .Seperator, .value = try alloc_with_default(u8, 1, ';', alloc), .line_num = 0 };
						defer alloc.free(ending_struct.value);

						const struc = try format_tokens(alloc, tokens, i, ending_struct, indent, source_name, .StructDef);
						defer struc.s.deinit();

						try s.appendSlice(struc.s.items);
						// try s.appendSlice("\n");

						i += struc.amount_processed;
					}

				} else if (std.mem.eql(u8, token.value, "use")) {

					const path_of_lib = tokens.items[i+1].value;
					i += 2;

					for (imported_libs.items) |lib| {
						if (std.mem.eql(u8, lib, path_of_lib)) {
							continue :outer;
						}
					}

					var dir: ?std.fs.Dir = null;

					if (std.fs.cwd().openDir(path_of_lib, .{ .iterate = true })) |d| {
						dir = d;
					} else |e| {
						if (e != error.FileNotFound) {
							log.err("Failed to open dir: {s}", .{@errorName(e)});
						}
					}

					if (dir == null) {
						const path = try std.fs.selfExeDirPathAlloc(alloc);
						defer alloc.free(path);

						const path_dir = try std.fs.openDirAbsolute(path, .{});

						if (path_dir.openDir(path_of_lib, .{ .iterate = true })) |d| {
							dir = d;
						} else |e| {
							if (e == error.FileNotFound) {
								log.err("Library {s} not found", .{path_of_lib});
							} else {
								log.err("Failed to open dir: {s}", .{@errorName(e)});
							}
						}
					}

					var it = dir.?.iterate();

					while (try it.next()) |entry| {

						if (entry.kind == .file) {
							const file = try dir.?.openFile(entry.name, .{});
							const source = try file.readToEndAlloc(alloc, 1024 * 1024 * 1024);
							defer alloc.free(source);

							var full = std.ArrayList(u8).init(alloc);
							try full.appendSlice(path_of_lib);
							try full.appendSlice("/");
							try full.appendSlice(entry.name);
							try defs.log_with_prefix(defs.colors.green ++ " Compiling" ++ defs.colors.reset, "{s}", .{full.items});

							log.debug("Parsing source", .{});
							var tokens2 = try parse_source(alloc, source, full.items);
							full.deinit();

							defer {
								for (tokens2.items) |token2| {
									alloc.free(token2.value);
								}
								tokens2.deinit();
							}

							for (tokens2.items) |token2| {
								log.debug("Found token: Type: {any} Value: {s}", .{token2.typ, token2.value});
							}

							log.debug("Translating tokens", .{});

							const ending_token2 = Token { .typ = .End, .value = try alloc_with_default_slice(u8, 3, "END", alloc), .line_num = 0 };
							defer alloc.free(ending_token2.value);

							const struc = try format_tokens(alloc, &tokens2, 0, ending_token2, 0, full.items, .Normal);

							const s2 = struc.s;
							defer s2.deinit();

							try s.appendSlice(s2.items);

						}

					}

					try imported_libs.append(try alloc.dupe(u8, path_of_lib));
					dir.?.close();

				} else if (std.mem.eql(u8, token.value, "return")) {
					for (0..defers.items.len) |j| {
						const def = defers.items[j];
						if (def.scope <= indent) {
							log.debug("Parsing source", .{});
							var tokens2 = try parse_source(alloc, def.t.value, source_name);

							defer {
								for (tokens2.items) |token2| {
									alloc.free(token2.value);
								}
								tokens2.deinit();
							}

							for (tokens2.items) |token2| {
								log.debug("Found token: Type: {any} Value: {s}", .{token2.typ, token2.value});
							}

							log.debug("Translating tokens", .{});

							const ending_token2 = Token { .typ = .End, .value = try alloc_with_default_slice(u8, 3, "END", alloc), .line_num = 0 };
							defer alloc.free(ending_token2.value);

							const struc = try format_tokens(alloc, &tokens2, current_index, ending_token2, indent, source_name, .Normal);

							const s2 = struc.s;
							defer s2.deinit();

							try s.appendSlice(s2.items);
							for (0..indent) |_| {
								try s.appendSlice("\t");
							}
							continue;
						}
					}

					try s.appendSlice(token.value);
				} else {
					try s.appendSlice(token.value);
				}
			},
			.CLiteral => {
				try s.appendSlice(token.value);
				try s.appendSlice("\n");
			},
			.Ident => {

				try s.appendSlice("__");

				var result = std.ArrayList(u8).init(alloc);
				defer result.deinit();

				try result.appendSlice(token.value);

				if (std.mem.count(u8, result.items, "_") > 0) {
					const buf = try alloc.alloc(u8, result.items.len + (std.mem.count(u8, result.items, "_") * 2));
					defer alloc.free(buf);

					_ = std.mem.replace(u8, result.items, "_", "___", buf);
					try result.resize(0);

					try result.appendSlice(buf);
				}

				if (std.mem.count(u8, result.items, ".") > 0) {
					const buf = try alloc.alloc(u8, result.items.len + (std.mem.count(u8, result.items, ".")));
					defer alloc.free(buf);

					_ = std.mem.replace(u8, result.items, ".", "__", buf);
					try result.resize(0);

					try result.appendSlice(buf);
				}

				try s.appendSlice(result.items);
				try s.appendSlice("__");

			},
			.Seperator => {
				if (std.mem.eql(u8, token.value, "{")) {
					try s.appendSlice("{\n");
					indent += 1;
				} else if (std.mem.eql(u8, token.value, "}")) {

					if (indent != 0) {
						var j: i64 = 0;
						while (j < defers.items.len) : (j += 1) {
							const def = defers.items[@as(u64, @bitCast(j))];
							if (def.scope == indent) {
								log.debug("Parsing source", .{});
								var tokens2 = try parse_source(alloc, def.t.value, source_name);

								defer {
									for (tokens2.items) |token2| {
										alloc.free(token2.value);
									}
									tokens2.deinit();
								}

								for (tokens2.items) |token2| {
									log.debug("Found token: Type: {any} Value: {s}", .{token2.typ, token2.value});
								}

								log.debug("Translating tokens", .{});

								const ending_token2 = Token { .typ = .End, .value = try alloc_with_default_slice(u8, 3, "END", alloc), .line_num = 0 };
								defer alloc.free(ending_token2.value);

								const struc = try format_tokens(alloc, &tokens2, current_index, ending_token2, indent, source_name, .Normal);

								const s2 = struc.s;
								defer s2.deinit();

								try s.appendSlice(s2.items);
								for (0..indent) |_| {
									try s.appendSlice("\t");
								}
								_ = defers.orderedRemove(@as(u64, @bitCast(j)));
								j -= 1;
								continue;
							}
						}
					} else {
						defers.shrinkRetainingCapacity(0);
					}

					try s.appendSlice("\n");
					for (0..indent-1) |_| {
						try s.appendSlice("\t");
					}
					try s.appendSlice("}\n");
					indent -= 1;
					if (indent == 0) {
						try s.appendSlice("\n");
					}
				} else if (std.mem.eql(u8, token.value, ";")) {
					try s.appendSlice(";\n");
				} else if (std.mem.eql(u8, token.value, ",")) {
					if (mode == .StructDef) {
						try s.appendSlice(";\n");
					} else {
						try s.appendSlice(",");
					}
				} else {
					try s.appendSlice(token.value);
				}
			},
			.Str => {
				try s.appendSlice("\"");
				try s.appendSlice(token.value);
				try s.appendSlice("\"");
			},
			.Char => {
				try s.appendSlice("\'");
				try s.appendSlice(token.value);
				try s.appendSlice("\'");
			},
			.End => {
				try s.appendSlice("\n");
			},
			else => {
				try s.appendSlice(token.value);
			},
		}

		if (s.getLast() != '\n' and token.typ != .Defer) {
			try s.appendSlice(" ");
		}

	}

	return .{ .s = s, .amount_processed = i-current_index };

}

const ParseError = error {
	InvalidNumber,
};

pub fn parse_source(alloc: std.mem.Allocator, source: []const u8, source_name: []const u8) !std.ArrayList(Token) {

	var current_line: u64 = 0;
	var current_index: u64 = 0;

	var tokens = std.ArrayList(Token).init(alloc);
	errdefer {
		for (tokens.items) |token| {
			alloc.free(token.value);
		}
		tokens.deinit();
	}

	var err: ?ParseError = null;

	loop: while (current_index < source.len) {

		const c = source[current_index];
		var caught: bool = true;

		if (c == '=' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Compare, .value = try alloc_with_default(u8, 2, c, alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '<' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Compare, .value = try alloc_with_default_slice(u8, 2, "<=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '>' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Compare, .value = try alloc_with_default_slice(u8, 2, ">=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '!' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Keyword, .value = try alloc_with_default_slice(u8, 2, "!=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '.' and source[current_index+1] == '.' and source[current_index+2] == '.') {
			try tokens.append(Token { .typ = .Keyword, .value = try alloc_with_default_slice(u8, 3, "...", alloc), .line_num = current_line });
			current_index += 2;
		} else if (c == '+' and source[current_index+1] == '+') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 2, c, alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '-' and source[current_index+1] == '-') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 2, c, alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '+' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default_slice(u8, 2, "+=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '-' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default_slice(u8, 2, "-=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '*' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default_slice(u8, 2, "*=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '/' and source[current_index+1] == '=') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default_slice(u8, 2, "/=", alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '-' and source[current_index+1] == '>') {
			try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, '.', alloc), .line_num = current_line });
			current_index += 1;
		} else if (c == '/' and source[current_index+1] == '/') {
			var str = parse_comment(alloc, source, current_index) catch null;
			if (str != null) {
				str.?.t.line_num = current_line;
				current_index += str.?.amount_processed;
				try tokens.append(str.?.t);
			}
		} else {
			caught = false;
		}

		if (!caught) {
			switch (c) {
				';' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'(' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				')' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'{' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'}' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				',' => try tokens.append(Token { .typ = .Seperator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'+' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'-' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'*' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'/' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'%' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'=' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'<' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'>' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'&' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'.' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'[' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				']' => try tokens.append(Token { .typ = .Operator, .value = try alloc_with_default(u8, 1, c, alloc), .line_num = current_line }),
				'\n' => {
					current_line += 1;
					caught = false;
				},
				else => caught = false,
			}
		}

		if (!caught) {

			if (c == '@') {
				var str: ?Token = parse_c_literal(alloc, source, current_index) catch null;
				if (str != null) {
					str.?.line_num = current_line;
					current_index += 3;
					current_index += str.?.value.len - 1;
					try tokens.append(str.?);
				}
			} else if (c == 'd') {
				var str = parse_defer(alloc, source, current_index) catch null;
				if (str != null) {
					str.?.t.line_num = current_line;
					current_index += str.?.amount_processed;
					try tokens.append(str.?.t);
					continue;
				}
			}

			if (std.ascii.isDigit(c)) {

				var num = parse_number(alloc, source, current_index) catch |e| {
					if (e == error.InvalidNumber) {
						err = ParseError.InvalidNumber;
						break :loop;
					} else {
						return e;
					}
				};
				num.line_num = current_line;
				current_index += num.value.len - 1;
				try tokens.append(num);

			} else if (std.ascii.isAlphabetic(c)) {

				var str = try parse_ident(alloc, source, current_index);
				str.line_num = current_line;
				current_index += str.value.len - 1;
				try tokens.append(str);

			} else if (c == '"') {

				var str = try parse_string(alloc, source, current_index+1);
				str.line_num = current_line;
				current_index += str.value.len + 1;
				try tokens.append(str);

			} else if (c == '\'') {

				var str = try parse_char(alloc, source, current_index+1);
				str.line_num = current_line;
				current_index += str.value.len + 1;
				try tokens.append(str);

			}
		}

		current_index += 1;

	}

	if (err) |e| {
		switch (e) {
			ParseError.InvalidNumber => {
				try defs.log_with_prefix(defs.colors.red ++ "     error" ++ defs.colors.reset, "Invalid number", .{});
			}
		}
		try println(defs.colors.red ++ "\t--> {s}:{d}" ++ defs.colors.reset, .{source_name, current_line});
		std.process.exit(1);
	}

	try tokens.append(Token { .typ = .End, .value = try alloc_with_default_slice(u8, 3, "END", alloc), .line_num = current_line });
	return tokens;
}



