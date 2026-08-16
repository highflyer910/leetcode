# AoC 2022 Day 05 - Supply Stacks
# Solved backwards: instead of simulating every crate move, track where 
# the final top crate came from by going through the moves in reverse.
# We only care about the crate on top of each stack, so there's no need
# to move every crate. With at most 10 stacks, that's at most 10 positions
# to track.
# Complexity: O(stacks * moves)

import sys
import re
import time

def solve_backwards(file_path):
    t0 = time.perf_counter()

    with open(file_path, 'r', encoding='utf8') as f:
        data = f.read()

    parts = re.split(r'\r?\n\r?\n', data, maxsplit=1)
    if len(parts) < 2:
        return

    header, moves_block = parts

    lines = header.splitlines()
    label_line = lines[-1]
    crate_lines = lines[:-1]

    num_stacks = len(label_line.split())
    initial_stacks = [[] for _ in range(num_stacks)]

    for line in reversed(crate_lines):
        for i in range(num_stacks):
            idx = 1 + 4 * i
            if idx < len(line):
                ch = line[idx]
                if ch != ' ':
                    initial_stacks[i].append(ch)

    raw_moves = []

    for line in moves_block.splitlines():
        line = line.strip()
        if not line or not line.startswith('m'):
            continue

        parts = line.split()
        src = int(parts[3]) - 1
        dst = int(parts[5]) - 1

        if not (0 <= src < num_stacks and 0 <= dst < num_stacks):
            continue

        match = re.match(r'\d+', parts[1])
        count = int(match.group()) if match else 0
        raw_moves.append((count, src, dst))

    sizes = [len(stack) for stack in initial_stacks]
    moves = []

    for count, src, dst in raw_moves:
        count = min(count, sizes[src])
        sizes[src] -= count
        sizes[dst] += count
        moves.append((count, src, dst))

    result_chars = []

    for target_stack in range(num_stacks):
        curr_stack = target_stack
        depth_from_top = 0

        for count, src, dst in reversed(moves):
            if count == 0:
                continue

            if curr_stack == dst:
                if depth_from_top < count:
                    curr_stack = src
                    depth_from_top = count - 1 - depth_from_top
                else:
                    depth_from_top -= count

            elif curr_stack == src:
                depth_from_top += count

        initial_stack = initial_stacks[curr_stack]
        index = len(initial_stack) - 1 - depth_from_top

        if 0 <= index < len(initial_stack):
            result_chars.append(initial_stack[index])

    result = ''.join(result_chars)
    t1 = time.perf_counter()

    print('Result:', result)
    print(f'Time: {(t1 - t0) * 1000:.4f} ms')


if __name__ == '__main__':
    if len(sys.argv) > 1:
        solve_backwards(sys.argv[1])
    else:
        print('Usage: python supplystacks.py <input-file>')