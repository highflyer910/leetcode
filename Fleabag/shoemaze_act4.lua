-- Fleabag
-- Act 4: The Real Game, But Now With Receipts
--
-- Four pieces. Nine cells.
-- Somehow this has become a *solver*.
--
-- Last act I built a board. This act I built something
-- that tells you the *right way to play it*, which is
-- either the most useful thing I've ever written
-- or the most presumptuous. Depends on the day.

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
        name   = "red",
        r      = 3,
        c      = 1,
        dir    = "N",
        color  = RED,
        inside = nil
    },

    blue = {
        name   = "blue",
        r      = 2,
        c      = 2,
        dir    = "N",
        color  = BLUE,
        inside = nil
    },

    black = {
        name   = "black",
        r      = 1,
        c      = 3,
        dir    = "W",
        color  = BLACK,
        inside = nil
    },

    message = ""
}

local shoes = {
    state.red,
    state.blue,
    state.black
}

-- Last act this function took two arguments.
-- Now it takes three, because the solver needs to ask
-- "what's here?" about boards that aren't *this* board.
--
-- Same function. Different question. Slightly more tired.

local function shoes_at(r, c, board)
    local board_shoes = board and {board.red, board.blue, board.black} or shoes
    local found = {}

    for _, shoe in ipairs(board_shoes) do
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

-- `board or state`.
-- I know, Loki. I know.

local function may_enter(moving_shoe, target_shoe, move, board)
    return moving_shoe ~= target_shoe
       and moving_shoe == (board or state).red
       and move == ENTRY_MOVE[target_shoe.dir]
end

-- Rendering. Unchanged from last act.
-- The board still looks the same. The hints are new.
-- The board doesn't know it's being solved.

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
-- The solver needs to ask this about hypothetical boards too,
-- so this now works with whichever board it gets.
--
-- Same chain walk. Same transitive closure.
-- Different board. That's the whole change.

local function get_moving_shoes(move, board)
    local s = board or state
    local board_shoes = {s.red, s.blue, s.black}
    local moving = {}
    local container = s.sq.inside
    while container do
        if move ~= EXIT_MOVE[container.dir] then
            table.insert(moving, container)
        end
        container = container.inside
    end
    local changed = true
    while changed do
        changed = false
        for _, shoe in ipairs(board_shoes) do
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

-- Same legality check. Now it can check hypothetical boards too.
-- Apparently threading a board through the old code was the price
-- of making the solver reuse the actual game rules

local function can_move(move, moving_shoes, target_r, target_c, board)
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

    local destination_shoes = shoes_at(target_r, target_c, board)
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
    for _, moving in ipairs(moving_shoes) do
        for _, target in ipairs(destination_shoes) do
            if not contains(moving_shoes, target) then
                if not may_enter(moving, target, move, board) then
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

-- The actual move. Same as last act, plus a board parameter.
--
-- `board = s` isn't beautiful.
-- It is, however, doing its job.

local function move_player(move, board)
    local s = board or state
    board = s
    local d = DELTA[move]
    if not d then return end
    s.message = ""

    local target_r = s.sq.r + d.r
    local target_c = s.sq.c + d.c
    local moving_shoes = get_moving_shoes(move, board)
    local ok, err = can_move(move, moving_shoes, target_r, target_c, board)
    if not ok then
        s.message = err
        return
    end
    if s.sq.inside and not contains(moving_shoes, s.sq.inside) then
        s.sq.inside = nil
    end
    for _, shoe in ipairs(moving_shoes) do
        if shoe.inside and not contains(moving_shoes, shoe.inside) then
            shoe.inside = nil
        end
        shoe.r = shoe.r + d.r
        shoe.c = shoe.c + d.c
    end
    s.sq.r = target_r
    s.sq.c = target_c

    local here = shoes_at(target_r, target_c, board)
    for _, moving in ipairs(moving_shoes) do
        for _, target in ipairs(here) do
            if not moving.inside
               and not contains(moving_shoes, target)
               and may_enter(moving, target, move, board) then
                moving.inside = target
                break
            end
        end
    end
    if not s.sq.inside then
        for _, shoe in ipairs(here) do
            if move == ENTRY_MOVE[shoe.dir]
               and not contains(moving_shoes, shoe) then
                s.sq.inside = shoe
                break
            end
        end
    end
end

-- Win condition. Same as last act.
-- Red and Blue on the same cell. That's it.
--
-- All this machinery for one tiny `true`.
-- Seems reasonable.

local function check_win(board)
    local s = board or state
    return s.red.r == s.blue.r
       and s.red.c == s.blue.c
end

-- Act 4 proper. The solver.
--
-- Everything below this line is new.
-- Everything above it is last act's furniture,
-- now willing to answer questions about boards
-- that don't exist yet.

local PIECES = {"sq", "red", "blue", "black"}
local DIRECTIONS = {"N", "S", "E", "W"}
local DIRECTION_NAMES = {N = "North", S = "South", E = "East", W = "West"}

-- Clone a board. Deep copy every piece, then rebuild
-- the `inside` pointers so they point at the *clones*,
-- not the originals.

local function clone_state(board)
    local copy, references = {message = board.message}, {}
    for _, name in ipairs(PIECES) do
        local original, piece = board[name], {}
        for key, value in pairs(original) do
            if key ~= "inside" then piece[key] = value end
        end
        copy[name], references[original] = piece, piece
    end
    for _, name in ipairs(PIECES) do
        copy[name].inside = references[board[name].inside]
    end
    return copy
end

-- Turn a whole board into one comparable value so `visited`
-- can answer one important question: Have I already been here?

local function state_key(board)
    local names, parts = {}, {}
    for _, name in ipairs(PIECES) do names[board[name]] = name end
    for _, name in ipairs(PIECES) do
        local p = board[name]
        parts[#parts + 1] = table.concat({p.r, p.c, p.dir or "-",
                                        names[p.inside] or "-"}, ",")
    end
    return table.concat(parts, "|")
end

-- BFS Solver.
--
-- Start at the current board and expand one move at a time.
-- Reaching a win returns the first move and distance.

local function shortest_hint(board)
    board = board or state
    if check_win(board) then return nil, 0 end
    local queue = {{board = clone_state(board), distance = 0}}
    local head, tail = 1, 1
    local visited = {[state_key(board)] = true}
    while head <= tail do
        local node = queue[head]
        queue[head] = nil
        head = head + 1
        for _, move in ipairs(DIRECTIONS) do
            local next_board = clone_state(node.board)
            move_player(move, next_board)
            if next_board.message == "" then
                local key = state_key(next_board)
                if not visited[key] then
                    visited[key] = true
                    local first = node.first or move
                    local distance = node.distance + 1
                    if check_win(next_board) then return first, distance end
                    tail = tail + 1
                    queue[tail] = {board = next_board, first = first,
                                   distance = distance}
                end
            end
        end
    end
    return nil, nil
end

-- There. I can now predict the future.
-- Unfortunately only for shoes.

while true do
    render()

    if check_win() then
        print("\n🎉 VICTORY! CONGRATS!")
        print("They're together. Everyone can go home now.")
        print("Apparently all they needed was a breadth-first search.")
        print("Good for them.")
        break
    end

    local direction, distance = shortest_hint()
    if direction then
        print(string.format("Hint: %s (%s). Shortest solution: %d moves.",
                            DIRECTION_NAMES[direction], direction, distance))
    else
        print("No solution exists from this position.")
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