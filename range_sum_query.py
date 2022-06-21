# https://leetcode.com/problems/range-sum-query-immutable/
# Given an integer array nums, find the sum of the elements between indices i and j (i ≤ j), inclusive.

# Store cumulative sum.
# Time: O(n)
# Space: O(n)


class NumArray:
    def __init__(self, nums):
        self.cumul = [0]
        for num in nums:
            self.cumul.append(self.cumul[-1] + num)

    def sumRange(self, i, j):
        return self.cumul[j + 1] - self.cumul[i]        