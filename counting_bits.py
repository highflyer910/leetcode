# https://leetcode.com/problems/counting-bits/
# Given a non negative integer number num. For every numbers i in the range 0 ≤ i ≤ num calculate the number of 1's in their binary representation and return them as an array.
# Example 1:
# Input: 2
# Output: [0,1,1]
# Time Complexity: O(n)
# Space Complexity: O(n)


class Solution:
    def countBits(self, num):
        ones = [0]
        for i in range(1, num + 1):
            ones.append(1 + ones[i & (i - 1)])
        return ones    