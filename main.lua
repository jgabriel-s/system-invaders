require "palette"
require "sprites"

local background = require "lupi_background"

function loop(frame)
    
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    ui.clip(0, 0, 480, 270)
    ui.camera(0, 0)
    ui.cls(0)

    ui.grid(0, 0, 1, 1, background)
    
end 