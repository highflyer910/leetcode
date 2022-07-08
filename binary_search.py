# https://leetcode.com/problems/binary-search/
# Given a sorted (in ascending order) integer array nums of n elements and a target value,
# write a function to search target in nums. If target exists, then return its index, otherwise return -1.
# Input: nums = [-1,0,3,5,9,12], target = 9
# Output: 4

# Time Complexity: O(log(n))
# Space Complexity: O(1)


class Solution:
    def search(self, nums, target):
        if not nums:
            return -1
        left, right = 0, len(nums) - 1

        while left <= right:

            mid = (left + right) // 2

            if nums[mid] == target:
                return mid
            elif nums[mid] < target:
                left = mid + 1
            else:
                right = mid - 1

        return -1