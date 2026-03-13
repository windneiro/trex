const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const VERSION = "1.0.2";
const AUTHOR = "Windneiro";

// ANSI color codes
const Color = struct {
    const reset        = "\x1b[0m";
    const bold         = "\x1b[1m";
    const dim          = "\x1b[2m";
    const bright_blue  = "\x1b[94m";
    const bright_cyan  = "\x1b[96m";
    const bright_green = "\x1b[92m";
    const bright_yellow= "\x1b[93m";
    const bright_white = "\x1b[97m";
    const red          = "\x1b[31m";
};

const TreeChars = struct {
    branch: []const u8,
    last:   []const u8,
    pipe:   []const u8,
    space:  []const u8,
};

// ASCII by default -- works on Windows CMD / PowerShell without any encoding issues
const ASCII_CHARS = TreeChars{
    .branch = "+-- ",
    .last   = "`-- ",
    .pipe   = "|   ",
    .space  = "    ",
};

// Unicode box-drawing -- opt-in via --unicode (requires UTF-8 terminal)
const UNICODE_CHARS = TreeChars{
    .branch = "\xe2\x94\x9c\xe2\x94\x80\xe2\x94\x80 ",
    .last   = "\xe2\x94\x94\xe2\x94\x80\xe2\x94\x80 ",
    .pipe   = "\xe2\x94\x82   ",
    .space  = "    ",
};

const Options = struct {
    path:          []const u8  = ".",
    max_depth:     ?u32        = null,
    show_hidden:   bool        = false,
    dirs_only:     bool        = false,
    no_color:      bool        = false,
    unicode_mode:  bool        = false,
    show_size:     bool        = false,
    pattern:       ?[]const u8 = null,
    dirs_first:    bool        = false,
    files_first:   bool        = false,
    show_full_path:bool        = false,
    count_only:    bool        = false,
};

const Stats = struct {
    dirs:       u64 = 0,
    files:      u64 = 0,
    symlinks:   u64 = 0,
    total_size: u64 = 0,
};

const EntryKind = enum { file, dir, symlink, other };

const Entry = struct {
    name: []const u8,
    kind: EntryKind,
    size: u64,
};

fn printHelp() void {
    const out = io.getStdOut().writer();

    out.print("{s}{s}trex{s} {s}v{s}{s} -- Tree Explorer\n", .{
        Color.bold, Color.bright_cyan, Color.reset,
        Color.bright_yellow, VERSION, Color.reset,
    }) catch {};
    out.print("{s}by {s}{s}\n\n", .{ Color.dim, AUTHOR, Color.reset }) catch {};

    out.print("{s}USAGE:{s}\n  trex [OPTIONS] [PATH]\n\n", .{ Color.bold, Color.reset }) catch {};
    out.print("{s}OPTIONS:{s}\n", .{ Color.bold, Color.reset }) catch {};

    const G = Color.bright_green;
    const R = Color.reset;
    out.print("  {s}-h, --help{s}           Show this help message\n",             .{ G, R }) catch {};
    out.print("  {s}-v, --version{s}        Show version information\n",           .{ G, R }) catch {};
    out.print("  {s}-d, --depth <N>{s}      Max depth to traverse\n",              .{ G, R }) catch {};
    out.print("  {s}-a, --all{s}            Show hidden files and directories\n",  .{ G, R }) catch {};
    out.print("  {s}-D, --dirs-only{s}      Show only directories\n",              .{ G, R }) catch {};
    out.print("  {s}-s, --size{s}           Show file sizes\n",                    .{ G, R }) catch {};
    out.print("  {s}--pattern <GLOB>{s}     Filter entries (e.g. *.zig)\n",        .{ G, R }) catch {};
    out.print("  {s}--dirs-first{s}         List directories before files\n",      .{ G, R }) catch {};
    out.print("  {s}--files-first{s}        List files before directories\n",      .{ G, R }) catch {};
    out.print("  {s}--full-path{s}          Print full path for each entry\n",     .{ G, R }) catch {};
    out.print("  {s}--no-color{s}           Disable colored output\n",             .{ G, R }) catch {};
    out.print("  {s}--unicode{s}            Use Unicode box-drawing characters\n", .{ G, R }) catch {};
    out.print("  {s}--count{s}              Show summary counts only\n\n",         .{ G, R }) catch {};

    out.print("{s}EXAMPLES:{s}\n", .{ Color.bold, Color.reset }) catch {};
    out.writeAll("  trex                      Explore current directory\n")    catch {};
    out.writeAll("  trex C:\\Users\\me -d 2     Max depth of 2\n")             catch {};
    out.writeAll("  trex . -a -s              Show all files with sizes\n")    catch {};
    out.writeAll("  trex src --pattern *.zig  Filter .zig files only\n")       catch {};
    out.writeAll("  trex . -D --dirs-first    Directories only, sorted\n\n")   catch {};
}

fn printVersion() void {
    const out = io.getStdOut().writer();
    out.print("{s}trex{s} version {s}{s}{s} -- built by {s}\n", .{
        Color.bright_cyan,   Color.reset,
        Color.bright_yellow, VERSION, Color.reset,
        AUTHOR,
    }) catch {};
}

fn formatSize(size: u64, buf: []u8) []const u8 {
    if (size >= 1024 * 1024 * 1024)
        return std.fmt.bufPrint(buf, "{d:.1}G", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0 * 1024.0)}) catch "?";
    if (size >= 1024 * 1024)
        return std.fmt.bufPrint(buf, "{d:.1}M", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0)}) catch "?";
    if (size >= 1024)
        return std.fmt.bufPrint(buf, "{d:.1}K", .{@as(f64, @floatFromInt(size)) / 1024.0}) catch "?";
    return std.fmt.bufPrint(buf, "{d}B", .{size}) catch "?";
}

fn matchPattern(name: []const u8, pattern: []const u8) bool {
    if (mem.eql(u8, pattern, "*")) return true;
    if (mem.indexOf(u8, pattern, "*")) |star| {
        const pre = pattern[0..star];
        const suf = pattern[star + 1 ..];
        if (!mem.startsWith(u8, name, pre)) return false;
        if (suf.len == 0) return true;
        if (name.len < pre.len + suf.len) return false;
        return mem.endsWith(u8, name, suf);
    }
    return mem.eql(u8, name, pattern);
}

fn entryColor(kind: EntryKind, no_color: bool) []const u8 {
    if (no_color) return "";
    return switch (kind) {
        .dir     => Color.bright_blue,
        .symlink => Color.bright_cyan,
        .file    => Color.bright_white,
        .other   => Color.dim,
    };
}

fn kindSuffix(kind: EntryKind) []const u8 {
    return switch (kind) {
        .dir     => "/",
        .symlink => "@",
        .file    => "",
        .other   => "?",
    };
}

fn lessThan(opts: *const Options, a: Entry, b: Entry) bool {
    if (opts.dirs_first) {
        if (a.kind == .dir and b.kind != .dir) return true;
        if (a.kind != .dir and b.kind == .dir) return false;
    }
    if (opts.files_first) {
        if (a.kind != .dir and b.kind == .dir) return true;
        if (a.kind == .dir and b.kind != .dir) return false;
    }
    return std.ascii.lessThanIgnoreCase(a.name, b.name);
}

// Join path using the separator already present in parent (handles both / and \)
fn joinPath(alloc: mem.Allocator, parent: []const u8, name: []const u8) ![]u8 {
    const sep: u8 = if (mem.indexOfScalar(u8, parent, '\\') != null) '\\' else '/';
    return std.fmt.allocPrint(alloc, "{s}{c}{s}", .{ parent, sep, name });
}

fn walk(
    alloc:    mem.Allocator,
    writer:   anytype,
    dir_path: []const u8,
    prefix:   []const u8,
    depth:    u32,
    opts:     *const Options,
    stats:    *Stats,
    chars:    *const TreeChars,
) !void {
    if (opts.max_depth) |md| if (depth > md) return;

    var dir = fs.openDirAbsolute(dir_path, .{ .iterate = true }) catch |err| {
        if (!opts.no_color) try writer.writeAll(Color.red);
        try writer.print("[cannot open: {s}]\n", .{@errorName(err)});
        if (!opts.no_color) try writer.writeAll(Color.reset);
        return;
    };
    defer dir.close();

    var entries = ArrayList(Entry).init(alloc);
    defer {
        for (entries.items) |e| alloc.free(e.name);
        entries.deinit();
    }

    var it = dir.iterate();
    while (try it.next()) |raw| {
        if (!opts.show_hidden and raw.name.len > 0 and raw.name[0] == '.') continue;

        const kind: EntryKind = switch (raw.kind) {
            .directory => .dir,
            .sym_link  => .symlink,
            .file      => .file,
            else       => .other,
        };

        if (opts.dirs_only and kind != .dir) continue;
        if (opts.pattern) |pat| {
            if (kind == .file and !matchPattern(raw.name, pat)) continue;
        }

        var size: u64 = 0;
        if (opts.show_size and kind == .file) {
            const fp = joinPath(alloc, dir_path, raw.name) catch continue;
            defer alloc.free(fp);
            if (fs.openFileAbsolute(fp, .{})) |f| {
                defer f.close();
                if (f.stat()) |st| { size = st.size; stats.total_size += size; } else |_| {}
            } else |_| {}
        }

        try entries.append(.{
            .name = try alloc.dupe(u8, raw.name),
            .kind = kind,
            .size = size,
        });
    }

    std.sort.insertion(Entry, entries.items, opts, struct {
        fn lt(o: *const Options, a: Entry, b: Entry) bool { return lessThan(o, a, b); }
    }.lt);

    for (entries.items, 0..) |entry, idx| {
        const last     = (idx == entries.items.len - 1);
        const conn     = if (last) chars.last  else chars.branch;
        const next_ext = if (last) chars.space else chars.pipe;
        const next_pfx = try std.fmt.allocPrint(alloc, "{s}{s}", .{ prefix, next_ext });
        defer alloc.free(next_pfx);

        const col = entryColor(entry.kind, opts.no_color);
        const suf = kindSuffix(entry.kind);
        const rst = if (opts.no_color) "" else Color.reset;

        switch (entry.kind) {
            .dir     => stats.dirs     += 1,
            .file    => stats.files    += 1,
            .symlink => stats.symlinks += 1,
            .other   => {},
        }

        if (!opts.no_color) try writer.writeAll(Color.dim);
        try writer.print("{s}{s}", .{ prefix, conn });
        if (!opts.no_color) try writer.writeAll(Color.reset);

        if (opts.show_size and entry.kind == .file) {
            var sb: [32]u8 = undefined;
            const ss = formatSize(entry.size, &sb);
            try writer.print("{s}{s}{s}{s} {s}[{s}]{s}\n", .{
                col, entry.name, suf, rst,
                Color.bright_yellow, ss, rst,
            });
        } else {
            try writer.print("{s}{s}{s}{s}\n", .{ col, entry.name, suf, rst });
        }

        if (entry.kind == .dir) {
            const child = try joinPath(alloc, dir_path, entry.name);
            defer alloc.free(child);
            try walk(alloc, writer, child, next_pfx, depth + 1, opts, stats, chars);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var opts = Options{};
    var path_arg: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if      (mem.eql(u8, a, "-h") or mem.eql(u8, a, "--help"))      { printHelp();    return; }
        else if (mem.eql(u8, a, "-v") or mem.eql(u8, a, "--version"))    { printVersion(); return; }
        else if (mem.eql(u8, a, "-a") or mem.eql(u8, a, "--all"))        { opts.show_hidden    = true; }
        else if (mem.eql(u8, a, "-D") or mem.eql(u8, a, "--dirs-only"))  { opts.dirs_only      = true; }
        else if (mem.eql(u8, a, "-s") or mem.eql(u8, a, "--size"))       { opts.show_size      = true; }
        else if (mem.eql(u8, a, "--no-color"))    { opts.no_color       = true; }
        else if (mem.eql(u8, a, "--unicode"))     { opts.unicode_mode   = true; }
        else if (mem.eql(u8, a, "--dirs-first"))  { opts.dirs_first     = true; opts.files_first = false; }
        else if (mem.eql(u8, a, "--files-first")) { opts.files_first    = true; opts.dirs_first  = false; }
        else if (mem.eql(u8, a, "--full-path"))   { opts.show_full_path = true; }
        else if (mem.eql(u8, a, "--count"))       { opts.count_only     = true; }
        else if (mem.eql(u8, a, "-d") or mem.eql(u8, a, "--depth")) {
            i += 1;
            if (i >= args.len) { std.debug.print("--depth requires a number\n", .{}); return error.InvalidArgument; }
            opts.max_depth = std.fmt.parseInt(u32, args[i], 10) catch {
                std.debug.print("Invalid depth: '{s}'\n", .{args[i]}); return error.InvalidArgument;
            };
        } else if (mem.eql(u8, a, "--pattern")) {
            i += 1;
            if (i >= args.len) { std.debug.print("--pattern requires a value\n", .{}); return error.InvalidArgument; }
            opts.pattern = args[i];
        } else if (a.len > 0 and a[0] != '-') {
            path_arg = a;
        } else {
            std.debug.print("Unknown option: {s}\nRun 'trex --help' for usage.\n", .{a});
            return error.InvalidArgument;
        }
    }

    if (path_arg) |p| opts.path = p;

    const stdout = io.getStdOut().writer();
    var buf_writer = io.bufferedWriter(stdout);
    const writer = buf_writer.writer();

    // ASCII by default; unicode only when explicitly requested with --unicode
    const chars: *const TreeChars = if (opts.unicode_mode) &UNICODE_CHARS else &ASCII_CHARS;

    var abs_buf: [fs.max_path_bytes]u8 = undefined;
    const abs = try fs.realpath(opts.path, &abs_buf);

    const display = if (opts.show_full_path) abs else opts.path;
    if (!opts.no_color) try writer.writeAll(Color.bold ++ Color.bright_cyan);
    try writer.writeAll(display);
    if (!opts.no_color) try writer.writeAll(Color.reset);
    try writer.writeByte('\n');

    var stats = Stats{};
    try walk(alloc, writer, abs, "", 0, &opts, &stats, chars);
    try buf_writer.flush();

    const out = io.getStdOut().writer();
    try out.writeByte('\n');

    if (!opts.no_color) try out.writeAll(Color.bright_green);
    try out.print("{d} director{s}", .{ stats.dirs, if (stats.dirs == 1) "y" else "ies" });
    if (!opts.no_color) try out.writeAll(Color.reset);

    if (!opts.dirs_only) {
        try out.writeAll(", ");
        if (!opts.no_color) try out.writeAll(Color.bright_white);
        try out.print("{d} file{s}", .{ stats.files, if (stats.files == 1) "" else "s" });
        if (!opts.no_color) try out.writeAll(Color.reset);
    }

    if (stats.symlinks > 0) {
        try out.writeAll(", ");
        if (!opts.no_color) try out.writeAll(Color.bright_cyan);
        try out.print("{d} symlink{s}", .{ stats.symlinks, if (stats.symlinks == 1) "" else "s" });
        if (!opts.no_color) try out.writeAll(Color.reset);
    }

    if (opts.show_size and stats.total_size > 0) {
        var sb: [32]u8 = undefined;
        const ss = formatSize(stats.total_size, &sb);
        try out.writeAll(" (");
        if (!opts.no_color) try out.writeAll(Color.bright_yellow);
        try out.print("{s} total", .{ss});
        if (!opts.no_color) try out.writeAll(Color.reset);
        try out.writeByte(')');
    }

    try out.writeByte('\n');
}
