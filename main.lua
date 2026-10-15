
-- SPACE INVADERS: CIRCULAR DEFENSE
-- LEFT / RIGHT: girar a nave
-- B: atirar / reiniciar

local W, H = 480, 270
local CX, CY = 240, 135

local BLACK  = 0
local BLUE   = 1
local RED    = 2
local WHITE  = 3
local GREEN  = 4
local YELLOW = 5

local palette = {
    [0] = 0x0000,
    [1] = 0x7C00,
    [2] = 0x001F,
    [3] = 0x7FFF,
    [4] = 0x03E0,
    [5] = 0x7FE0
}

local FIRE_BUTTON = BTN_Z

local TURN_SPEED = 0.055
local BULLET_SPEED = 4

local INITIAL_ENEMY_SPEED = 0.45
local ENEMY_SPEED_INCREASE = 0.05
local POINTS_PER_LEVEL = 500

local ENEMY_SPEED = INITIAL_ENEMY_SPEED

local MAX_ENEMIES = 6
local MAX_BULLETS = 8

local angle = -math.pi / 2
local score = 0
local highScore = 0
local tick = 0
local shootCooldown = 0
local gameOver = false

local vx = {0, 0, 0}
local vy = {0, 0, 0}

-- Desenha um triangulo preenchido
local function drawTriangle(x, y, a, size, color)
    local tipX = x + math.cos(a) * size
    local tipY = y + math.sin(a) * size

    local backX = x - math.cos(a) * size * 0.65
    local backY = y - math.sin(a) * size * 0.65

    local sideX = math.cos(a + math.pi / 2) * size * 0.65
    local sideY = math.sin(a + math.pi / 2) * size * 0.65

    vx[1] = tipX
    vy[1] = tipY

    vx[2] = backX + sideX
    vy[2] = backY + sideY

    vx[3] = backX - sideX
    vy[3] = backY - sideY

    local minY = math.floor(math.min(vy[1], vy[2], vy[3]))
    local maxY = math.ceil(math.max(vy[1], vy[2], vy[3]))

    for py = minY, maxY do
        local left = 9999
        local right = -9999

        for i = 1, 3 do
            local j = i % 3 + 1
            local y1 = vy[i]
            local y2 = vy[j]

            if py >= math.min(y1, y2)
            and py < math.max(y1, y2)
            and y1 ~= y2 then

                local xHit = vx[i] +
                    (py - y1) * (vx[j] - vx[i]) / (y2 - y1)

                if xHit < left then left = xHit end
                if xHit > right then right = xHit end
            end
        end

        if left <= right then
            ui.rectfill(
                math.floor(left), py,
                math.ceil(right), py,
                color
            )
        end
    end
end

-- Calcula a direcao de um ponto para outro
local function angleTo(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    if dx > 0 then
        return math.atan(dy / dx)
    elseif dx < 0 then
        return math.atan(dy / dx) + math.pi
    elseif dy >= 0 then
        return math.pi / 2
    else
        return -math.pi / 2
    end
end

local enemies = {}

local function respawnEnemy(e)
    local a = math.random() * math.pi * 2
    local radius = 105 + math.random() * 25

    e.x = CX + math.cos(a) * radius
    e.y = CY + math.sin(a) * radius
    e.alive = true
end

for i = 1, MAX_ENEMIES do
    enemies[i] = {
        x = 0,
        y = 0,
        alive = true
    }

    respawnEnemy(enemies[i])
end

local bullets = {}

for i = 1, MAX_BULLETS do
    bullets[i] = {
        x = 0,
        y = 0,
        dx = 0,
        dy = 0,
        active = false
    }
end

local function resetGame()
    angle = -math.pi / 2
    score = 0
    tick = 0
    shootCooldown = 0
    gameOver = false

    -- Reinicia a velocidade dos inimigos
    ENEMY_SPEED = INITIAL_ENEMY_SPEED

    -- O High Score permanece entre as partidas
    for i = 1, MAX_ENEMIES do
        respawnEnemy(enemies[i])
    end

    for i = 1, MAX_BULLETS do
        bullets[i].active = false
    end
end

local function shoot()
    for i = 1, MAX_BULLETS do
        local b = bullets[i]

        if not b.active then
            b.x = CX + math.cos(angle) * 12
            b.y = CY + math.sin(angle) * 12
            b.dx = math.cos(angle) * BULLET_SPEED
            b.dy = math.sin(angle) * BULLET_SPEED
            b.active = true
            return
        end
    end
end

function loop(frame)
    tick = tick + 1

    for i = 0, 5 do
        ui.palset(i, palette[i])
    end

    ui.cls(BLACK)

    ui.print("CIRCULAR DEFENSE", 175, 8, GREEN)
    ui.print("SCORE:", 12, 8, WHITE)
    ui.print(tostring(score), 60, 8, YELLOW)

    ui.print("BEST:", 350, 8, WHITE)
    ui.print(tostring(highScore), 400, 8, YELLOW)

    if gameOver then
        ui.print("SYSTEM FAILURE", 174, 105, RED)
        ui.print("PRESS B TO RESTART", 164, 125, WHITE)

        if ui.btnp(FIRE_BUTTON) then
            resetGame()
        end

        return
    end

    -- Girar a nave
    if ui.btn(LEFT) then
        angle = angle - TURN_SPEED
    end

    if ui.btn(RIGHT) then
        angle = angle + TURN_SPEED
    end

    -- Disparar
    if shootCooldown > 0 then
        shootCooldown = shootCooldown - 1
    end

    if ui.btn(FIRE_BUTTON) and shootCooldown == 0 then
        shoot()
        shootCooldown = 10
    end

    -- Atualizar velocidade conforme a pontuacao
    local level = math.floor(score / POINTS_PER_LEVEL)

    ENEMY_SPEED = INITIAL_ENEMY_SPEED
        + level * ENEMY_SPEED_INCREASE

    -- Inimigos avancam em direcao ao centro
    for i = 1, MAX_ENEMIES do
        local e = enemies[i]

        if e.alive then
            local dx = CX - e.x
            local dy = CY - e.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < 8 then
                gameOver = true

                if score > highScore then
                    highScore = score
                end
            else
                e.x = e.x + (dx / distance) * ENEMY_SPEED
                e.y = e.y + (dy / distance) * ENEMY_SPEED
            end
        end
    end

    -- Atualizar tiros e verificar colisoes
    for i = 1, MAX_BULLETS do
        local b = bullets[i]

        if b.active then
            b.x = b.x + b.dx
            b.y = b.y + b.dy

            if b.x < 0 or b.x >= W
            or b.y < 0 or b.y >= H then
                b.active = false
            else
                for j = 1, MAX_ENEMIES do
                    local e = enemies[j]

                    if e.alive then
                        local dx = b.x - e.x
                        local dy = b.y - e.y

                        if dx * dx + dy * dy < 64 then
                            respawnEnemy(e)
                            b.active = false
                            score = score + 10
                            break
                        end
                    end
                end
            end
        end
    end

    -- Desenhar inimigos
    for i = 1, MAX_ENEMIES do
        local e = enemies[i]

        if e.alive then
            local enemyAngle = angleTo(e.x, e.y, CX, CY)

            drawTriangle(e.x, e.y, enemyAngle, 7, RED)
        end
    end

    -- Desenhar projeteis
    for i = 1, MAX_BULLETS do
        local b = bullets[i]

        if b.active then
            ui.rectfill(
                b.x - 1, b.y - 1,
                b.x + 1, b.y + 1,
                GREEN
            )
        end
    end

    -- Jogador triangular fixo no centro
    drawTriangle(CX, CY, angle, 10, BLUE)

    -- Indicador da mira
    local tipX = CX + math.cos(angle) * 12
    local tipY = CY + math.sin(angle) * 12

    ui.rectfill(
        tipX - 1, tipY - 1,
        tipX + 1, tipY + 1,
        WHITE
    )
end
