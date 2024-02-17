// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IErrors {
    /// Will arise when msg.value is lower than minAmount
    /// `minAmount` minimmum amount
    /// @param minAmount the minnimum acceptable ETH amount to fund
    /// @param payedAmount the ETH amount funded by user
    error LowEtherAmount(uint minAmount, uint payedAmount);

    /// Will arise when block.timestamp is more than campaingDeadline
    /// `campaingDeadline` deadline
    /// @param campaingDeadline deadline time of fundraising the campaign
    /// @param requestTime time of requesting
    error DeadLine(uint campaingDeadline, uint requestTime);
}
