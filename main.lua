
-- SPACE INVADERS: CIRCULAR DEFENSE
-- Jogador fixo no centro
-- LEFT / RIGHT: girar
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
local ENEMY_SPEED = 0.45
local MAX_ENEMIES = 12
local MAX_BULLETS = 8

local angle = -math.pi / 2
local score = 0
local tick = 0
local shootCooldown = 0
local gameOver = false

-- Reutiliza os mesmos objetos de inimigos
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

-- Projéteis criados uma única vez
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

    if gameOver then
        ui.print("SYSTEM FAILURE", 174, 105, RED)
        ui.print("PRESS B TO RESTART", 164, 125, WHITE)

        if ui.btnp(FIRE_BUTTON) then
            resetGame()
        end

        return
    end

    -- Girar a nave sem deslocar o jogador
    if ui.btn(LEFT) then
        angle = angle - TURN_SPEED
    end

    if ui.btn(RIGHT) then
        angle = angle + TURN_SPEED
    end

    -- Disparo com intervalo entre tiros
    if shootCooldown > 0 then
        shootCooldown = shootCooldown - 1
    end

    if ui.btn(FIRE_BUTTON) and shootCooldown == 0 then
        shoot()
        shootCooldown = 10
    end

    -- Atualizar inimigos
    for i = 1, MAX_ENEMIES do
        local e = enemies[i]

        if e.alive then
            local dx = CX - e.x
            local dy = CY - e.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < 8 then
                gameOver = true
            else
                e.x = e.x + (dx / distance) * ENEMY_SPEED
                e.y = e.y + (dy / distance) * ENEMY_SPEED
            end
        end
    end

    -- Atualizar projéteis e verificar colisões
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
                            -- Reposiciona o inimigo derrotado
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
            ui.rectfill(
                e.x - 4, e.y - 4,
                e.x + 4, e.y + 4,
                RED
            )

            ui.rectfill(
                e.x - 2, e.y - 1,
                e.x - 1, e.y,
                WHITE
            )

            ui.rectfill(
                e.x + 2, e.y - 1,
                e.x + 3, e.y,
                WHITE
            )
        end
    end

    -- Desenhar projéteis
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

    -- Jogador fixo no centro
    ui.rectfill(
        CX - 5, CY - 5,
        CX + 5, CY + 5,
        BLUE
    )

    -- Indicador de direção da nave
    local tipX = CX + math.cos(angle) * 13
    local tipY = CY + math.sin(angle) * 13

    ui.rectfill(
        tipX - 2, tipY - 2,
        tipX + 2, tipY + 2,
        WHITE
    )
end