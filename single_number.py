# https://leetcode.com/problems/single-number/
# Given an array of integers, every element appears twice except for one. Find that single one.

# Any number XOR with itself is 0.
# So, we can use XOR to find the single number.
# Time - 0(n)
# Space - 0(1)


class Solution(object):
    def singleNumber(self, nums):
        """
        :type nums: List[int]
        :rtype: int
        """
        result = 0
        for num in nums:
            result ^= num
        return result
