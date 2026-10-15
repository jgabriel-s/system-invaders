require "palette"
require "sprites"

local terminal = {}

local cols = 60
local rows = 23

function loop(frame)
    
    for i = 1, #Palette do
            ui.palset(i - 1, Palette[i])
        end

        ui.cls(0)

        -- Desenha o sprite de fundo
        ui.spr(fundo, 0, 0)

        -- Outros elementos do jogo vêm depois
    
end 