const std = @import("std");

pub const RepeateTimer = struct {
    timer: std.time.Timer,
    period_ms: u64, // period in milliseconds

    fn convertMilliSecToNanoSec(ms: u64) u64 {
        return ms * 1000000;
    }

    /// Starts a RepeatingTimer with period_ms periodicity in milliseconds
    /// If supported clock cannot be found by Operating System, function panics.
    pub fn start(period_ms: u64) RepeateTimer {
        var result: RepeateTimer = undefined;
        result.timer = std.time.Timer.start() catch {
            std.debug.panic("Could not find Timer from Operating System!", .{});
        };
        result.period_ms = period_ms;

        return result;
    }

    /// Returns how many laps have happened between timer.started and timer.previous based on the periond_ms.
    /// (This way it can be used with a loop pretty well to compensate for lag (I didn't though))
    /// If it laped, than reset timer.
    /// If it returns 0, than it has not lapped yet.
    pub fn loop_count(self: *RepeateTimer) u64 {
        const since = self.*.timer.read();
        const result = @divFloor(since, convertMilliSecToNanoSec(self.*.period_ms));

        if (result > 0) {
            self.*.timer.reset();
        }

        return result;
    }
};
