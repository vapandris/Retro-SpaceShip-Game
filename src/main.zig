const std = @import("std");
const rl = @import("raylib");

const bullet = @import("bullet.zig");
const ship = @import("ship.zig");
const timer = @import("timer.zig");

const EnemyBullet = bullet.EnemyBullet;
const PlayerBullet = bullet.PlayerBullet;

const EnemyShip = ship.EnemyShip;
const PlayerShip = ship.PlayerShip;

// TODO: GUI

// gloabal constants to represent the screen:
const screenWidth = 800;
const screenHeight = 450;

/// Struct containing every data in the game world:
const GameState = struct {
    playerShip: PlayerShip,
    enemyShips: std.ArrayList(EnemyShip),
    playerBullets: std.ArrayList(PlayerBullet),
    enemyBullets: std.ArrayList(EnemyBullet),

    enemySpawnTimer: timer.RepeateTimer,

    const enemyShootTimeMin_ms: u64 = 300;
    const enemyShootTimeMax_ms: u64 = 1500;
};

pub fn main() anyerror!void {
    // Init window and its settings:
    rl.initWindow(screenWidth, screenHeight, "Space invaders");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    // Init the game state and its members:
    var gameState: GameState = undefined;
    gameState.playerShip = .{
        .nose = .{ .x = 100, .y = screenHeight / 2 },
    };
    gameState.enemySpawnTimer = timer.RepeateTimer.start(1400);

    gameState.enemyShips = std.ArrayList(EnemyShip).init(std.heap.page_allocator);
    defer gameState.enemyShips.deinit();

    gameState.playerBullets = std.ArrayList(PlayerBullet).init(std.heap.page_allocator);
    defer gameState.playerBullets.deinit();

    gameState.enemyBullets = std.ArrayList(EnemyBullet).init(std.heap.page_allocator);
    defer gameState.enemyBullets.deinit();

    // Main game loop
    while (!rl.windowShouldClose()) {
        { // Process input:
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and gameState.playerShip.nose.y > 0) {
                gameState.playerShip.nose.y -= 5;
            } else if (rl.isKeyDown(rl.KeyboardKey.key_s) and gameState.playerShip.nose.y < screenHeight) {
                gameState.playerShip.nose.y += 5;
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
                try gameState.playerBullets.append(PlayerBullet{
                    .midPoint = .{
                        .x = gameState.playerShip.nose.x + 20,
                        .y = gameState.playerShip.nose.y,
                    },
                });
            }
        }

        { // Check for bullet-enemyShip collisions
            var i: u32 = 0;

            while (i < gameState.playerBullets.items.len) {
                var j: u32 = 0;
                var playerBullet = &gameState.playerBullets.items[i];
                while (j < gameState.enemyShips.items.len) {
                    var enemyShip = &gameState.enemyShips.items[j];

                    if (enemyShip.colisionWithLine(playerBullet.*.midPoint, PlayerBullet.length)) {
                        _ = gameState.enemyShips.swapRemove(j);
                        _ = gameState.playerBullets.swapRemove(i);
                    }
                    j += 1;
                }
                i += 1;
            }
        }

        { // Check for bullet-playerShip collision
            var i: u32 = 0;
            const playerShip = gameState.playerShip;

            while (i < gameState.enemyBullets.items.len) {
                var enemyBullet = &gameState.enemyBullets.items[i];

                if (playerShip.colisionWithLine(enemyBullet.*.midPoint, EnemyBullet.length)) {
                    _ = gameState.enemyBullets.swapRemove(i);

                    // TODO: This is really bad, fix it in the future :)
                    rl.closeWindow();
                }

                i += 1;
            }
        }

        { // move bullets:
            var i: u32 = 0;
            while (i < gameState.playerBullets.items.len) {
                var playerBullet = &gameState.playerBullets.items[i];
                const isBulletOutOfScope = playerBullet.*.midPoint.x > screenWidth * 1.2;

                if (isBulletOutOfScope) {
                    _ = gameState.playerBullets.swapRemove(i);
                }
                playerBullet.move();

                i += 1;
            }

            i = 0;
            while (i < gameState.enemyBullets.items.len) {
                var enemyBullet = &gameState.enemyBullets.items[i];
                const isBulletOutOfScope = enemyBullet.*.midPoint.x < -50;

                if (isBulletOutOfScope) {
                    _ = gameState.enemyBullets.swapRemove(i);
                }

                enemyBullet.move();

                i += 1;
            }
        }

        { // move EnemyShips & make them shoot bullet if timer is up:
            var i: u32 = 0;
            while (i < gameState.enemyShips.items.len) {
                var enemyShip = &gameState.enemyShips.items[i];

                // move:
                if (enemyShip.*.nose.x < -50) {
                    _ = gameState.enemyShips.swapRemove(i);
                }

                enemyShip.*.nose.x -= 5;

                // shoot:
                if (enemyShip.*.loop_count() > 0) {
                    const randomShootTimer = std.crypto.random.intRangeAtMost(
                        u64,
                        GameState.enemyShootTimeMin_ms,
                        GameState.enemyShootTimeMax_ms,
                    );
                    enemyShip.*.shootTimer.period_ms = randomShootTimer;

                    try gameState.enemyBullets.append(EnemyBullet{
                        .midPoint = .{ .x = enemyShip.*.nose.x - 10, .y = enemyShip.*.nose.y },
                    });
                }

                i += 1;
            }
        }

        // Create new enemy playerShip every few seconds:
        if (gameState.enemySpawnTimer.loop_count() > 0) {
            const rnd = std.crypto.random.intRangeAtMost(i32, 15, screenHeight - 15);
            const posY: f32 = @floatFromInt(rnd);

            const randomShootTimer = std.crypto.random.intRangeAtMost(
                u64,
                GameState.enemyShootTimeMin_ms,
                GameState.enemyShootTimeMax_ms,
            );
            try gameState.enemyShips.append(EnemyShip{
                .nose = .{ .x = screenWidth + 10, .y = posY },
                .shootTimer = timer.RepeateTimer.start(randomShootTimer),
            });
        }

        //-----------------
        // Draw
        //-----------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color{
            .r = 10,
            .g = 10,
            .b = 10,
            .a = 255,
        });

        // draw playerShip:
        gameState.playerShip.draw();

        // draw enemyShips:
        for (gameState.enemyShips.items) |enemyShip| {
            enemyShip.draw();
        }
        // draw bullets:
        for (gameState.playerBullets.items) |playerBullet| {
            playerBullet.draw();
        }
        for (gameState.enemyBullets.items) |enemyBullets| {
            enemyBullets.draw();
        }
    }
}
