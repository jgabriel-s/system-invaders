require "main"

Frame = 0

function update()
    Frame = Frame + 1
    update(Frame)
end 