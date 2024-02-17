// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Campaign {
    address owner;
    bool payedOut;
    string title;
    string description;
    uint256 target;
    uint256 deadline;
    uint256 amountCollected;
    string image;
    address[] donators;
    uint256[] donations;
    // Donator donator;
}

// this strcut might be use to make the lotto procedure,
//  based on donator's donated amount
struct Donator {
    address wallet;
    uint256 donatedAmt;
}
