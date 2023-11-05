pub fn swap(comptime T: type, a: *T, b: *T) void {
    const init_a: T = a.*;
    a.* = b.*;
    b.* = init_a;
}
