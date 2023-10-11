pub fn draw_triangle(v0: [2]f32, v1: [2]f32, v2: [2]f32, color: colors.Color, canvas: *Canvas) void {
    const x0: i32 = @intFromFloat(16 * v0[0]);
    const x1: i32 = @intFromFloat(16 * v1[0]);
    const x2: i32 = @intFromFloat(16 * v2[0]);
    const y0: i32 = @intFromFloat(16 * v0[1]);
    const y1: i32 = @intFromFloat(16 * v1[1]);
    const y2: i32 = @intFromFloat(16 * v2[1]);

    // Deltas for line equation precalculation
    const dx01: i32 = x0 - x1;
    const dx12: i32 = x1 - x2;
    const dx20: i32 = x2 - x0;
    const dy01: i32 = y0 - y1;
    const dy12: i32 = y1 - y2;
    const dy20: i32 = y2 - y0;
    // Fixed point deltas
    const fdx01: i32 = dx01 << 4;
    const fdx12: i32 = dx12 << 4;
    const fdx20: i32 = dx20 << 4;
    const fdy01: i32 = dy01 << 4;
    const fdy12: i32 = dy12 << 4;
    const fdy20: i32 = dy20 << 4;

    // Bounding rect
    var xvals: [3]i32 = .{ x0, x1, x2 }; // Declaration because min_in_array and max_...
    var yvals: [3]i32 = .{ y0, y1, y2 }; // require already initialized array
    const xmin: i32 = (utils.min_in_array(i32, &xvals) + 0xF) >> 4;
    const xmax: i32 = (utils.max_in_array(i32, &xvals) + 0xF) >> 4;
    const ymin: i32 = (utils.min_in_array(i32, &yvals) + 0xF) >> 4;
    const ymax: i32 = (utils.max_in_array(i32, &yvals) + 0xF) >> 4;

    // c = constant parts of line equation
    var c0: i32 = dy01 * x0 - dx01 * y0;
    var c1: i32 = dy12 * x1 - dx12 * y1;
    var c2: i32 = dy20 * x2 - dx20 * y2;

    // Make calculation equivelant to >= 0 by adding 1,
    // but only in the case of this being the top left line.
    // This is the common convention to prevent gaps
    if(dy01 < 0 or (dy01 == 0 and dx01 > 0)) c0 += 1;
    if(dy12 < 0 or (dy12 == 0 and dx12 > 0)) c1 += 1;
    if(dy20 < 0 or (dy20 == 0 and dx20 > 0)) c2 += 1;

    // Starting values of function at top of bounding rect
    var cy0: i32 = c0 + dx01 * (ymin << 4) - dy01 * (xmin << 4);
    var cy1: i32 = c1 + dx12 * (ymin << 4) - dy12 * (xmin << 4);
    var cy2: i32 = c2 + dx20 * (ymin << 4) - dy20 * (xmin << 4);

    var py: i32 = ymin;
    while(py < ymax) : (py += 1) {
        // Starting values of function per horizontal scan
        var cx0: i32 = cy0;
        var cx1: i32 = cy1;
        var cx2: i32 = cy2;

        var px: i32 = xmin;
        while(px < xmax) : (px += 1) {
            if(cx0 > 0 and cx1 > 0 and cx2 > 0) {
                draw_pixel(px, py, color, canvas);
            }

            cx0 -= fdy01;
            cx1 -= fdy12;
            cx2 -= fdy20;
        }

        cy0 += fdx01;
        cy1 += fdx12;
        cy2 += fdx20;
    }
}
