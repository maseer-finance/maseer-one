// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerPrice {

    // Slot 0
    mapping (address => uint256) public wards;
    // Slot 1
    uint256 public read;
    // Allocate slots 2-49
    uint256[49] private __gap;

    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerPrice/not-authorized");
        _;
    }

    constructor() {
        wards[msg.sender] = 1;
    }

    function poke(uint256 read_) external auth {
        read = read_;
    }
}
