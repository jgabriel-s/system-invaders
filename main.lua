
-- SPACE INVADERS: CYBER WAR
-- RED TEAM: ataque / virus
-- BLUE TEAM: defesa / nave
-- Sem bibliotecas externas

local W, H = 480, 270

local BLACK  = 0
local BLUE   = 1
local RED    = 2
local WHITE  = 3
local GREEN  = 4
local YELLOW = 5

local palette = {
    [0] = 0x0000,
    [1] = 0x001F,
    [2] = 0x7C00,
    [3] = 0x7FFF,
    [4] = 0x03E0,
    [5] = 0x7FE0
}

local PLAYER_SPEED = 3
local BULLET_SPEED = 5
local ENEMY_BULLET_SPEED = 2
local SCORE_CAP = 500

local player = {
    x = 232,
    y = 238,
    w = 16,
    h = 12
}

local playerBullets = {}
for i = 1, 3 do
    playerBullets[i] = {x = 0, y = 0, active = false}
end

local enemyBullets = {}
for i = 1, 4 do
    enemyBullets[i] = {x = 0, y = 0, active = false}
end

local enemies = {}
for row = 1, 3 do
    for col = 1, 4 do
        local i = (row - 1) * 4 + col
        enemies[i] = {
            x = 65 + (col - 1) * 85,
            y = 48 + (row - 1) * 28,
            alive = true
        }
    end
end

local score = 0
local tick = 0
local shootCooldown = 0
local enemyDirection = 1
local enemyShotIndex = 1
local gameOver = false
local victory = false

local function resetGame()
    player.x = 232
    player.y = 238

    score = 0
    tick = 0
    shootCooldown = 0
    enemyDirection = 1
    enemyShotIndex = 1
    gameOver = false
    victory = false

    for row = 1, 3 do
        for col = 1, 4 do
            local i = (row - 1) * 4 + col
            enemies[i].x = 65 + (col - 1) * 85
            enemies[i].y = 48 + (row - 1) * 28
            enemies[i].alive = true
        end
    end

    for i = 1, 3 do
        playerBullets[i].active = false
    end

    for i = 1, 4 do
        enemyBullets[i].active = false
    end
end

function loop(frame)
    tick = tick + 1

    for i = 0, 5 do
        ui.palset(i, palette[i])
    end

    ui.cls(BLACK)

    -- INTERFACE HACKER
    ui.rect(5, 5, 474, 264, BLUE)
    ui.rectfill(8, 8, 471, 31, BLUE)
    ui.print("CYBER WAR // DEFENSE SYSTEM", 95, 16, WHITE)

    -- Barra de alerta
    ui.rectfill(8, 35, 471, 49, RED)
    ui.print("WARNING: RED TEAM INTRUSION", 110, 39, WHITE)

    -- Indicadores
    ui.print("RED TEAM: ATTACK", 20, 56, RED)
    ui.print("BLUE TEAM: DEFENSE", 260, 56, BLUE)

    ui.print("SCORE", 365, 72, GREEN)
    ui.print(tostring(score), 420, 72, WHITE)

    -- Linhas de terminal nas laterais
    ui.print("> FIREWALL ACTIVE", 15, 91, GREEN)
    ui.print("> VIRUS DETECTED", 15, 105, RED)
    ui.print("> DEFEND CORE", 15, 119, BLUE)

    ui.print("MOVE: LEFT / RIGHT", 325, 105, WHITE)
    ui.print("FIRE: Z", 365, 119, YELLOW)

    -- Tela final
    if gameOver or victory then
        ui.rectfill(65, 91, 415, 184, BLACK)
        ui.rect(65, 91, 415, 184, BLUE)

        if victory then
            ui.print("SYSTEM SECURE", 175, 112, GREEN)
            ui.print("RED TEAM ELIMINATED", 145, 135, WHITE)
        else
            ui.print("SYSTEM BREACHED", 165, 112, RED)
            ui.print("BLUE TEAM OFFLINE", 155, 135, WHITE)
        end

        ui.print("PRESS B TO RESTART", 160, 160, YELLOW)

        -- BTN_Z representa o botao B neste esquema de controles
        if ui.btnp(BTN_Z) then
            resetGame()
        end

        return
    end

    -- MOVIMENTO BLUE TEAM
    if ui.btn(LEFT) then
        player.x = player.x - PLAYER_SPEED
    end

    if ui.btn(RIGHT) then
        player.x = player.x + PLAYER_SPEED
    end

    if player.x < 12 then
        player.x = 12
    end

    if player.x > W - player.w - 12 then
        player.x = W - player.w - 12
    end

    -- Disparo da defesa
    if shootCooldown > 0 then
        shootCooldown = shootCooldown - 1
    end

    if ui.btn(BTN_Z) and shootCooldown == 0 then
        for i = 1, 3 do
            local b = playerBullets[i]

            if not b.active then
                b.x = player.x + 7
                b.y = player.y - 4
                b.active = true
                shootCooldown = 12
                break
            end
        end
    end

    -- RED TEAM AVANCA
    local hitEdge = false

    for i = 1, 12 do
        local e = enemies[i]

        if e.alive then
            e.x = e.x + enemyDirection

            if e.x < 55 or e.x > 440 then
                hitEdge = true
            end
        end
    end

    if hitEdge then
        enemyDirection = -enemyDirection

        for i = 1, 12 do
            local e = enemies[i]

            if e.alive then
                e.y = e.y + 5

                if e.y >= player.y - 8 then
                    gameOver = true
                end
            end
        end
    end

    -- Projeteis azuis e colisao com virus
    for i = 1, 3 do
        local b = playerBullets[i]

        if b.active then
            b.y = b.y - BULLET_SPEED

            if b.y < 35 then
                b.active = false
            else
                for j = 1, 12 do
                    local e = enemies[j]

                    if e.alive
                    and b.x >= e.x
                    and b.x <= e.x + 18
                    and b.y >= e.y
                    and b.y <= e.y + 12 then

                        e.alive = false
                        b.active = false

                        if score < SCORE_CAP then
                            score = score + 10
                        end

                        break
                    end
                end
            end
        end
    end

    -- RED TEAM DISPARA contra a defesa
    if tick % 35 == 0 then
        for attempt = 1, 12 do
            local idx = ((enemyShotIndex + attempt - 2) % 12) + 1
            local e = enemies[idx]

            if e.alive then
                for slot = 1, 4 do
                    local b = enemyBullets[slot]

                    if not b.active then
                        b.x = e.x + 8
                        b.y = e.y + 12
                        b.active = true
                        enemyShotIndex = idx % 12 + 1
                        break
                    end
                end

                break
            end
        end
    end

    -- Projeteis vermelhos e colisao com a nave
    for i = 1, 4 do
        local b = enemyBullets[i]

        if b.active then
            b.y = b.y + ENEMY_BULLET_SPEED

            if b.y > 250 then
                b.active = false
            elseif b.x >= player.x
            and b.x <= player.x + player.w
            and b.y >= player.y
            and b.y <= player.y + player.h then

                b.active = false
                gameOver = true
            end
        end
    end

    -- DESENHO DA NAVE BLUE TEAM
    ui.rectfill(player.x + 5, player.y,
                player.x + 10, player.y + 3, WHITE)
    ui.rectfill(player.x + 2, player.y + 4,
                player.x + 13, player.y + 8, BLUE)
    ui.rectfill(player.x, player.y + 9,
                player.x + 15, player.y + 11, BLUE)

    -- DESENHO DOS VIRUS RED TEAM
    local remaining = 0

    for i = 1, 12 do
        local e = enemies[i]

        if e.alive then
            remaining = remaining + 1

            ui.rectfill(e.x + 3, e.y,
                        e.x + 14, e.y + 3, RED)
            ui.rectfill(e.x, e.y + 4,
                        e.x + 17, e.y + 9, RED)
            ui.rectfill(e.x + 3, e.y + 10,
                        e.x + 6, e.y + 12, RED)
            ui.rectfill(e.x + 12, e.y + 10,
                        e.x + 15, e.y + 12, RED)

            ui.rectfill(e.x + 4, e.y + 5,
                        e.x + 6, e.y + 6, WHITE)
            ui.rectfill(e.x + 11, e.y + 5,
                        e.x + 13, e.y + 6, WHITE)
        end
    end

    -- Projeteis da defesa
    for i = 1, 3 do
        local b = playerBullets[i]

        if b.active then
            ui.rectfill(b.x, b.y, b.x + 2, b.y + 5, GREEN)
        end
    end

    -- Projeteis do ataque
    for i = 1, 4 do
        local b = enemyBullets[i]

        if b.active then
            ui.rectfill(b.x, b.y, b.x + 2, b.y + 5, RED)
        end
    end

    -- Status inferior
    ui.rectfill(8, 251, 471, 260, BLUE)
    ui.print("FIREWALL: ACTIVE // DEFEND THE CORE", 100, 253, WHITE)

    if remaining == 0 then
        victory = true
    end
end
