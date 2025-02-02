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
    // Slot 5
    uint256 public delay;
    // Slot 6
    uint256 public cap;
    // Allocate slots 7-49
    uint256[44] private __gap;

    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerGate/not-authorized");
        _;
    }

    constructor() {
        wards[msg.sender] = 1;
    }

    function live() external view returns (bool) {
        return block.timestamp >= open &&
               block.timestamp <= halt;
    }

    function setOpen(uint256 open_) external auth {
        _setOpen(open_);
    }

    function _setOpen(uint256 open_) internal {
        require(open_ < block.timestamp + 365 days, "MaseerGate/open-too-far");
        open = open_;
    }

    function setHalt(uint256 halt_) external auth {
        _setHalt(halt_);
    }

    function _setHalt(uint256 halt_) internal {
        require(halt_ < block.timestamp + 365 days, "MaseerGate/halt-too-far");
        halt = halt_;
    }

    function setBpsin(uint256 bpsin_) external auth {
        _setBpsin(bpsin_);
    }

    function _setBpsin(uint256 bpsin_) internal {
        require(bpsin_ <= 10000, "MaseerGate/bpsin-too-high");
        bpsin = bpsin_;
    }

    function setBpsout(uint256 bpsout_) external auth {
        _setBpsout(bpsout_);
    }

    function _setBpsout(uint256 bpsout_) internal {
        require(bpsout_ <= 10000, "MaseerGate/bpsout-too-high");
        bpsout = bpsout_;
    }

    function setDelay(uint256 delay_) external auth {
        _setDelay(delay_);
    }

    function _setDelay(uint256 delay_) internal {
        require(delay_ <= 365 days, "MaseerGate/delay-too-high");
        delay = delay_;
    }

    function setCap(uint256 cap_) external auth {
        _setCap(cap_);
    }

    function _setCap(uint256 cap_) internal {
        cap = cap_;
    }

    function pauseMarket() external auth {
        open = 0;
        halt = 0;
    }



}

