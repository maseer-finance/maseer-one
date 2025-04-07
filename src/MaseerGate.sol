// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2025 Maseer LTD
//
// This file is subject to the Business Source License 1.1.
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at:
// https://github.com/Maseer-LTD/maseer-one/blob/master/LICENSE
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerGate is MaseerImplementation {

    bytes32 internal constant _OPEN_MINT_SLOT   = keccak256("maseer.gate.mint.open");
    bytes32 internal constant _HALT_MINT_SLOT   = keccak256("maseer.gate.mint.halt");
    bytes32 internal constant _OPEN_BURN_SLOT   = keccak256("maseer.gate.burn.open");
    bytes32 internal constant _HALT_BURN_SLOT   = keccak256("maseer.gate.burn.halt");
    bytes32 internal constant _BPSIN_SLOT       = keccak256("maseer.gate.bpsin");
    bytes32 internal constant _BPSOUT_SLOT      = keccak256("maseer.gate.bpsout");
    bytes32 internal constant _COOLDOWN_SLOT    = keccak256("maseer.gate.cooldown");
    bytes32 internal constant _CAPACITY_SLOT    = keccak256("maseer.gate.capacity");

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

    function mintcost(uint256 _price) external view returns (uint256) {
        return _adjustMintPrice(_price, bpsin());
    }

    function burncost(uint256 _price) external view returns (uint256) {
        return _adjustBurnPrice(_price, bpsout());
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

    function cooldown() public view returns (uint256) {
        return _uint256Slot(_COOLDOWN_SLOT);
    }

    function capacity() public view returns (uint256) {
        return _uint256Slot(_CAPACITY_SLOT);
    }

    function nextOpenMint() external view returns (uint256) {
        uint256 _open = openMint();
        return _open >= block.timestamp ? _open : 0;
    }

    function nextHaltMint() external view returns (uint256) {
        uint256 _halt = haltMint();
        return _halt >= block.timestamp ? _halt : 0;
    }

    function nextOpenBurn() external view returns (uint256) {
        uint256 _open = openBurn();
        return _open >= block.timestamp ? _open : 0;
    }

    function nextHaltBurn() external view returns (uint256) {
        uint256 _halt = haltBurn();
        return _halt >= block.timestamp ? _halt : 0;
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

    function setCooldown(uint256 cool_) external auth {
        if (cool_ > 365 days) revert UnrecognizedParam(bytes32(cool_));
        _setCooldown(cool_);
    }

    function setCapacity(uint256 capacity_) external auth {
        _setCapacity(capacity_);
    }

    function file(bytes32 what, uint256 data) external auth {
        if      (what == "openmint") _setOpenMint(data);
        else if (what == "haltmint") _setHaltMint(data);
        else if (what == "openburn") _setOpenBurn(data);
        else if (what == "haltburn") _setHaltBurn(data);
        else if (what == "bpsin")    _setBpsin(data);
        else if (what == "bpsout")   _setBpsout(data);
        else if (what == "cooldown") _setCooldown(data);
        else if (what == "capacity") _setCapacity(data);
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

    function _setCooldown(uint256 cool_) internal {
        _setVal(_COOLDOWN_SLOT, bytes32(cool_));
    }

    function _setCapacity(uint256 cap_) internal {
        _setVal(_CAPACITY_SLOT, bytes32(cap_));
    }

    function _adjustMintPrice(uint256 _price, uint256 _bps) internal pure returns (uint256) {
        return _divup((_price * (10_000 + _bps)), 10_000);
    }

    function _adjustBurnPrice(uint256 _price, uint256 _bps) internal pure returns (uint256) {
        return _divup((_price * 10_000), (10_000 + _bps));
    }

    function _divup(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}

