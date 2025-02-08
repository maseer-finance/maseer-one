// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerGate is MaseerImplementation {

    bytes32 internal constant _OPEN_MINT_SLOT   = keccak256("maseer.gate.mint.open");
    bytes32 internal constant _HALT_MINT_SLOT   = keccak256("maseer.gate.mint.halt");
    bytes32 internal constant _OPEN_BURN_SLOT   = keccak256("maseer.gate.burn.open");
    bytes32 internal constant _HALT_BURN_SLOT   = keccak256("maseer.gate.burn.halt");
    bytes32 internal constant _BPSIN_SLOT       = keccak256("maseer.gate.bpsin");
    bytes32 internal constant _BPSOUT_SLOT      = keccak256("maseer.gate.bpsout");
    bytes32 internal constant _DELAY_SLOT       = keccak256("maseer.gate.delay");
    bytes32 internal constant _CAP_SLOT         = keccak256("maseer.gate.cap");

    // Allocate slots 0-49
    uint256[50] private __gap;

    constructor() {
        _rely(msg.sender);
    }

    function mintable() external view returns (bool) {
        return block.timestamp >= openMint() &&
               block.timestamp <= haltMint();
    }

    function burnable() external view returns (bool) {
        return block.timestamp >= openBurn() &&
               block.timestamp <= haltBurn();
    }

    function openMint() public view returns (uint256) {
        return _uint256Slot(_OPEN_MINT_SLOT);
    }

    function haltMint() public view returns (uint256) {
        return _uint256Slot(_HALT_MINT_SLOT);
    }

    function openBurn() public view returns (uint256) {
        return _uint256Slot(_OPEN_BURN_SLOT);
    }

    function haltBurn() public view returns (uint256) {
        return _uint256Slot(_HALT_BURN_SLOT);
    }

    function bpsin() public view returns (uint256) {
        return _uint256Slot(_BPSIN_SLOT);
    }

    function bpsout() public view returns (uint256) {
        return _uint256Slot(_BPSOUT_SLOT);
    }

    function delay() public view returns (uint256) {
        return _uint256Slot(_DELAY_SLOT);
    }

    function cap() public view returns (uint256) {
        return _uint256Slot(_CAP_SLOT);
    }

    function setOpenMint(uint256 open_) external auth {
        if (open_ > block.timestamp + 365 days) revert UnrecognizedParam(bytes32(open_));
        _setOpenMint(open_);
    }

    function setHaltMint(uint256 halt_) external auth {
        if (halt_ > block.timestamp + 365 days) revert UnrecognizedParam(bytes32(halt_));
        _setHaltMint(halt_);
    }

    function setOpenBurn(uint256 open_) external auth {
        if (open_ > block.timestamp + 365 days) revert UnrecognizedParam(bytes32(open_));
        _setOpenBurn(open_);
    }

    function setHaltBurn(uint256 halt_) external auth {
        if (halt_ > block.timestamp + 365 days) revert UnrecognizedParam(bytes32(halt_));
        _setHaltBurn(halt_);
    }

    function pauseMarket() external auth {
        _setOpenMint(0);
        _setHaltMint(0);
        _setOpenBurn(0);
        _setHaltBurn(0);
    }

    function setBpsin(uint256 bpsin_) external auth {
        if (bpsin_ > 10000) revert UnrecognizedParam(bytes32(bpsin_));
        _setBpsin(bpsin_);
    }

    function setBpsout(uint256 bpsout_) external auth {
        if (bpsout_ > 10000) revert UnrecognizedParam(bytes32(bpsout_));
        _setBpsout(bpsout_);
    }

    function setDelay(uint256 delay_) external auth {
        if (delay_ > 365 days) revert UnrecognizedParam(bytes32(delay_));
        _setDelay(delay_);
    }

    function setCap(uint256 cap_) external auth {
        _setCap(cap_);
    }

    function file(bytes32 what, uint256 data) external auth {
        if      (what == "openmint") _setOpenMint(data);
        else if (what == "haltmint") _setHaltMint(data);
        else if (what == "openburn") _setOpenBurn(data);
        else if (what == "haltburn") _setHaltBurn(data);
        else if (what == "bpsin")    _setBpsin(data);
        else if (what == "bpsout")   _setBpsout(data);
        else if (what == "delay")    _setDelay(data);
        else if (what == "cap")      _setCap(data);
        else    revert UnrecognizedParam(what);
    }

    function _setOpenMint(uint256 open_) internal {
        _setVal(_OPEN_MINT_SLOT, bytes32(open_));
    }

    function _setHaltMint(uint256 halt_) internal {
        _setVal(_HALT_MINT_SLOT, bytes32(halt_));
    }

    function _setOpenBurn(uint256 open_) internal {
        _setVal(_OPEN_BURN_SLOT, bytes32(open_));
    }

    function _setHaltBurn(uint256 halt_) internal {
        _setVal(_HALT_BURN_SLOT, bytes32(halt_));
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

