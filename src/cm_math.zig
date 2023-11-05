pub fn iterate_looping(comptime T: type, initial: T, wrap_max: T) T {
    var v = initial;
    v += 1;
    if (v >= wrap_max) {
        v = 0;
    }
    return v;
}

pub fn max(comptime T: type, a: T, b: T) T {
    if(a > b) return a;
    return b;
}

pub fn min(comptime T: type, a: T, b: T) T {
    if(a < b) return a;
    return b;
}

pub fn max_in_array(comptime T: type, l: []T) T {
    var r: T = l[0];
    for(l) |v| {
        if(v > r) r = v;
    }
    return r;
}

pub fn min_in_array(comptime T: type, l: []T) T {
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

pub fn dot_v3(comptime T: type, v0: @Vector(3, T), v1: @Vector(3, T)) T {
    return v0[0] * v1[0] + v0[1] * v1[1] + v0[2] * v1[2];
}

pub fn cross_v3(v1: @Vector(3, f32), v2: @Vector(3, f32)) @Vector(3, f32) { 
    return .{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[0] * v2[2] - v1[2] * v2[0],
        v1[0] * v2[1] - v1[1] * v2[0]
    };
}

pub fn multmat_44_44(comptime T: type, m0: *const [4][4]f32, m1: *const [4][4]f32) [4][4]T {
    var result: [4][4]T = undefined;
    var m0_row: usize = 0;
    while(m0_row < 4) : (m0_row += 1) {
        var m1_col: usize = 0;
        while(m1_col < 4) : (m1_col += 1) {
            var sum: T = 0;
            var i: usize = 0;
            while(i < 4) : (i += 1) {
                sum += m0[m0_row][i] * m1[i][m1_col];
            }
            result[m0_row][m1_col] = sum;
        }
    }
    return result;
}

pub fn multmat_44_4(comptime T: type, m0: *const [4][4]f32, m1: *const [4]f32) [4]T {
    var result: [4]T = undefined;
    var i: usize = 0;
    while(i < 4) : (i += 1) {
        var sum: T = 0;
        var j: usize = 0;
        while(j < 4) : (j += 1) {
            sum += m0[i][j] * m1[j];
        }
        result[i] = sum;
    }
    return result;
}

pub fn multmat_44_3(comptime T: type, m0: *const [4][4]f32, m1: *const [3]f32) [3]T {
    const m1_4: [4]f32 = .{ m1[0], m1[1], m1[2], 1 };
    const result_4 = multmat_44_4(T, m0, &m1_4);
    return .{ result_4[0], result_4[1], result_4[2] };
}
