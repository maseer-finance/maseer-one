// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerGate is MaseerImplementation {

    bytes32 internal constant _OPEN_SLOT   = keccak256("maseer.gate.open");
    bytes32 internal constant _HALT_SLOT   = keccak256("maseer.gate.halt");
    bytes32 internal constant _BPSIN_SLOT  = keccak256("maseer.gate.bpsin");
    bytes32 internal constant _BPSOUT_SLOT = keccak256("maseer.gate.bpsout");
    bytes32 internal constant _DELAY_SLOT  = keccak256("maseer.gate.delay");
    bytes32 internal constant _CAP_SLOT    = keccak256("maseer.gate.cap");

    // Allocate slots 0-49
    uint256[50] private __gap;

    constructor() {
        _rely(msg.sender);
    }

    function live() external view returns (bool) {
        return block.timestamp >= open() &&
               block.timestamp <= halt();
    }

    function open() public view returns (uint256) {
        return _u(_OPEN_SLOT);
    }

    function halt() public view returns (uint256) {
        return _u(_HALT_SLOT);
    }

    function bpsin() public view returns (uint256) {
        return _u(_BPSIN_SLOT);
    }

    function bpsout() public view returns (uint256) {
        return _u(_BPSOUT_SLOT);
    }

    function delay() public view returns (uint256) {
        return _u(_DELAY_SLOT);
    }

    function cap() public view returns (uint256) {
        return _u(_CAP_SLOT);
    }

    function setOpen(uint256 open_) external auth {
        require(open_ < block.timestamp + 365 days, "MaseerGate/open-too-far");
        _setOpen(open_);
    }

    function setHalt(uint256 halt_) external auth {
        require(halt_ < block.timestamp + 365 days, "MaseerGate/halt-too-far");
        _setHalt(halt_);
    }

    function pauseMarket() external auth {
        _setOpen(0);
        _setHalt(0);
    }

    function setBpsin(uint256 bpsin_) external auth {
        require(bpsin_ <= 10000, "MaseerGate/bpsin-too-high");
        _setBpsin(bpsin_);
    }

    function setBpsout(uint256 bpsout_) external auth {
        require(bpsout_ <= 10000, "MaseerGate/bpsout-too-high");
        _setBpsout(bpsout_);
    }

    function setDelay(uint256 delay_) external auth {
        require(delay_ <= 365 days, "MaseerGate/delay-too-high");
        _setDelay(delay_);
    }

    function setCap(uint256 cap_) external auth {
        _setCap(cap_);
    }

    function file(bytes32 what, uint256 data) external auth {
        if      (what == "open")    _setOpen(data);
        else if (what == "halt")    _setHalt(data);
        else if (what == "bpsin")   _setBpsin(data);
        else if (what == "bpsout")  _setBpsout(data);
        else if (what == "delay")   _setDelay(data);
        else if (what == "cap")     _setCap(data);
        else    revert("MaseerGate/file-unrecognized-param");
    }

    function _setOpen(uint256 open_) internal {
        _setVal(_OPEN_SLOT, bytes32(open_));
    }

    function _setHalt(uint256 halt_) internal {
        _setVal(_HALT_SLOT, bytes32(halt_));
    }

    function _setBpsin(uint256 bpsin_) internal {
        _setVal(_BPSIN_SLOT, bytes32(bpsin_));
    }

    function _setBpsout(uint256 bpsout_) internal {
        _setVal(_BPSOUT_SLOT, bytes32(bpsout_));
    }

    function _setDelay(uint256 delay_) internal {
        _setVal(_DELAY_SLOT, bytes32(delay_));
    }

    function _setCap(uint256 cap_) internal {
        _setVal(_CAP_SLOT, bytes32(cap_));
    }
}

