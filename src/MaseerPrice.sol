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
        return _u(_PRICE_SLOT);
    }

    function poke(uint256 read_) public auth {
        _poke(read_);
    }

    function name() external view returns (string memory) {
        return _b32toString(_getVal(_NAME_SLOT));
    }

    function decimals() external view returns (uint8 decimals_) {
        return uint8(_u(_DECIMALS_SLOT));
    }

    function file(bytes32 what, bytes32 data) external auth {
        if      (what == "price")    _poke(uint256(data));
        else if (what == "name")     _setVal(_NAME_SLOT, data);
        else if (what == "decimals" && uint256(data) <= 18) _setVal(_DECIMALS_SLOT, data);
        else    revert("MaseerPrice/file-unrecognized-param");
        emit    File(what, data);
    }

    function _poke(uint256 read_) internal {
        _setVal(_PRICE_SLOT, bytes32(read_));
        emit PriceUpdate(read_, block.timestamp);
    }

    function _b32toString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 length = 0;
        while (length < 32 && _bytes32[length] != 0) {
            length++;
        }

        bytes memory bytesArray = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytesArray[i] = _bytes32[i];
        }

        return string(bytesArray);
    }
}
