pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub fn color_from_rgb(r: u8, g: u8, b: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = 255 };
}

pub fn white() Color {
    return color_from_rgb(255, 255, 255);
}

pub fn black() Color {
    return color_from_rgb(0, 0, 0);
}
