# https://leetcode.com/problems/maximum-subarray/submissions/
# Find the contiguous subarray within an array (containing at least one number) 
# which has the largest sum.

# Time Complexity: O(n)
# Space Complexity: O(1)


class Solution(object):
    def maxSubArray(self, nums):
        max_sum = nums[0]
        current_sum = nums[0]
        
        for i in range(1, len(nums)):
            num = nums[i]
            
            current_sum = max(current_sum + num, num)
            max_sum = max(current_sum, max_sum)
            
        return max_sum  