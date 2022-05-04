# https://leetcode.com/problems/two-sum/
# Given an array of integers nums and an integer target
# return indices of the two numbers such that they add up to target.
# You may assume that each input would have exactly one solution.

# Maintain a mapping from each number to its index
# Check if target - num has already been found
# Time complexity: O(n)
# Space complexity: O(n) for the dictionary

class Solution:
    def twoSum(self, nums, target):

        seen = {}

        for i, num in enumerate(nums):
            if target - num in seen:
                return [seen[target - num], i]
            seen[num] = i

        return []
    