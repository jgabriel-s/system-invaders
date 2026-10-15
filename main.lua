
-- SPACE INVADERS: SYSTEM FAILURE
-- Versao enxuta para testar no Lupi
-- Sem bibliotecas externas, sprites ou audio

local W, H = 480, 270

local BLACK  = 0
local BLUE   = 1
local RED    = 2
local WHITE  = 3
local GREEN  = 4
local YELLOW = 5

-- Cores RGB555 numericas
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

-- Tabelas de tamanho fixo: reutilizamos os objetos
local playerBullets = {}
for i = 1, 3 do
    playerBullets[i] = { x = 0, y = 0, active = false }
end

local enemyBullets = {}
for i = 1, 4 do
    enemyBullets[i] = { x = 0, y = 0, active = false }
end

local enemies = {}
for row = 1, 3 do
    for col = 1, 4 do
        local i = (row - 1) * 4 + col
        enemies[i] = {
            x = 65 + (col - 1) * 85,
            y = 35 + (row - 1) * 28,
            alive = true
        }
    end
end

local score = 0
local tick = 0
local shootCooldown = 0
local enemyDirection = 1
local enemyStep = 1
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
    enemyStep = 1
    enemyShotIndex = 1
    gameOver = false
    victory = false

    for row = 1, 3 do
        for col = 1, 4 do
            local i = (row - 1) * 4 + col
            enemies[i].x = 65 + (col - 1) * 85
            enemies[i].y = 35 + (row - 1) * 28
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

    -- A API exige configurar as cores a cada frame
    for i = 0, 5 do
        ui.palset(i, palette[i])
    end

    ui.cls(BLACK)

    -- Fundo simples
    ui.print("SYSTEM FAILURE", 8, 8, GREEN)
    ui.print("BLUE TEAM", 8, 20, BLUE)
    ui.print("SCORE:", 365, 8, WHITE)
    ui.print(tostring(score), 415, 8, YELLOW)

    -- Tela final
    if gameOver or victory then
        if victory then
            ui.print("SYSTEM RESTORED!", 165, 105, GREEN)
        else
            ui.print("BLUE TEAM OFFLINE", 155, 105, RED)
        end

        ui.print("PRESS B TO RESTART", 155, 125, WHITE)

        if ui.btnp(BTN_Z) then
            resetGame()
        end

        return
    end

    -- Movimento do jogador
    if ui.btn(LEFT) then
        player.x = player.x - PLAYER_SPEED
    end

    if ui.btn(RIGHT) then
        player.x = player.x + PLAYER_SPEED
    end

    if player.x < 0 then
        player.x = 0
    end

    if player.x > W - player.w then
        player.x = W - player.w
    end

    -- Disparo com intervalo, sem criar novos objetos
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

    -- Movimento dos inimigos
    local hitEdge = false

    for i = 1, 12 do
        local e = enemies[i]

        if e.alive then
            e.x = e.x + enemyDirection * enemyStep

            if e.x < 5 or e.x > W - 25 then
                hitEdge = true
            end
        end
    end

    if hitEdge then
        enemyDirection = -enemyDirection

        for i = 1, 12 do
            if enemies[i].alive then
                enemies[i].y = enemies[i].y + 5

                if enemies[i].y >= player.y - 8 then
                    gameOver = true
                end
            end
        end
    end

    -- Tiros do jogador e colisões
    for i = 1, 3 do
        local b = playerBullets[i]

        if b.active then
            b.y = b.y - BULLET_SPEED

            if b.y < 0 then
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

    -- Disparo inimigo periódico
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

    -- Tiros inimigos e colisão com o jogador
    for i = 1, 4 do
        local b = enemyBullets[i]

        if b.active then
            b.y = b.y + ENEMY_BULLET_SPEED

            if b.y > H then
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

    -- Desenho do jogador: nave azul com detalhes
    ui.rectfill(
        player.x + 5, player.y,
        player.x + 10, player.y + 3, WHITE
    )
    ui.rectfill(
        player.x + 2, player.y + 4,
        player.x + 13, player.y + 8, BLUE
    )
    ui.rectfill(
        player.x, player.y + 9,
        player.x + 15, player.y + 11, BLUE
    )

    -- Desenho dos vírus
    local remaining = 0

    for i = 1, 12 do
        local e = enemies[i]

        if e.alive then
            remaining = remaining + 1

            ui.rectfill(
                e.x + 3, e.y,
                e.x + 14, e.y + 3, RED
            )
            ui.rectfill(
                e.x, e.y + 4,
                e.x + 17, e.y + 9, RED
            )
            ui.rectfill(
                e.x + 3, e.y + 10,
                e.x + 6, e.y + 12, RED
            )
            ui.rectfill(
                e.x + 12, e.y + 10,
                e.x + 15, e.y + 12, RED
            )
            ui.rectfill(
                e.x + 4, e.y + 5,
                e.x + 6, e.y + 6, WHITE
            )
            ui.rectfill(
                e.x + 11, e.y + 5,
                e.x + 13, e.y + 6, WHITE
            )
        end
    end

    -- Desenho dos projéteis ativos
    for i = 1, 3 do
        local b = playerBullets[i]

        if b.active then
            ui.rectfill(b.x, b.y, b.x + 2, b.y + 5, GREEN)
        end
    end

    for i = 1, 4 do
        local b = enemyBullets[i]

        if b.active then
            ui.rectfill(b.x, b.y, b.x + 2, b.y + 5, RED)
        end
    end

    -- Vitória quando todos os vírus forem eliminados
    if remaining == 0 then
        victory = true
    end
end
