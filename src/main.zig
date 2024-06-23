const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn sqrt(value: u128) usize {
    var result: u128 = 0;
    var bit: u128 = 1 << 63; // Start with the highest bit for u128

    while (bit > 0) {
        result |= bit; // Set current bit in result
        const squared = result * result;
        if (squared > value) {
            result ^= bit; // Unset current bit if the square is too high
        }
        bit >>= 1;
    }

    return @intCast(result);
}

const BitMap = struct {
    bitmap: []u256,

    pub fn init(a: *std.mem.Allocator, length: usize) !BitMap {
        var arr = try a.alloc(u256, length);
        for (0..length) |i| {
            arr[i] = 0;
        }

        return BitMap{ .bitmap = arr };
    }

    pub fn set(self: *BitMap, idx: usize) void {
        const div: usize = @intCast(idx / 256);
        const rem: u8 = @intCast(idx % 256);
        var val:u256 = 1;
        val <<= rem;

        self.bitmap[div] |= val;
    }

    pub fn check(self: BitMap, idx: usize) bool {
        const div: usize = @intCast(idx / 256);
        const rem: u8 = @intCast(idx % 256);

        var mask: u256 = 1;
        mask <<= rem;
        return (self.bitmap[div] & mask) != 0;
    }
};

pub fn main() !void {
    var a = gpa.allocator();

    const n: u128 = 1_000_000_000;
    const n_sqrt = sqrt(n);
    const len = n / (3 * 256) + 1;

    std.debug.print("n: {}\n", .{n});
    std.debug.print("len: {}\n", .{len});

    var primes: BitMap = try BitMap.init(&a, len);
    defer a.free(primes.bitmap);

    const start_time = std.time.nanoTimestamp();

    var i: usize = 5;
    while (i <= n_sqrt) {
        if (!primes.check(i / 3 - 1)) {
            var idx = i * i;
            var cnt: usize = 0;

            while (idx <= n) {
                primes.set(idx / 3 - 1);
                if (cnt & 1 == 0) {
                    idx += 2 * i;
                } else {
                    idx += 4 * i;
                }
                cnt += 1;
            }
        }

        i += 2;

        if (!primes.check(i / 3 - 1)) {
            var idx = i * i;
            var cnt: usize = 0;

            while (idx < n_sqrt) {
                primes.set(idx / 3 - 1);
                if (cnt & 1 == 0) {
                    idx += 4 * i;
                } else {
                    idx += 2 * i;
                }
                cnt += 1;
            }
        }

        i += 4;
    }

    const end_time = std.time.nanoTimestamp();
    const elapsed_time = end_time - start_time;

    std.debug.print("Elapsed time: {} ns\n", .{elapsed_time});
}
