-- ============================================================
-- SYSTEM INVADERS (Memory Optimized Edition)
-- Lupi Game API (480x270 @ 60 FPS)
-- ============================================================

Palette = {
    0x0000, 0x03E0, 0x0120, 0x001F, 0x03FF, 0x7C00, 0x7FE0, 0x7FFF
}

local GAME_STATE = "PLAYING"

-- Player (blue team)
local player = { x = 210, y = 245, hp = 100, score = 0 }

-- Pools fixas de tiros (sem table.insert/remove para evitar garbage collection)
local MAX_P_BULLETS = 8
local p_bullets = {}
for i = 1, MAX_P_BULLETS do p_bullets[i] = { x = 0, y = 0, active = false } end

local MAX_E_BULLETS = 12
local e_bullets = {}
for i = 1, MAX_E_BULLETS do e_bullets[i] = { x = 0, y = 0, active = false } end

-- Inimigos fixos (24 no total)
local enemies = {}
for i = 1, 24 do enemies[i] = { x = 0, y = 0, type = 1, alive = false } end

local enemy_dir = 1
local enemy_speed = 0.5
local anim_frame = 1

local ENEMY_TYPES = {
    { score = 30, a1 = "<{o}>", a2 = "<{x}>" },
    { score = 20, a1 = "~(o)~", a2 = "=(o)=" },
    { score = 10, a1 = "[R#X]", a2 = "[R!X]" }
}

-- Firewalls fixos (4 nós)
local firewalls = {}
for i = 1, 4 do firewalls[i] = { x = 0, y = 210, hp = 12 } end

function init_game()
    GAME_STATE = "PLAYING"
    player.x = 210
    player.hp = 100
    player.score = 0

    -- Limpa tiros
    for i = 1, MAX_P_BULLETS do p_bullets[i].active = false end
    for i = 1, MAX_E_BULLETS do e_bullets[i].active = false end

    -- Reset inimigos (3 linhas x 8 colunas)
    local idx = 1
    for row = 1, 3 do
        for col = 1, 8 do
            local e = enemies[idx]
            e.x = 30 + (col - 1) * 50
            e.y = 35 + (row - 1) * 22
            e.type = row
            e.alive = true
            idx = idx + 1
        end
    end

    -- Reset firewalls
    for i = 1, 4 do
        firewalls[i].x = 60 + (i - 1) * 105
        firewalls[i].hp = 12
    end
end

init_game()

-- Função disparada a cada frame
function update(frame)
    -- Palette registration
    for i = 1, 8 do ui.palset(i - 1, Palette[i]) end
    ui.cls(0)

    -- Background decorativo
    for y = 0, 270, 20 do ui.line(0, y, 480, y, 2) end
    ui.rect(2, 2, 477, 267, 1)

    if GAME_STATE == "PLAYING" then
        -- Controle Player
        if ui.btn(0) then player.x = player.x - 3 end -- LEFT
        if ui.btn(1) then player.x = player.x + 3 end -- RIGHT
        player.x = ui.mid(10, player.x, 410)

        -- Disparo Player
        if ui.btnp(4) or ui.btnp(5) then -- BTN_Z ou BTN_X
            for i = 1, MAX_P_BULLETS do
                if not p_bullets[i].active then
                    p_bullets[i].x = player.x + 28
                    p_bullets[i].y = player.y - 6
                    p_bullets[i].active = true
                    break
                end
            end
        end

        -- Atualizar Tiros do Player
        for i = 1, MAX_P_BULLETS do
            local b = p_bullets[i]
            if b.active then
                b.y = b.y - 5
                if b.y < 20 then b.active = false end
            end
        end

        -- Atualizar Tiros dos Inimigos
        for i = 1, MAX_E_BULLETS do
            local b = e_bullets[i]
            if b.active then
                b.y = b.y + 3
                if b.y > 260 then b.active = false end
            end
        end

        -- Atualizar Inimigos
        if frame % 30 == 0 then anim_frame = (anim_frame == 1) and 2 or 1 end
        local move_x = enemy_dir * enemy_speed
        local hit_edge = false
        local alive_count = 0

        for i = 1, 24 do
            local e = enemies[i]
            if e.alive then
                alive_count = alive_count + 1
                e.x = e.x + move_x
                if e.x > 420 or e.x < 10 then hit_edge = true end

                -- Chance de tiro inimigo
                if math.random(1, 400) == 1 then
                    for j = 1, MAX_E_BULLETS do
                        if not e_bullets[j].active then
                            e_bullets[j].x = e.x + 15
                            e_bullets[j].y = e.y + 10
                            e_bullets[j].active = true
                            break
                        end
                    end
                end

                if e.y >= 200 then GAME_STATE = "GAMEOVER" end
            end
        end

        if alive_count == 0 then GAME_STATE = "WIN" end

        if hit_edge then
            enemy_dir = -enemy_dir
            for i = 1, 24 do enemies[i].y = enemies[i].y + 8 end
        end

        -- Checar Colisões
        -- Tiro Player vs Inimigo
        for i = 1, MAX_P_BULLETS do
            local pb = p_bullets[i]
            if pb.active then
                for j = 1, 24 do
                    local e = enemies[j]
                    if e.alive and pb.x >= e.x and pb.x <= e.x + 35 and pb.y >= e.y and pb.y <= e.y + 15 then
                        e.alive = false
                        pb.active = false
                        player.score = player.score + ENEMY_TYPES[e.type].score
                        break
                    end
                end
            end
        end

        -- Tiros vs Firewalls
        for i = 1, 4 do
            local fw = firewalls[i]
            if fw.hp > 0 then
                for j = 1, MAX_P_BULLETS do
                    local pb = p_bullets[j]
                    if pb.active and pb.x >= fw.x and pb.x <= fw.x + 50 and pb.y >= fw.y and pb.y <= fw.y + 12 then
                        fw.hp = fw.hp - 1
                        pb.active = false
                    end
                end
                for j = 1, MAX_E_BULLETS do
                    local eb = e_bullets[j]
                    if eb.active and eb.x >= fw.x and eb.x <= fw.x + 50 and eb.y >= fw.y and eb.y <= fw.y + 12 then
                        fw.hp = fw.hp - 1
                        eb.active = false
                    end
                end
            end
        end

        -- Tiro Inimigo vs Player
        for i = 1, MAX_E_BULLETS do
            local eb = e_bullets[i]
            if eb.active and eb.x >= player.x and eb.x <= player.x + 60 and eb.y >= player.y and eb.y <= player.y + 10 then
                player.hp = player.hp - 20
                eb.active = false
                if player.hp <= 0 then GAME_STATE = "GAMEOVER" end
            end
        end

    elseif ui.btnp(4) or ui.btnp(5) then
        init_game()
    end

    -- Desenhar Elementos
    for i = 1, 4 do
        local fw = firewalls[i]
        if fw.hp > 0 then
            ui.print("[FW::NET] " .. fw.hp, fw.x, fw.y, (fw.hp > 6) and 1 or 6)
        end
    end

    ui.print("[===A===]", player.x, player.y, 3)

    for i = 1, 24 do
        local e = enemies[i]
        if e.alive then
            local t = ENEMY_TYPES[e.type]
            ui.print((anim_frame == 1) and t.a1 or t.a2, e.x, e.y, 5)
        end
    end

    for i = 1, MAX_P_BULLETS do
        if p_bullets[i].active then ui.print("|", p_bullets[i].x, p_bullets[i].y, 4) end
    end

    for i = 1, MAX_E_BULLETS do
        if e_bullets[i].active then ui.print("v", e_bullets[i].x, e_bullets[i].y, 5) end
    end

    -- UI Top Bar
    ui.rectfill(0, 0, 480, 16, 0)
    ui.line(0, 16, 480, 16, 1)
    ui.print("SYS_SEC v1.0", 10, 4, 1)
    ui.print("SCORE: " .. player.score, 140, 4, 1)
    ui.print("KERNEL: " .. player.hp .. "%", 280, 4, (player.hp > 40) and 3 or 5)

    if GAME_STATE == "GAMEOVER" then
        ui.rectfill(80, 90, 400, 170, 0)
        ui.rect(80, 90, 400, 170, 5)
        ui.print("[!] CRITICAL SYSTEM FAILURE [!]", 110, 110, 5)
        ui.print("PRESS [Z] TO REBOOT SYSTEM", 130, 140, 1)
    elseif GAME_STATE == "WIN" then
        ui.rectfill(80, 90, 400, 170, 0)
        ui.rect(80, 90, 400, 170, 3)
        ui.print("[+] THREAT NEUTRALIZED [+]", 130, 110, 3)
        ui.print("PRESS [Z] TO INITIALIZE NEW SCAN", 105, 140, 1)
    end
end