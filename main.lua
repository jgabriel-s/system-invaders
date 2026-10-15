
require "palette"
require "sprites"

local background = require "lupi_background"

local WIDTH = 480
local HEIGHT = 270

local COLOR_BG = 0
local COLOR_GREEN = 11
local COLOR_DARK_GREEN = 12

-- Objetos do jogo
local player = {
    x = 240,
    y = 225,
    speed = 3,
    width = 15,
    height = 13,
    lives = 3,
    cooldown = 0,
    invulnerable = 0
}

local enemies = {}
local bullets = {}

local score = 0
local game_over = false
local spawn_timer = 0

-- Cria um inimigo
local function create_enemy()
    local enemy = {
        x = 18 + math.random(0, WIDTH - 36),
        y = -12,
        speed = 1 + math.random() * 1.2,
        width = 13,
        height = 10,
        alive = true
    }

    table.insert(enemies, enemy)
end

-- Cria um projétil
local function shoot()
    table.insert(bullets, {
        x = player.x,
        y = player.y - 10,
        speed = 5,
        alive = true
    })
end

-- Verifica colisão entre dois retângulos
local function overlaps(a, b)
    return math.abs(a.x - b.x) < (a.width + b.width) / 2
       and math.abs(a.y - b.y) < (a.height + b.height) / 2
end

-- Desenha a nave do jogador
local function draw_player()
    if player.invulnerable > 0 and math.floor(player.invulnerable / 5) % 2 == 0 then
        return
    end

    -- Corpo triangular
    ui.trisfill(
        player.x, player.y - 9,
        player.x - 8, player.y + 6,
        player.x + 8, player.y + 6,
        COLOR_GREEN
    )

    -- Cabine
    ui.rectfill(
        player.x - 2, player.y - 1,
        player.x + 2, player.y + 3,
        COLOR_DARK_GREEN
    )

    -- Motores
    ui.rectfill(player.x - 6, player.y + 6, player.x - 3, player.y + 9, COLOR_GREEN)
    ui.rectfill(player.x + 3, player.y + 6, player.x + 6, player.y + 9, COLOR_GREEN)
end

-- Desenha um inimigo
local function draw_enemy(enemy)
    -- Corpo
    ui.rectfill(
        enemy.x - 6, enemy.y - 4,
        enemy.x + 6, enemy.y + 4,
        COLOR_GREEN
    )

    -- Asas
    ui.trisfill(
        enemy.x - 6, enemy.y,
        enemy.x - 11, enemy.y + 5,
        enemy.x - 4, enemy.y + 3,
        COLOR_GREEN
    )

    ui.trisfill(
        enemy.x + 6, enemy.y,
        enemy.x + 11, enemy.y + 5,
        enemy.x + 4, enemy.y + 3,
        COLOR_GREEN
    )

    -- Núcleo escuro
    ui.rectfill(
        enemy.x - 2, enemy.y - 2,
        enemy.x + 2, enemy.y + 2,
        COLOR_DARK_GREEN
    )
end

-- Atualiza o jogo
local function update_game(frame)
    -- Movimento
    if ui.btn(LEFT) then
        player.x = player.x - player.speed
    end

    if ui.btn(RIGHT) then
        player.x = player.x + player.speed
    end

    if ui.btn(UP) then
        player.y = player.y - player.speed
    end

    if ui.btn(DOWN) then
        player.y = player.y + player.speed
    end

    -- Mantém a nave dentro da tela
    player.x = ui.mid(9, player.x, WIDTH - 9)
    player.y = ui.mid(14, player.y, HEIGHT - 10)

    -- Disparo: botão Z
    if player.cooldown > 0 then
        player.cooldown = player.cooldown - 1
    end

    if ui.btn(BTN_Z) and player.cooldown == 0 then
        shoot()
        player.cooldown = 12
    end

    -- Invulnerabilidade temporária após colisão
    if player.invulnerable > 0 then
        player.invulnerable = player.invulnerable - 1
    end

    -- Gera inimigos periodicamente
    spawn_timer = spawn_timer + 1

    local spawn_interval = math.max(20, 55 - math.floor(score / 50))

    if spawn_timer >= spawn_interval then
        spawn_timer = 0
        create_enemy()
    end

    -- Atualiza projéteis
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.y = bullet.y - bullet.speed

        if bullet.y < -5 then
            table.remove(bullets, i)
        end
    end

    -- Atualiza inimigos e testa colisões
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy.y = enemy.y + enemy.speed

        -- Inimigo chegou ao fundo
        if enemy.y > HEIGHT + 12 then
            table.remove(enemies, i)

        else
            -- Colisão entre nave e inimigo
            if player.invulnerable == 0 and overlaps(player, enemy) then
                player.lives = player.lives - 1
                player.invulnerable = 90
                table.remove(enemies, i)

                if player.lives <= 0 then
                    game_over = true
                end
            else
                -- Colisão entre projéteis e inimigos
                for j = #bullets, 1, -1 do
                    local bullet = bullets[j]

                    local bullet_box = {
                        x = bullet.x,
                        y = bullet.y,
                        width = 3,
                        height = 6
                    }

                    if overlaps(bullet_box, enemy) then
                        table.remove(bullets, j)
                        table.remove(enemies, i)
                        score = score + 10
                        break
                    end
                end
            end
        end
    end
end

-- Desenha todos os objetos
local function draw_game()
    -- Imagem original convertida em pixels
    ui.grid(0, 0, 1, 1, background)

    for _, bullet in ipairs(bullets) do
        ui.rectfill(
            bullet.x - 1, bullet.y - 3,
            bullet.x + 1, bullet.y + 3,
            COLOR_GREEN
        )
    end

    for _, enemy in ipairs(enemies) do
        draw_enemy(enemy)
    end

    draw_player()

    ui.print("PONTOS: " .. score, 8, 8, COLOR_GREEN)
    ui.print("VIDAS: " .. player.lives, 8, 20, COLOR_GREEN)
    ui.print("Z: ATIRAR", 390, 8, COLOR_GREEN)
end

-- Reinicia o jogo
local function reset_game()require "palette"
require "sprites"

local background = require "lupi_background"

function loop(frame)
    
    
end 
    player.x = 240
    player.y = 225
    player.lives = 3
    player.cooldown = 0
    player.invulnerable = 0

    enemies = {}
    bullets = {}

    score = 0
    spawn_timer = 0
    game_over = false
end

-- Loop principal do Lupi
function update(frame)
    -- Registra a paleta a cada frame
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    -- Garante as cores usadas pelo fundo e pelos objetos
    ui.palset(COLOR_BG, 0x0000)
    ui.palset(COLOR_GREEN, 0x03E0)
    ui.palset(COLOR_DARK_GREEN, 0x01A0)

    ui.clip(0, 0, WIDTH, HEIGHT)
    ui.camera(0, 0)
    ui.cls(COLOR_BG)

    if game_over then
        ui.print("SISTEMA DESTRUIDO", 155, 105, COLOR_GREEN)
        ui.print("PONTUACAO: " .. score, 180, 125, COLOR_GREEN)
        ui.print("APERTE X PARA REINICIAR", 140, 150, COLOR_GREEN)

        if ui.btnp(BTN_X) then
            reset_game()
        end

        return
    end

    update_game(frame)
    draw_game()
end
