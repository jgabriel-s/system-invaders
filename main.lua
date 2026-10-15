require "palette"
require "sprites"

local terminal = {}

local cols = 60
local rows = 23

-- Criar a matriz do terminal
for y = 1, rows do
    local line = ""

    for x = 1, cols do
        if y == 1 or y == rows or x == 1 or x == cols then
            line = line .. "#"
        else
            line = line .. "."
        end
    end

    terminal[y] = line
end

function loop(frame)
    
    for i = 1, #Palette do
        local color = Palette[i]
        ui.palset(i - 1, color)
    end

    ui.clip(0,0,480,270)
    ui.camera(0,0)
    ui.cls(Palette.hex(0x0000))
    
    local green = Palette.id(11)

    for y = 1, #terminal do
        ui.print(terminal[y], 0, (y - 1) * 12, green)
    end
end 