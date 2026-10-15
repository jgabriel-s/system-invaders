-- ============================================================
-- SYSTEM INVADERS (Ultra-Light Prototype)
-- Lupi Game API (480x270 @ 60 FPS)
-- ============================================================

local Palette = { 0x0000, 0x03E0, 0x0120, 0x001F, 0x03FF, 0x7C00, 0x7FE0, 0x7FFF }

-- Estado do Jogador
local px, py = 210, 245

-- Projéteis Reduzidos (Pool Fixo de 3 Tiros)
local pb = {
    { x = 0, y = 0, act = false },
    { x = 0, y = 0, act = false },
    { x = 0, y = 0, act = false }
}

local eb = {
    { x = 0, y = 0, act = false },
    { x = 0, y = 0, act = false },
    { x = 0, y = 0, act = false }
}

-- Inimigos Reduzidos (Apenas 6 Vírus)
local enemies = {
    { x = 40,  y = 40, act = true },
    { x = 100, y = 40, act = true },
    { x = 160, y = 40, act = true },
    { x = 220, y = 40, act = true },
    { x = 280, y = 40, act = true },
    { x = 340, y = 40, act = true }
}

local edir = 1
local anim = 1

-- Barreiras de Firewall (2 Módulos)
local fw = {
    { x = 120, y = 210, hp = 6 },
    { x = 280, y = 210, hp = 6 }
}

function update(frame)
    -- 1. Registo de Paleta
    for i = 1, 8 do ui.palset(i - 1, Palette[i]) end
    ui.cls(0)

    -- 2. Movimentação e Disparo do Jogador
    if ui.btn(0) then px = px - 3 end -- LEFT
    if ui.btn(1) then px = px + 3 end -- RIGHT
    px = ui.mid(10, px, 410)

    if ui.btnp(4) or ui.btnp(5) then -- BTN_Z / BTN_X
        for i = 1, 3 do
            if not pb[i].act then
                pb[i].x = px + 28
                pb[i].y = py - 6
                pb[i].act = true
                break
            end
        end
    end

    -- 3. Atualizar Tiros do Jogador
    for i = 1, 3 do
        if pb[i].act then
            pb[i].y = pb[i].y - 5
            if pb[i].y < 20 then pb[i].act = false end
        end
    end

    -- 4. Atualizar Tiros dos Inimigos
    for i = 1, 3 do
        if eb[i].act then
            eb[i].y = eb[i].y + 3
            if eb[i].y > 260 then eb[i].act = false end
        end
    end

    -- 5. Atualizar Inimigos
    if frame % 30 == 0 then anim = (anim == 1) and 2 or 1 end
    local edge = false

    for i = 1, 6 do
        local e = enemies[i]
        if e.act then
            e.x = e.x + (edir * 0.5)
            if e.x > 430 or e.x < 10 then edge = true end

            -- Disparo Inimigo Aleatório
            if math.random(1, 300) == 1 then
                for j = 1, 3 do
                    if not eb[j].act then
                        eb[j].x = e.x + 15
                        eb[j].y = e.y + 10
                        eb[j].act = true
                        break
                    end
                end
            end
        end
    end

    if edge then
        edir = -edir
        for i = 1, 6 do enemies[i].y = enemies[i].y + 6 end
    end

    -- 6. Colisões
    for i = 1, 3 do
        if pb[i].act then
            for j = 1, 6 do
                local e = enemies[j]
                if e.act and pb[i].x >= e.x and pb[i].x <= e.x + 35 and pb[i].y >= e.y and pb[i].y <= e.y + 15 then
                    e.act = false
                    pb[i].act = false
                    break
                end
            end
        end
    end

    for i = 1, 2 do
        if fw[i].hp > 0 then
            for j = 1, 3 do
                if pb[j].act and pb[j].x >= fw[i].x and pb[j].x <= fw[i].x + 40 and pb[j].y >= fw[i].y and pb[j].y <= fw[i].y + 12 then
                    fw[i].hp = fw[i].hp - 1
                    pb[j].act = false
                end
                if eb[j].act and eb[j].x >= fw[i].x and eb[j].x <= fw[i].x + 40 and eb[j].y >= fw[i].y and eb[j].y <= fw[i].y + 12 then
                    fw[i].hp = fw[i].hp - 1
                    eb[j].act = false
                end
            end
        end
    end

    -- 7. Desenho dos Elementos
    ui.print("[===A===]", px, py, 3)

    for i = 1, 6 do
        if enemies[i].act then
            ui.print((anim == 1) and "<{o}>" or "<{x}>", enemies[i].x, enemies[i].y, 5)
        end
    end

    for i = 1, 2 do
        if fw[i].hp > 0 then
            ui.print("[FW::NET]", fw[i].x, fw[i].y, 1)
        end
    end

    for i = 1, 3 do
        if pb[i].act then ui.print("|", pb[i].x, pb[i].y, 4) end
        if eb[i].act then ui.print("v", eb[i].x, eb[i].y, 5) end
    end

    -- Top Bar
    ui.line(0, 16, 480, 16, 1)
    ui.print("SYS_INVADERS // PROTO", 10, 4, 1)
end