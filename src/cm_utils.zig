pub fn iterate_looping(comptime T: type, initial: T, wrap_max: T) T {
    var v = initial;
    v += 1;
    if (v >= wrap_max) {
        v = 0;
    }
    return v;
}

pub fn swap(comptime T: type, a: *T, b: *T) void {
    const init_a: T = a.*;
    a.* = b.*;
    b.* = init_a;
}

pub fn max(comptime T: type, a: T, b: T) T {
    if(a > b) return a;
    return b;
}

pub fn min(comptime T: type, a: T, b: T) T {
    if(a < b) return a;
    return b;
}

// TODO: come back once error conventions have been more figured out
// Same with min_in_array
pub fn max_in_array(comptime T: type, l: []T) T {
    // if(l.len == 0) return error { EmptyArray, };
    var r: T = l[0];
    for(l) |v| {
        if(v > r) r = v;
    }
    return r;
}

pub fn min_in_array(comptime T: type, l: []T) T {
    // if(l.len == 0) return error { EmptyArray, };
    var r: T = l[0];
    for(l) |v| {
        if(v < r) r = v;
    }
    return r;
}

pub fn abs(comptime T: type, n: T) T {
    if(n > 0) return n;
    return -n;
}
