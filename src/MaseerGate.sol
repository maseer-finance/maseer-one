// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerGate {
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerGate/not-authorized");
        _;
    }

    uint256 public open;
    uint256 public halt;

    constructor() {
        wards[msg.sender] = 1;
    }

    function setOpen(uint256 open_) external auth {
        require(open_ < block.timestamp + 365 days, "MaseerGate/open-too-far");
        open = open_;
    }

    function setHalt(uint256 halt_) external auth {
        require(halt_ < block.timestamp + 365 days, "MaseerGate/halt-too-far");
        halt = halt_;
    }

    function pauseMarket() external auth {
        open = 0;
        halt = 0;
    }

    function live() external view returns (bool) {
        return block.timestamp >= open &&
               block.timestamp <= halt;
    }

}

