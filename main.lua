-- ============================================================
-- SYSTEM INVADERS (Cybersecurity Edition: Blue Team vs Red Team)
-- Developed for Lupi Game API (480x270 @ 60 FPS)
-- ============================================================

-- Regras da Paleta de Cores (RGB555)
-- Index 0: Fundo do Terminal (Preto Profundo)
-- Index 1: Verde Terminal Matrix / UI Texto (Bright Green)
-- Index 2: Verde Escuro Dimmed (Linhas de Grade/Grid)
-- Index 3: Azul Nave Blue Team (Cyan / Electric Blue)
-- Index 4: Azul Claro / Tiro Blue Team
-- Index 5: Vermelho Inimigo / Red Team (Threat Red)
-- Index 6: Amarelo / Alerta Firewall
-- Index 7: Branco Puro / Impactos e Brilho
Palette = {
    0x0000, -- 0: Black
    0x03E0, -- 1: Matrix Green (RGB: 0, 31, 0)
    0x0120, -- 2: Dark Terminal Green
    0x001F, -- 3: Blue Team Defense
    0x03FF, -- 4: Blue Light / Lasers
    0x7C00, -- 5: Red Team Malware
    0x7FE0, -- 6: Warning Yellow
    0x7FFF  -- 7: White
}

-- Estado do Jogo
local GAME_STATE = "PLAYING" -- PLAYING, GAMEOVER, WIN

-- Definição do Player (Blue Team Defense Node)
local player = {
    x = 210,
    y = 245,
    w = 60,
    h = 10,
    speed = 3,
    ascii = "[===A===]",
    hp = 100,
    score = 0
}

-- Projéteis da Defesa (Blue Team Lasers)
local player_bullets = {}

-- Projéteis dos Vírus (Red Team Attacks)
local enemy_bullets = {}

-- Inimigos (Red Team Malware Nodes)
local enemies = {}
local enemy_dir = 1
local enemy_step_down = false
local enemy_speed = 0.5
local anim_timer = 0
local anim_frame = 1

-- Tipos de Inimigos e suas ASCII Arts
local ENEMY_TYPES = {
    { name = "TROJAN",     score = 30, art = { "<{o}>", "<{x}>" } },
    { name = "WORM",       score = 20, art = { "~(o)~", "=(o)=" } },
    { name = "RANSOMWARE", score = 10, art = { "[R#X]", "[R!X]" } }
}

-- Firewalls Defensivos (Barreiras de Proteção)
local firewalls = {}

-- Inicialização do Grid de Inimigos e Firewalls
function init_game()
    GAME_STATE = "PLAYING"
    player.x = 210
    player.hp = 100
    player.score = 0
    player_bullets = {}
    enemy_bullets = {}
    enemies = {}
    firewalls = {}

    -- Spawn dos Inimigos (5 colunas x 3 linhas)
    for row = 1, 3 do
        for col = 1, 8 do
            table.insert(enemies, {
                x = 30 + (col - 1) * 50,
                y = 35 + (row - 1) * 22,
                type = row, -- 1=Trojan, 2=Worm, 3=Ransomware
                alive = true
            })
        end
    end

    -- Spawn dos Firewalls (4 nós de defesa)
    for i = 1, 4 do
        table.insert(firewalls, {
            x = 60 + (i - 1) * 105,
            y = 210,
            hp = 12,
            art = "[FW::NET]"
        })
    end
end

-- Chamado imediatamente no carregamento
init_game()

-- ============================================================
-- MAIN LOOP (60 FPS)
-- ============================================================
function update(frame)
    -- 1. Registrar Paleta de Cores (Obrigatório a cada frame na Lupi API)
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    -- Limpa a tela com o fundo preto do terminal
    ui.cls(0)

    -- Desenhar Efeito Visual de Fundo (Terminal Grid / Scanlines)
    draw_terminal_bg()

    if GAME_STATE == "PLAYING" then
        update_player()
        update_bullets()
        update_enemies(frame)
        check_collisions()
    elseif GAME_STATE == "GAMEOVER" or GAME_STATE == "WIN" then
        if ui.btnp(BTN_Z) or ui.btnp(BTN_X) then
            init_game()
        end
    end

    -- Renderização dos elementos
    draw_firewalls()
    draw_player()
    draw_enemies()
    draw_bullets()
    draw_hud(frame)
end

-- ============================================================
-- LÓGICA E ATUALIZAÇÕES
-- ============================================================

function update_player()
    -- Movimentação
    if ui.btn(LEFT) then player.x = player.x - player.speed end
    if ui.btn(RIGHT) then player.x = player.x + player.speed end

    -- Limitar à tela
    player.x = ui.mid(10, player.x, 410)

    -- Disparo (BTN_Z ou BTN_X)
    if ui.btnp(BTN_Z) or ui.btnp(BTN_X) then
        table.insert(player_bullets, { x = player.x + 28, y = player.y - 6 })
    end
end

function update_bullets()
    -- Atualizar Tiros do Jogador
    for i = #player_bullets, 1, -1 do
        local b = player_bullets[i]
        b.y = b.y - 5
        if b.y < 20 then
            table.remove(player_bullets, i)
        end
    end

    -- Atualizar Tiros Inimigos
    for i = #enemy_bullets, 1, -1 do
        local b = enemy_bullets[i]
        b.y = b.y + 3
        if b.y > 260 then
            table.remove(enemy_bullets, i)
        end
    end
end

function update_enemies(frame)
    anim_timer = anim_timer + 1
    if anim_timer % 30 == 0 then
        anim_frame = (anim_frame == 1) and 2 or 1
    end

    local move_x = enemy_dir * enemy_speed
    local hit_edge = false
    local alive_count = 0

    for _, e in ipairs(enemies) do
        if e.alive then
            alive_count = alive_count + 1
            e.x = e.x + move_x
            if e.x > 420 or e.x < 10 then
                hit_edge = true
            end

            -- Ataque aleatório dos vírus
            if math.random(1, 400) == 1 then
                table.insert(enemy_bullets, { x = e.x + 15, y = e.y + 10 })
            end

            -- Se invasão chegar no Firewall/Player
            if e.y >= 200 then
                GAME_STATE = "GAMEOVER"
            end
        end
    end

    if alive_count == 0 then
        GAME_STATE = "WIN"
    end

    if hit_edge then
        enemy_dir = -enemy_dir
        for _, e in ipairs(enemies) do
            e.y = e.y + 8
        end
    end
end

function check_collisions()
    -- Colisão: Tiro do Jogador vs Inimigos
    for i = #player_bullets, 1, -1 do
        local pb = player_bullets[i]
        for _, e in ipairs(enemies) do
            if e.alive and pb.x >= e.x and pb.x <= e.x + 35 and pb.y >= e.y and pb.y <= e.y + 15 then
                e.alive = false
                player.score = player.score + ENEMY_TYPES[e.type].score
                table.remove(player_bullets, i)
                break
            end
        end
    end

    -- Colisão: Tiro do Jogador vs Firewall
    for i = #player_bullets, 1, -1 do
        local pb = player_bullets[i]
        for _, fw in ipairs(firewalls) do
            if fw.hp > 0 and pb.x >= fw.x and pb.x <= fw.x + 50 and pb.y >= fw.y and pb.y <= fw.y + 12 then
                fw.hp = fw.hp - 1
                table.remove(player_bullets, i)
                break
            end
        end
    end

    -- Colisão: Tiro Inimigo vs Firewall
    for i = #enemy_bullets, 1, -1 do
        local eb = enemy_bullets[i]
        for _, fw in ipairs(firewalls) do
            if fw.hp > 0 and eb.x >= fw.x and eb.x <= fw.x + 50 and eb.y >= fw.y and eb.y <= fw.y + 12 then
                fw.hp = fw.hp - 1
                table.remove(enemy_bullets, i)
                break
            end
        end
    end

    -- Colisão: Tiro Inimigo vs Player
    for i = #enemy_bullets, 1, -1 do
        local eb = enemy_bullets[i]
        if eb.x >= player.x and eb.x <= player.x + 60 and eb.y >= player.y and eb.y <= player.y + 10 then
            player.hp = player.hp - 20
            table.remove(enemy_bullets, i)
            if player.hp <= 0 then
                GAME_STATE = "GAMEOVER"
            end
        end
    end
end

-- ============================================================
-- RENDERIZAÇÃO E GRÁFICOS ASCII
-- ============================================================

function draw_terminal_bg()
    -- Linhas sutis de grade do terminal (Verde escuro)
    for y = 0, 270, 15 do
        ui.line(0, y, 480, y, 2)
    end
    ui.rect(2, 2, 477, 267, 1) -- Moldura do terminal
end

function draw_player()
    -- Blue Team Node em Azul (Cor 3)
    ui.print(player.ascii, player.x, player.y, 3)
end

function draw_enemies()
    -- Red Team Viruses em Vermelho (Cor 5)
    for _, e in ipairs(enemies) do
        if e.alive then
            local art = ENEMY_TYPES[e.type].art[anim_frame]
            ui.print(art, math.floor(e.x), math.floor(e.y), 5)
        end
    end
end

function draw_bullets()
    -- Tiros do Player em Azul Cyan (Cor 4)
    for _, b in ipairs(player_bullets) do
        ui.print("|", b.x, b.y, 4)
    end

    -- Tiros Inimigos (Malware Payloads) em Vermelho (Cor 5)
    for _, b in ipairs(enemy_bullets) do
        ui.print("v", b.x, b.y, 5)
    end
end

function draw_firewalls()
    for _, fw in ipairs(firewalls) do
        if fw.hp > 0 then
            local col = (fw.hp > 6) and 1 or 6 -- Verde se saudável, Amarelo se danificado
            ui.print(fw.art .. " " .. fw.hp, fw.x, fw.y, col)
        end
    end
end

function draw_hud(frame)
    -- Top Bar: Status do Sistema
    ui.rectfill(0, 0, 480, 16, 0)
    ui.line(0, 16, 480, 16, 1)

    ui.print("SYS_SEC v1.0", 10, 4, 1)
    ui.print("SCORE: " .. player.score, 140, 4, 1)
    
    -- Barra de Integridade do Kernel (Blue Team HP)
    ui.print("KERNEL: " .. player.hp .. "%", 280, 4, (player.hp > 40) and 3 or 5)

    -- Telas de Game Over / Victory
    if GAME_STATE == "GAMEOVER" then
        ui.rectfill(80, 90, 400, 170, 0)
        ui.rect(80, 90, 400, 170, 5)
        ui.print("[!] CRITICAL SYSTEM FAILURE [!]", 110, 110, 5)
        ui.print("MALWARE OVERRUN DETECTED", 140, 130, 5)
        ui.print("PRESS [Z] TO REBOOT SYSTEM", 130, 150, 1)
    elseif GAME_STATE == "WIN" then
        ui.rectfill(80, 90, 400, 170, 0)
        ui.rect(80, 90, 400, 170, 3)
        ui.print("[+] THREAT NEUTRALIZED [+]", 130, 110, 3)
        ui.print("BLUE TEAM SECURED THE NETWORK", 120, 130, 1)
        ui.print("PRESS [Z] TO INITIALIZE NEW SCAN", 105, 150, 1)
    end
end