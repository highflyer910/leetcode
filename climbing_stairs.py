# https://leetcode.com/problems/climbing-stairs/
# You are climbing a stair case. It takes n steps to reach to the top.
# Each time you can either climb 1 or 2 steps. In how many distinct ways can you climb to the top?

# For each additional step, the number of ways is taking one step from the previous step, 
# plus taking two steps from the previous step. Result is a Fibonacci sequence.
# Time - O(n)
# Space - O(n)

class Solution:
    def climbStairs(self, n):
        if n <= 0:
            return 0
        if n <= 2:
            return n
        
        stairs, prev = 2, 1
        for _ in range(3, n + 1):
            stairs, prev = stairs + prev, stairs

        return stairs    