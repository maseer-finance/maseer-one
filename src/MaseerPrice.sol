// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerPrice is MaseerImplementation{

    bytes32 internal constant _NAME_SLOT     = keccak256("maseer.price.name");
    bytes32 internal constant _PRICE_SLOT    = keccak256("maseer.price.price");
    bytes32 internal constant _DECIMALS_SLOT = keccak256("maseer.price.decimals");

    // Allocate slots 0-49
    uint256[50] private __gap;

    event File(bytes32 indexed what, bytes32 data);
    event PriceUpdate(uint256 indexed price, uint256 indexed timestamp);

    constructor() {
        _rely(msg.sender);
    }

    function read() external view returns (uint256) {
        return _uint256Slot(_PRICE_SLOT);
    }

    function poke(uint256 read_) public auth {
        _poke(read_);
    }

    function pause() external auth {
        _poke(0);
    }

    function name() external view returns (string memory) {
        return _stringSlot(_NAME_SLOT);
    }

    function decimals() external view returns (uint8 decimals_) {
        return uint8(_uint256Slot(_DECIMALS_SLOT));
    }

    function paused() external view returns (bool) {
        return (_uint256Slot(_PRICE_SLOT) == 0) ? true : false;
    }

    function file(bytes32 what, bytes32 data) external auth {
        if      (what == "price")    _poke(uint256(data));
        else if (what == "name")     _setVal(_NAME_SLOT, data);
        else if (what == "decimals" && uint256(data) <= 18) _setVal(_DECIMALS_SLOT, data);
        else    revert UnrecognizedParam(data);
        emit    File(what, data);
    }

    function _poke(uint256 read_) internal {
        _setVal(_PRICE_SLOT, bytes32(read_));
        emit PriceUpdate(read_, block.timestamp);
    }
}
