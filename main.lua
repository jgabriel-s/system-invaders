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

    -- 7. Renderização com Primitivas Gráficas

    -- Firewalls (Blocos Verdes em Degradê por Dano)
    for i = 1, 2 do
        if fw[i].hp > 0 then
            local col = (fw[i].hp > 3) and 1 or 6
            ui.rectfill(fw[i].x, fw[i].y, fw[i].x + 40, fw[i].y + 10, col)
            ui.rect(fw[i].x, fw[i].y, fw[i].x + 40, fw[i].y + 10, 7)
        end
    end

    -- Nave Blue Team (Formato Geométrico Azul)
    ui.rectfill(px, py + 4, px + 36, py + 10, 3)     -- Base
    ui.trisfill(px + 12, py + 4, px + 24, py + 4, px + 18, py - 2, 4) -- Ponta da Nave

    -- Vírus Red Team (Formato Losango/Inimigo Pulsante)
    for i = 1, 6 do
        local e = enemies[i]
        if e.act then
            if anim == 1 then
                -- Frame 1: Losango Vermelho com Centro Claro
                ui.trisfill(e.x + 12, e.y, e.x, e.y + 8, e.x + 24, e.y + 8, 5)
                ui.trisfill(e.x, e.y + 8, e.x + 24, e.y + 8, e.x + 12, e.y + 16, 5)
                ui.circfill(e.x + 12, e.y + 8, 2, 7)
            else
                -- Frame 2: Quadrado Rotacionado
                ui.rectfill(e.x + 4, e.y + 2, e.x + 20, e.y + 14, 5)
                ui.rect(e.x + 2, e.y, e.x + 22, e.y + 16, 6)
            end
        end
    end

    -- Tiros do Player (Cyan)
    for i = 1, 3 do
        if pb[i].act then
            ui.rectfill(pb[i].x, pb[i].y, pb[i].x + 2, pb[i].y + 6, 4)
        end
    end

    -- Tiros Inimigos (Vermelho)
    for i = 1, 3 do
        if eb[i].act then
            ui.circfill(eb[i].x, eb[i].y, 3, 5)
        end
    end

    -- Linha Superior do HUD
    ui.line(0, 16, 480, 16, 1)
end