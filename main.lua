-- ============================================================
-- SYSTEM INVADERS (Jogador + Inimigos Básicos)
-- Lupi Game API (480x270 @ 60 FPS)dwadawdwadwa
-- ============================================================

local Palette = { 0x0000, 0x03E0, 0x0120, 0x001F, 0x03FF, 0x7C00, 0x7FE0, 0x7FFF }

-- Posição do Jogador (Nave Blue Team)
local px = 220

-- Posições X fixas dos Inimigos (Red Team)
local ex_pos = { 60, 115, 170, 225, 280, 335 }

function update(frame)
    -- 1. Registro de Paleta (Obrigatório Lupi API)
    for i = 1, 8 do ui.palset(i - 1, Palette[i]) end
    ui.cls(0)

    -- 2. Movimentação do Jogador
    if ui.btn(0) then px = px - 3 end -- Esquerda (LEFT)
    if ui.btn(1) then px = px + 3 end -- Direita (RIGHT)
    px = ui.mid(10, px, 430)

    -- 3. Renderização do Jogador (Triângulo + Retângulo Azul)
    ui.rectfill(px, 249, px + 36, 255, 3)
    ui.trisfill(px + 12, 249, px + 24, 249, px + 18, 243, 4)

    -- 4. Renderização dos Inimigos (Retângulos Vermelhos)
    for i = 1, 6 do
        local ex = ex_pos[i]
        ui.rectfill(ex + 4, 42, ex + 20, 54, 5)
        ui.rect(ex + 2, 40, ex + 22, 56, 6)
    end
end