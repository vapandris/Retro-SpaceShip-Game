const std = @import("std");
const rl = @import("raylib");

const BulletType = enum {
    Enemy,
    Player,
};

const playerColor = rl.Color{ .r = 15, .g = 198, .b = 47, .a = 255 };
const enemyColor = rl.Color.red;

fn Bullet(comptime bulletType: BulletType) type {
    return struct {
        const Self = @This();

        midPoint: rl.Vector2,

        pub const length = switch (bulletType) {
            .Player => 30,
            .Enemy => 20,
        };

        pub fn draw(self: Self) void {
            // Set the appierance of the bullet based on its variant:
            const drawColor = switch (bulletType) {
                .Player => playerColor,
                .Enemy => enemyColor,
            };
            const thickness = switch (bulletType) {
                .Player => 4.20,
                .Enemy => 3.00,
            };

            // Calculate the start and end position of the bullet:
            const start = rl.Vector2{
                .x = self.midPoint.x - (length / 2),
                .y = self.midPoint.y,
            };
            const end = rl.Vector2{
                .x = self.midPoint.x + (length / 2),
                .y = self.midPoint.y,
            };

            rl.drawLineEx(start, end, thickness, drawColor);
        }

        pub fn move(self: *Self) void {
            const moveSpeed = switch (bulletType) {
                .Player => 10,
                .Enemy => -10,
            };

            self.*.midPoint.x += moveSpeed;
        }
    };
}

pub const EnemyBullet = Bullet(BulletType.Enemy);
pub const PlayerBullet = Bullet(BulletType.Player);

/// GeneralBullet type when you want to store these bullets in the same container
/// Both Bullet variant take up the same place, so this shouldn't cause any problem.. hopefully :)
pub const GeneralBullet = union {
    enemyBullet: EnemyBullet,
    playerBullet: PlayerBullet,
};
