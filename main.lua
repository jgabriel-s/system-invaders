-- ============================================================
-- SYSTEM INVADERS (Static / No-Animation Edition)
-- Lupi Game API (480x270 @ 60 FPS)
-- ============================================================

local Palette = { 0x0000, 0x03E0, 0x0120, 0x001F, 0x03FF, 0x7C00, 0x7FE0, 0x7FFF }

-- Posição do Jogador
local px = 220

-- Máscara de bits para 6 inimigos (63 = todos vivos)
local enemies_mask = 63

-- Posições X fixas e estáticas dos 6 inimigos
local ex_pos = { 60, 115, 170, 225, 280, 335 }

-- Pools fixos de tiros (3 do Player, 3 dos Inimigos)
local pb = { {x=0, y=0, a=false}, {x=0, y=0, a=false}, {x=0, y=0, a=false} }
local eb = { {x=0, y=0, a=false}, {x=0, y=0, a=false}, {x=0, y=0, a=false} }

-- Firewalls (HP)
local fw1_hp, fw2_hp = 6, 6

function update(frame)
    -- 1. Registro de Paleta (Obrigatório Lupi API)
    for i = 1, 8 do ui.palset(i - 1, Palette[i]) end
    ui.cls(0)

    -- 2. Movimentação do Jogador
    if ui.btn(0) then px = px - 3 end -- LEFT
    if ui.btn(1) then px = px + 3 end -- RIGHT
    px = ui.mid(10, px, 430)

    -- Disparo do Jogador
    if ui.btnp(4) or ui.btnp(5) then
        for i = 1, 3 do
            if not pb[i].a then
                pb[i].x = px + 18
                pb[i].y = 241
                pb[i].a = true
                break
            end
        end
    end

    -- 3. Atualização dos Tiros
    for i = 1, 3 do
        if pb[i].a then
            pb[i].y = pb[i].y - 5
            if pb[i].y < 20 then pb[i].a = false end
        end
        if eb[i].a then
            eb[i].y = eb[i].y + 3
            if eb[i].y > 260 then eb[i].a = false end
        end
    end

    -- 4. Disparo Inimigo Estático (Intervalo fixo sem animações de movimento)
    if frame % 90 == 0 then
        for i = 1, 6 do
            local bit = 2 ^ (i - 1)
            if (enemies_mask % (bit * 2)) >= bit then
                for j = 1, 3 do
                    if not eb[j].a then
                        eb[j].x = ex_pos[i] + 12
                        eb[j].y = 52
                        eb[j].a = true
                        break
                    end
                end
                break
            end
        end
    end

    -- 5. Colisão Tiros vs Inimigos Estáticos (Y fixo em 40)
    for i = 1, 3 do
        if pb[i].a then
            for j = 1, 6 do
                local bit = 2 ^ (j - 1)
                if (enemies_mask % (bit * 2)) >= bit then
                    local ex = ex_pos[j]
                    if pb[i].x >= ex and pb[i].x <= ex + 24 and pb[i].y >= 40 and pb[i].y <= 56 then
                        enemies_mask = enemies_mask - bit
                        pb[i].a = false
                        break
                    end
                end
            end
        end
    end

    -- 6. Colisões Tiros vs Firewalls
    for i = 1, 3 do
        if fw1_hp > 0 then
            if pb[i].a and pb[i].x >= 120 and pb[i].x <= 160 and pb[i].y >= 205 and pb[i].y <= 217 then
                fw1_hp = fw1_hp - 1; pb[i].a = false
            end
            if eb[i].a and eb[i].x >= 120 and eb[i].x <= 160 and eb[i].y >= 205 and eb[i].y <= 217 then
                fw1_hp = fw1_hp - 1; eb[i].a = false
            end
        end
        if fw2_hp > 0 then
            if pb[i].a and pb[i].x >= 300 and pb[i].x <= 340 and pb[i].y >= 205 and pb[i].y <= 217 then
                fw2_hp = fw2_hp - 1; pb[i].a = false
            end
            if eb[i].a and eb[i].x >= 300 and eb[i].x <= 340 and eb[i].y >= 205 and eb[i].y <= 217 then
                fw2_hp = fw2_hp - 1; eb[i].a = false
            end
        end
    end

    -- 7. Renderização com Primitivas Estáticas

    -- Firewalls (Blocos Verdes Estáticos)
    if fw1_hp > 0 then
        ui.rectfill(120, 205, 160, 215, (fw1_hp > 3) and 1 or 6)
        ui.rect(120, 205, 160, 215, 7)
    end
    if fw2_hp > 0 then
        ui.rectfill(300, 205, 340, 215, (fw2_hp > 3) and 1 or 6)
        ui.rect(300, 205, 340, 215, 7)
    end

    -- Nave Blue Team
    ui.rectfill(px, 249, px + 36, 255, 3)
    ui.trisfill(px + 12, 249, px + 24, 249, px + 18, 243, 4)

    -- Inimigos Red Team (Desenho Estático Sem Alternância de Frames)
    for i = 1, 6 do
        local bit = 2 ^ (i - 1)
        if (enemies_mask % (bit * 2)) >= bit then
            local ex = ex_pos[i]
            ui.rectfill(ex + 4, 42, ex + 20, 54, 5)
            ui.rect(ex + 2, 40, ex + 22, 56, 6)
        end
    end

    -- Tiros
    for i = 1, 3 do
        if pb[i].a then ui.rectfill(pb[i].x, pb[i].y, pb[i].x + 2, pb[i].y + 6, 4) end
        if eb[i].a then ui.circfill(eb[i].x, eb[i].y, 3, 5) end
    end

    -- HUD Estático
    ui.line(0, 16, 480, 16, 1)
end