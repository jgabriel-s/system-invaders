-- ============================================================
-- SYSTEM INVADERS (Primitives Edition)
-- Lupi Game API (480x270 @ 60 FPS)
-- ============================================================

local Palette = { 0x0000, 0x03E0, 0x0120, 0x001F, 0x03FF, 0x7C00, 0x7FE0, 0x7FFF }

-- Estado do Jogador (Nave Blue Team)
local px, py = 220, 245

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

-- Inimigos (6 Vírus Vermelhos)
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
    { x = 120, y = 205, hp = 6 },
    { x = 300, y = 205, hp = 6 }
}

function update(frame)
    -- 1. Registro de Paleta
    for i = 1, 8 do ui.palset(i - 1, Palette[i]) end
    ui.cls(0)

    -- 2. Movimentação e Disparo do Jogador
    if ui.btn(0) then px = px - 3 end -- LEFT
    if ui.btn(1) then px = px + 3 end -- RIGHT
    px = ui.mid(10, px, 430)

    if ui.btnp(4) or ui.btnp(5) then -- BTN_Z / BTN_X
        for i = 1, 3 do
            if not pb[i].act then
                pb[i].x = px + 18
                pb[i].y = py - 4
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
                        eb[j].x = e.x + 12
                        eb[j].y = e.y + 12
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
                if e.act and pb[i].x >= e.x and pb[i].x <= e.x + 24 and pb[i].y >= e.y and pb[i].y <= e.y + 16 then
                    e.act = false
                    pb[i].act = false