# https://leetcode.com/problems/missing-number/
# Given an array containing n distinct numbers taken from 0, 1, 2, ..., n, 
# find the one that is missing from the array.

# Subtract the sum from n*(n+1)/2
# Time: O(n)
# Space: O(1)


class Solution(object):
    def missingNumber(self, nums):
        """
        :type nums: List[int]
        :rtype: int
        """
        n = len(nums)
        return n*(n+1)/2 - sum(nums)
