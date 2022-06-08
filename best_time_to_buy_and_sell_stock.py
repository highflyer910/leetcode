# https://leetcode.com/problems/best-time-to-buy-and-sell-stock/submissions/
# Say you have an array for which the ith element is the price of a given stock on day i.
# If you were only permitted to complete at most one transaction 
# (i.e., buy one and sell one share of the stock),
# design an algorithm to find the maximum profit.
# Note that you cannot sell a stock before you buy one.

#Time Complexity: O(n)
#Space Complexity: O(1)

class Solution:
    def maxProfit(self, prices):
        max_profit = 0
        current_min = prices[0]

        for i in range(1, len(prices)):
            price = prices[i]

            max_profit = max(max_profit, price - current_min)
            current_min = min(current_min, price)

        return max_profit    