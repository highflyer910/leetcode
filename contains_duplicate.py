# https://leetcode.com/problems/contains-duplicate/
# Given an array of integers, find if the array contains any duplicates.
# Your function should return true if any value appears at least twice in the array, 
#and it should return false if every element is distinct.

# If every number is unique then the set length is the same as the list length.
# If this is not true, then there are duplicates.
# Time complexity: O(n)
# Space complexity: O(n)


class Solution(object):
    def containsDuplicate(self, nums):
        """
        :type nums: List[int]
        :rtype: bool
        """
        return len(nums) != len(set(nums))