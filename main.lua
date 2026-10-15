
-- SPACE INVADERS: SYSTEM FAILURE
-- Versao otimizada para memoria
-- Blue Team vs Red Team
-- Controles: setas para mover, Z para atirar/reiniciar

local W, H = 480, 270

local PLAYER_SPEED = 3
local BULLET_SPEED = 5
local ENEMY_BULLET_SPEED = 2
local MAX_PLAYER_BULLETS = 3
local MAX_ENEMY_BULLETS = 4

local BLUE = 1
local RED = 2
local WHITE = 3
local BLACK = 0
local GREEN = 4
local YELLOW = 5

local palette = {
    [0] = "#080d18",
    [1] = "#36a9ff",
    [2] = "#ff3b54",
    [3] = "#e8f4ff",
    [4] = "#54ff9f",
    [5] = "#ffe66d"
}

-- Inimigos: 4 linhas x 5 colunas
local enemies = {}
for i = 1, 20 do
    local col = (i - 1) % 5
    local row = math.floor((i - 1) / 5)

    enemies[i] = {
        x = 55 + col * 78,
        y = 38 + row * 25,
        alive = true
    }
end

-- Projeteis com slots fixos: sem criar/remover tabelas durante o jogo
local bullets = {}
for i = 1, MAX_PLAYER_BULLETS do
    bullets[i] = { x = 0, y = 0, active = false }
end

local enemyBullets = {}
for i = 1, MAX_ENEMY_BULLETS do
    enemyBullets[i] = { x = 0, y = 0, active = false }
end

local player = {
    x = 228,
    y = 238,
    w = 24,
    h = 14
}

local score = 0
local lives = 3
local state = "playing"
local enemyDir = 1
local enemySpeed = 0.45
local tick = 0
local shootCooldown = 0
local enemyShootCooldown = 0

local function resetGame()
    player.x = 228
    score = 0
    lives = 3
    state = "playing"
    enemyDir = 1
    enemySpeed = 0.45
    tick = 0
    shootCooldown = 0
    enemyShootCooldown = 0

    for i = 1, 20 do
        local col = (i - 1) % 5
        local row = math.floor((i - 1) / 5)

        enemies[i].x = 55 + col * 78
        enemies[i].y = 38 + row * 25
        enemies[i].alive = true
    end

    for i = 1, MAX_PLAYER_BULLETS do
        bullets[i].active = false
    end

    for i = 1, MAX_ENEMY_BULLETS do
        enemyBullets[i].active = false
    end
end

local function spawnPlayerBullet()
    for i = 1, MAX_PLAYER_BULLETS do
        if not bullets[i].active then
            bullets[i].x = player.x + 11
            bullets[i].y = player.y - 4
            bullets[i].active = true
            return
        end
    end
end

local function spawnEnemyBullet()
    for i = 1, MAX_ENEMY_BULLETS do
        if not enemyBullets[i].active then
            -- Escolhe um inimigo vivo sem criar uma tabela nova
            local start = (math.floor(tick / 35) % 20) + 1

            for j = 0, 19 do
                local idx = ((start + j - 1) % 20) + 1
                local e = enemies[idx]

                if e.alive then
                    enemyBullets[i].x = e.x + 8
                    enemyBullets[i].y = e.y + 12
                    enemyBullets[i].active = true
                    return
                end
            end
            return
        end
    end
end

local function updatePlayer()
    if ui.btn(LEFT) then
        player.x = player.x - PLAYER_SPEED
    end

    if ui.btn(RIGHT) then
        player.x = player.x + PLAYER_SPEED
    end

    if player.x < 4 then
        player.x = 4
    end
    if player.x > W - player.w - 4 then
        player.x = W - player.w - 4
    end

    if shootCooldown > 0 then
        shootCooldown = shootCooldown - 1
    end

    if ui.btnp(BTN_Z) and shootCooldown <= 0 then
        spawnPlayerBullet()
        shootCooldown = 12
    end
end

local function updateBullets()
    for i = 1, MAX_PLAYER_BULLETS do
        local b = bullets[i]

        if b.active then
            b.y = b.y - BULLET_SPEED

            if b.y < 0 then
                b.active = false
            else
                for j = 1, 20 do
                    local e = enemies[j]

                    if e.alive
                    and b.x >= e.x and b.x <= e.x + 16
                    and b.y >= e.y and b.y <= e.y + 14 then
                        e.alive = false
                        b.active = false
                        score = score + 25
                        break
                    end
                end
            end
        end
    end

    for i = 1, MAX_ENEMY_BULLETS do
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
                lives = lives - 1

                if lives <= 0 then
                    state = "lost"
                end
            end
        end
    end
end

local function updateEnemies()
    local hitEdge = false
    local aliveCount = 0

    for i = 1, 20 do
        local e = enemies[i]

        if e.alive then
            aliveCount = aliveCount + 1
            e.x = e.x + enemyDir * enemySpeed

            if e.x <= 5 or e.x >= W - 21 then
                hitEdge = true
            end

            if e.y >= player.y - 12 then
                state = "lost"
            end
        end
    end

    if hitEdge then
        enemyDir = -enemyDir

        for i = 1, 20 do
            if enemies[i].alive then
                enemies[i].y = enemies[i].y + 5
            end
        end
    end

    if aliveCount == 0 then
        state = "won"
    end
end

local function drawPlayer()
    -- Nave azul desenhada com retangulos
    ui.rectfill(player.x + 9, player.y, 6, 4, BLUE)
    ui.rectfill(player.x + 5, player.y + 4, 14, 5, BLUE)
    ui.rectfill(player.x, player.y + 9, 24, 5, BLUE)
    ui.rectfill(player.x + 10, player.y + 5, 4, 3, WHITE)
end

local function drawEnemies()
    for i = 1, 20 do
        local e = enemies[i]

        if e.alive then
            -- Corpo vermelho
            ui.rectfill(e.x + 3, e.y, 10, 4, RED)
            ui.rectfill(e.x, e.y + 4, 16, 7, RED)
            ui.rectfill(e.x + 2, e.y + 11, 4, 3, RED)
            ui.rectfill(e.x + 10, e.y + 11, 4, 3, RED)

            -- Olhos
            ui.rectfill(e.x + 3, e.y + 5, 3, 3, WHITE)
            ui.rectfill(e.x + 10, e.y + 5, 3, 3, WHITE)
        end
    end
end

local function drawBullets()
    for i = 1, MAX_PLAYER_BULLETS do
        local b = bullets[i]
        if b.active then
            ui.rectfill(b.x, b.y, 2, 6, GREEN)
        end
    end

    for i = 1, MAX_ENEMY_BULLETS do
        local b = enemyBullets[i]
        if b.active then
            ui.rectfill(b.x, b.y, 3, 5, RED)
        end
    end
end

local function drawHUD()
    ui.print("BLUE TEAM", 8, 7, BLUE)
    ui.print("SCORE: " .. score, 180, 7, WHITE)
    ui.print("LIVES: " .. lives, 385, 7, GREEN)
    ui.line(8, 22, 472, 22, BLUE)
end

local function drawEndScreen()
    ui.rectfill(45, 75, 390, 115, BLACK)

    if state == "won" then
        ui.print("SYSTEM RESTORED", 157, 95, GREEN)
        ui.print("RED TEAM ELIMINATED", 145, 125, WHITE)
        ui.print("FINAL SCORE: " .. score, 174, 148, YELLOW)
    else
        ui.print("SYSTEM FAILURE", 163, 95, RED)
        ui.print("BLUE TEAM DESTROYED", 143, 125, WHITE)
        ui.print("FINAL SCORE: " .. score, 174, 148, YELLOW)
    end

    ui.print("PRESS Z TO RESTART", 160, 169, WHITE)
end

function update(frame)
    -- Paleta registrada em todo frame, conforme a API do Lupi
    for i = 0, 5 do
        ui.palset(i, palette[i])
    end

    ui.cls(BLACK)
    tick = tick + 1

    if state == "playing" then
        updatePlayer()
        updateBullets()
        updateEnemies()

        enemyShootCooldown = enemyShootCooldown + 1
        if enemyShootCooldown >= 35 then
            spawnEnemyBullet()
            enemyShootCooldown = 0
        end
    elseif ui.btnp(BTN_Z) then
        resetGame()
    end

    drawHUD()
    drawPlayer()
    drawEnemies()
    drawBullets()

    if state ~= "playing" then
        drawEndScreen()
    end
end
