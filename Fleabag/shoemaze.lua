-- Fleabag
-- Act 3: The Real Game
--
-- Four pieces. Nine cells.
-- Somehow this has become a relationship problem.

local RED   = "\27[31m"
local BLUE  = "\27[34m"
local BLACK = "\27[90m"
local BOLD  = "\27[1m"
local RESET = "\27[0m"

-- Four directions, four glyphs, one shoe.
-- Turn it and suddenly it's somebody else's problem.

local SHAPES = {
    N = "∪",
    S = "∩",
    E = "⊂",
    W = "⊃"
}

-- I could have written four ifs.
-- I wrote a table.
--
-- Because four ifs is a confession and a table is a plan.

local DELTA = {
    N = { r = -1, c =  0 },
    S = { r =  1, c =  0 },
    E = { r =  0, c =  1 },
    W = { r =  0, c = -1 }
}

-- A North-facing shoe opens North,
-- so you enter it by moving South.

local ENTRY_MOVE = {
    N = "S",
    S = "N",
    E = "W",
    W = "E"
}

local EXIT_MOVE = {
    N = "N",
    S = "S",
    E = "E",
    W = "W"
}

-- One table. Four pieces.
--
-- The square can end up inside a shoe.
-- Red can end up inside Blue or Black.
--
-- That's enough shoe genealogy for one evening.
-- I'm not inventing Shoe Kubernetes.

local state = {
    sq = {
        r = 1,
        c = 1,
        inside = nil
    },

    red = {
        name  = "red",
        r     = 3,
        c     = 1,
        dir   = "N",
        color = RED,
        inside = nil
    },

    blue = {
        name  = "blue",
        r     = 2,
        c     = 2,
        dir   = "N",
        color = BLUE,
        inside = nil
    },

    black = {
        name  = "black",
        r     = 1,
        c     = 3,
        dir   = "W",
        color = BLACK,
        inside = nil
    },
    message = ""
}

local shoes = {
    state.red,
    state.blue,
    state.black
}

-- Black is the shoe standing quietly in the corner
-- while Red and Blue get all the plot.

local function shoes_at(r, c)
    local found = {}
    for _, shoe in ipairs(shoes) do
        if shoe.r == r and shoe.c == c then
            table.insert(found, shoe)
        end
    end
    return found
end

local function contains(list, item)
    for _, value in ipairs(list) do
        if value == item then
            return true
        end
    end
    return false
end

local function is_valid(r, c)
    return r >= 1 and r <= 3
       and c >= 1 and c <= 3
end

local function clear_screen()
    if package.config:sub(1, 1) == "\\" then
        os.execute("cls")
    else
        os.execute("clear")
    end
end

-- Red is the only SHOE allowed inside another shoe.
-- Of course Red gets special privileges.

local function may_enter(moving_shoe, target_shoe, move)
    return moving_shoe ~= target_shoe
       and moving_shoe == state.red
       and move == ENTRY_MOVE[target_shoe.dir]
end

local function get_cell_repr(r, c)
    local parts = {}
    for _, shoe in ipairs(shoes) do
        if shoe.r == r and shoe.c == c then
            table.insert(
                parts,
                shoe.color .. SHAPES[shoe.dir] .. RESET
            )
        end
    end
    if state.sq.r == r and state.sq.c == c then
        table.insert(parts, BOLD .. "■" .. RESET)
    end
    if #parts == 0 then
        return "[     ]"
    end
    return "[" .. table.concat(parts, "+") .. "]"
end

local function render()
    clear_screen()
    print("=================================")
    print("      FLEABAG'S SHOE MAZE        ")
    print("=================================")
    print("Controls: N, S, E, W | Q: Quit\n")
    print("+---------+---------+---------+")

    for r = 1, 3 do
        local line = "|"
        for c = 1, 3 do
            line = line .. " " .. get_cell_repr(r, c) .. " |"
        end
        print(line)
        print("+---------+---------+---------+")
    end

    print("\nLEGEND:")
    print(
        " " .. BOLD .. "■" .. RESET ..
        " = You (Black Square)"
    )

    print(
        " " .. RED ..
        SHAPES[state.red.dir] ..
        RESET ..
        " = Red Shoe   (open " ..
        state.red.dir .. ")"
    )

    print(
        " " .. BLUE ..
        SHAPES[state.blue.dir] ..
        RESET ..
        " = Blue Shoe  (open " ..
        state.blue.dir .. ")"
    )

    print(
        " " .. BLACK ..
        SHAPES[state.black.dir] ..
        RESET ..
        " = Black Shoe (open " ..
        state.black.dir .. ")"
    )

    print("---------------------------------")
    if state.message ~= "" then
        print(state.message)
        print("---------------------------------")
    end
end

-- Decide what travels with the square.
--
-- Square alone:
--     just the square.
--
-- Square inside Red while Red is inside another shoe:
--     walk the chain outward. Every enclosing shoe that isn't
--     being exited drags. Then close the set: anything inside
--     a dragging shoe drags with it.
--
--     Things have become unnecessarily intimate.

local function get_moving_shoes(move)
    local moving = {}
    local container = state.sq.inside
    while container do
        if move ~= EXIT_MOVE[container.dir] then
            table.insert(moving, container)
        end
        container = container.inside
    end

    local changed = true
    while changed do
        changed = false
        for _, shoe in ipairs(shoes) do
            if shoe.inside
               and contains(moving, shoe.inside)
               and not contains(moving, shoe) then
                table.insert(moving, shoe)
                changed = true
            end
        end
    end
    return moving
end
-- Work out whether the move is legal before touching the state.
--
-- Look at me checking before mutating things.
-- Growth is disgusting.

local function can_move(move, moving_shoes, target_r, target_c)
    if not is_valid(target_r, target_c) then
        return false, "Hit boundary wall!"
    end

    local d = DELTA[move]
    for _, shoe in ipairs(moving_shoes) do
        local new_r = shoe.r + d.r
        local new_c = shoe.c + d.c
        if not is_valid(new_r, new_c) then
            return false, "Cannot push shoe into outer wall!"
        end
    end

    local destination_shoes = shoes_at(target_r, target_c)

    if #moving_shoes == 0 then
        for _, target in ipairs(destination_shoes) do
            if move ~= ENTRY_MOVE[target.dir] then
                return false,
                    "Blocked by shoe wall! Open side is " ..
                    target.dir .. "."
            end
        end
        return true
    end

    -- Something is being dragged.
    --
    -- Loki will call this case analysis.
    -- I call it checking whether the shoes hit each other.
    for _, moving in ipairs(moving_shoes) do
        for _, target in ipairs(destination_shoes) do
            if not contains(moving_shoes, target) then
                if not may_enter(moving, target, move) then
                    return false,
                        moving.name ..
                        " shoe is blocked by " ..
                        target.name ..
                        " shoe!"
                end
            end
        end
    end
    return true
end

local function move_player(move)
    local d = DELTA[move]
    if not d then return end
    state.message = ""

    local target_r = state.sq.r + d.r
    local target_c = state.sq.c + d.c
    local moving_shoes = get_moving_shoes(move)
    local ok, err = can_move(move, moving_shoes, target_r, target_c)
    if not ok then
        state.message = err
        return
    end

    if state.sq.inside and not contains(moving_shoes, state.sq.inside) then
        state.sq.inside = nil
    end
    for _, shoe in ipairs(moving_shoes) do
        if shoe.inside and not contains(moving_shoes, shoe.inside) then
            shoe.inside = nil
        end
        shoe.r = shoe.r + d.r
        shoe.c = shoe.c + d.c
    end
    state.sq.r = target_r
    state.sq.c = target_c

    local here = shoes_at(target_r, target_c)
    for _, moving in ipairs(moving_shoes) do
        for _, target in ipairs(here) do
            if not moving.inside
               and not contains(moving_shoes, target)
               and may_enter(moving, target, move) then
                moving.inside = target
                break
            end
        end
    end

    if not state.sq.inside then
        for _, shoe in ipairs(here) do
            if move == ENTRY_MOVE[shoe.dir]
               and not contains(moving_shoes, shoe) then
                state.sq.inside = shoe
                break
            end
        end
    end
end

local function check_win()
    return state.red.r == state.blue.r
       and state.red.c == state.blue.c
end

-- Until Red is inside Blue.
--
-- Then the loop breaks,
-- the terminal goes quiet,
-- and everyone can finally go home.

while true do
    render()

    if check_win() then
        print("\n🎉 VICTORY! Red Shoe is inside Blue Shoe.")
        print("They're together. Everyone can go home now.")
        break
    end

    io.write("\nWhere to go? ")
    local input = io.read()
    if not input then
        break
    end

    input = input:upper():match("^%s*(.-)%s*$")
    if input == "Q" then
        break
    end

    if DELTA[input] then
        move_player(input)
    end
end