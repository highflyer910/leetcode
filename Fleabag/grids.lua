-- Mask B3 - Fleabag

-- Apparently we have a board now.
-- We don't.
-- We have two numbers and a man with stationery.

-- Loki will call this "state." I call it "x and y."
-- He'll say "mutable state is a sin." I say sin is a hobby.

local x, y = 1, 1

-- Why 1-based? Because Lua, Loki.
-- Because someone, somewhere, decided counting should start
-- where humans start counting: at one.

while true do
    -- No struct. No render function.
    -- Just a string, a format, and the truth.
    -- He'll say "this isn't a board, it's a print statement."
    -- He's right. And it prints. And that's the job.

    print(string.format(
        "\n[Fleabag's Board] Square is at Row %d, Col %d",
        y, x
    ))

    -- The square isn't *on* the board, Loki.
    -- The square is a coordinate. The board is a feeling.
    -- And I refuse to draw it.

    io.write("Where to go? ")
    local move = io.read()

    if move == "N" and y > 1 then
        y = y - 1
    elseif move == "S" and y < 3 then
        y = y + 1
    elseif move == "E" and x < 3 then
        x = x + 1
    elseif move == "W" and x > 1 then
        x = x - 1
    end

    -- Walk into a wall and nothing happens.
    -- No error message. No apology.
    -- Just the next prompt and the same two numbers.
    -- He'd probably give that a name.
    -- I call it Tuesday.
end