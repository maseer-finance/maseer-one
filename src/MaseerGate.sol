// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerGate {

    // Slot 0
    mapping (address => uint256) public wards;
    // Slot 1
    uint256 public open;
    // Slot 2
    uint256 public halt;
    // Slot 3
    uint256 public bpsin;
    // Slot 4
    uint256 public bpsout;
    // Allocate slots 5-49
    uint256[46] private __gap;

    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerGate/not-authorized");
        _;
    }

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

    function setBpsin(uint256 bpsin_) external auth {
        require(bpsin_ <= 10000, "MaseerGate/bpsin-too-high");
        bpsin = bpsin_;
    }

    function setBpsout(uint256 bpsout_) external auth {
        require(bpsout_ <= 10000, "MaseerGate/bpsout-too-high");
        bpsout = bpsout_;
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

