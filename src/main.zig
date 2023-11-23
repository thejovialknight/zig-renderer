// TODO: Here's a broad overview agenda for what to do next.
//
// * Implement better triangle rasterizer. Perhaps doesn't need to be final,
//   but should at least stop the freezes if possible
//
// * Implement depth buffer
//
// * Try out alternate coordinate systems to try to gain more intuitive understanding.
//   This means seeing what changes require changes in other places. Make sure that
//   the above refactor takes into account how to make this change the easiest, which
//   will mean defining constants or something for repeated numbers, or something.
//
// * Speed up triangle rasterization enough to be performant. Hopefully no threading
//   required, as that would be nice to do later.
//
// * Implement texture maps
//
// * Take stock of performance and see if we can implement threading and other techniques
//   to get things to a playable game state of any kind.
//
// *?At some point in here figure out whether aspect ratios are still fucking up
//   the projection.

const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));
const obj = @import("obj_loader.zig");

const Platform = @import("platform.zig").Platform;
const Canvas = @import("draw.zig").Canvas;
const World = @import("world.zig").World;
const Input = @import("input.zig").Input;

const CANVAS_WIDTH = @import("draw.zig").WIDTH;
const CANVAS_HEIGHT = @import("draw.zig").HEIGHT;

const clear = @import("draw.zig").clear;
const load_mesh = @import("mesh.zig").load_mesh;
const render_world_to_canvas = @import("render.zig").render_world_to_canvas;
const present_canvas_to_platform = @import("platform.zig").present_canvas_to_surface;
const initialize_platform = @import("platform.zig").init;
const poll_platform_events = @import("platform.zig").poll_events;
const cleanup_platform = @import("platform.zig").cleanup;
const initialize_input = @import("input.zig").init;
const update_input = @import("input.zig").update;
const initialize_world = @import("world.zig").init;
const update_world = @import("world.zig").update;

pub fn main() !void {
    var canvas: Canvas = .{}; // Implicitly sets canvas size
    clear(&canvas);

    var platform: Platform = .{};
    initialize_platform(&platform, &canvas);

    var input: Input = .{};
    initialize_input(&input);

    var world: World = .{};
    initialize_world(&world, &platform);

    loop: while (true) {
        poll_platform_events(&platform);
        if(platform.quit) break :loop;
        update_input(&platform, &input);

        update_world(&world, &input);

        render_world_to_canvas(&world, &canvas);
        present_canvas_to_platform(&canvas, platform.window, platform.surface);
    }

    cleanup_platform(&platform);
}
