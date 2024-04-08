const std = @import("std");
const rl = @import("raylib");
const timer = @import("timer.zig");

const ShipType = enum {
    Enemy,
    Player,
};

const playerColor = rl.Color{ .r = 15, .g = 198, .b = 47, .a = 255 };
const enemyColor = rl.Color.red;

/// A ship consists of 4 points.
/// The nose point will be the tip of the ship.
/// It also has 2 points behind itself simetricly in a manner of a triagle
/// But for aestetic reasons it will have a 4th point in the same y axes as the nose as a concave
///
/// It has two variants:
/// - `EnemyShip` for the enemies the player has to defeate
/// - `PlayerShip` for the player to control
fn Ship(comptime shipType: ShipType) type {
    return struct {
        const Self = @This();

        nose: rl.Vector2,

        // The Enemy-variant of the Ship will need to have:
        // - repeating timer for it to know when to shoot
        // (to be fair it is absolutelly not necessairy here - especially the loop_count - but I just wanted to try)
        shootTimer: switch (shipType) {
            .Enemy => timer.RepeateTimer,
            .Player => u0,
        } = undefined,

        pub usingnamespace switch (shipType) {
            .Enemy => struct {
                pub fn loop_count(self: *Self) u64 {
                    const loop_counter = self.*.shootTimer.loop_count();

                    return loop_counter;
                }
            },
            .Player => struct {},
        };

        const tailNoseDistance: rl.Vector2 = switch (shipType) {
            .Player => .{ .x = 80, .y = 40 },
            .Enemy => .{ .x = -40, .y = 35 },
        };

        const noseConcavDistance: rl.Vector2 = switch (shipType) {
            .Player => .{ .x = 50, .y = 0 },
            .Enemy => .{ .x = -20, .y = 0 },
        };

        pub fn draw(self: Self) void {
            // Set the appierance of the bullet based on its variant:
            const drawColor = switch (shipType) {
                .Player => playerColor,
                .Enemy => enemyColor,
            };
            const thickness = switch (shipType) {
                .Enemy => 3.0,
                .Player => 4.20,
            };
            const nose = self.nose;
            const tail1 = rl.Vector2{ .x = nose.x - tailNoseDistance.x, .y = nose.y - tailNoseDistance.y };
            const tail2 = rl.Vector2{ .x = nose.x - tailNoseDistance.x, .y = nose.y + tailNoseDistance.y };

            // Calculate the points of the ship:
            const concav = rl.Vector2{
                .x = nose.x - noseConcavDistance.x,
                .y = nose.y + noseConcavDistance.y,
            };

            rl.drawLineEx(nose, tail1, thickness, drawColor);
            rl.drawLineEx(nose, tail2, thickness, drawColor);
            rl.drawLineEx(tail1, concav, thickness, drawColor);
            rl.drawLineEx(tail2, concav, thickness, drawColor);
        }

        pub fn colisionWithLine(self: Self, midPoint: rl.Vector2, length: f32) bool {
            // This will be the line we will check the collision for:
            const pointA = rl.Vector2{ .x = midPoint.x - (length / 2), .y = midPoint.y };
            const pointB = rl.Vector2{ .x = midPoint.x + (length / 2), .y = midPoint.y };

            // These three points will define the two lines we will check the collision agains:
            // nose -> tail1
            // nose -> tail2
            const nose = self.nose;
            const tail1 = rl.Vector2{ .x = nose.x - tailNoseDistance.x, .y = nose.y - tailNoseDistance.y };
            const tail2 = rl.Vector2{ .x = nose.x - tailNoseDistance.x, .y = nose.y + tailNoseDistance.y };

            return lineIntersection(pointA, pointB, nose, tail1) or
                lineIntersection(pointA, pointB, nose, tail2);
        }
    };
}

// helper function to detect if two lines are colliding (should be moved to math lib):
// Formula: https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
fn lineIntersection(l1_start: rl.Vector2, l1_end: rl.Vector2, l2_start: rl.Vector2, l2_end: rl.Vector2) bool {
    const denominator = ((l2_end.y - l2_start.y) * (l1_end.x - l1_start.x)) - ((l2_end.x - l2_start.x) * (l1_end.y - l1_start.y));
    const numerator1 = ((l2_end.x - l2_start.x) * (l1_start.y - l2_start.y)) - ((l2_end.y - l2_start.y) * (l1_start.x - l2_start.x));
    const numerator2 = ((l1_end.x - l1_start.x) * (l1_start.y - l2_start.y)) - ((l1_end.y - l1_start.y) * (l1_start.x - l2_start.x));

    if (denominator == 0) return (numerator1 == 0) and (numerator2 == 0);

    const r = numerator1 / denominator;
    const s = numerator2 / denominator;

    return (0 <= r and r <= 1) and (0 <= s and s <= 1);
}

/// A ship consists of 4 points.
/// The nose point will be the tip of the ship.
/// It also has 2 points behind itself simetricly in a manner of a triagle
/// But for aestetic reasons it will have a 4th point in the same y axes as the nose as a concave
///
/// It's a spectial variant of the private generic `Ship` type
pub const EnemyShip = Ship(ShipType.Enemy);

/// A ship consists of 4 points.
/// The nose point will be the tip of the ship.
/// It also has 2 points behind itself simetricly in a manner of a triagle
/// But for aestetic reasons it will have a 4th point in the same y axes as the nose as a concave
///
/// It's a spectial variant of the private generic `Ship` type
pub const PlayerShip = Ship(ShipType.Player);
