// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerPrice {

    bytes32 internal constant _NAME_SLOT  = keccak256("MaseerPrice.name");
    bytes32 internal constant _PRICE_SLOT = keccak256("MaseerPrice.price");

    // Slot 0
    mapping (address => uint256) public wards;
    // Allocate slots 1-49
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

    function read() external view returns (uint256) {
        return uint256(_getVal(_PRICE_SLOT));
    }

    function poke(uint256 read_) external auth {
        _setVal(_PRICE_SLOT, bytes32(read_));
    }

    function name() external view returns (string memory) {
        return _b32toString(_getVal(_NAME_SLOT));
    }

    function file(bytes32 what, bytes32 data) external auth {
        if (what == "name") {
            _setVal(_NAME_SLOT, data);
        }
    }

    function _setVal(bytes32 slot, bytes32 val) internal {
        assembly {
            sstore(slot, val)
        }
    }

    function _getVal(bytes32 slot) internal view returns (bytes32) {
        bytes32 val;
        assembly {
            val := sload(slot)
        }
        return val;
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
