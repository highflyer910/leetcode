# https://leetcode.com/problems/find-all-numbers-disappeared-in-an-array/
# Given an array of integers where 1 ≤ a[i] ≤ n (n = size of array), 
# some elements appear twice and others appear once.
# Find all the elements of [1, n] inclusive that do not appear in this array.

# Iterate over the list. For every number seen, set the number with index of num -1 to be negative.
# Then iterate over the list again and print the numbers that are positive.


class Solution(object):
    def findDisappearedNumbers(self, nums):
        """
        :type nums: List[int]
        :rtype: List[int]
        """
        for i in range(len(nums)):
            index = abs(nums[i]) - 1
            nums[index] = -abs(nums[index])
        return [i + 1 for i in range(len(nums)) if nums[i] > 0]