// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerPrice {

    bytes32 internal constant _NAME_SLOT     = keccak256("MaseerPrice.name");
    bytes32 internal constant _PRICE_SLOT    = keccak256("MaseerPrice.price");
    bytes32 internal constant _DECIMALS_SLOT = keccak256("MaseerPrice.decimals");

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

    event File(bytes32 indexed what, bytes32 data);
    event PriceUpdate(uint256 indexed price, uint256 indexed timestamp);

    constructor() {
        wards[msg.sender] = 1;
    }

    function read() external view returns (uint256) {
        return uint256(_getVal(_PRICE_SLOT));
    }

    function poke(uint256 read_) public auth {
        _poke(read_);
    }

    function name() external view returns (string memory) {
        return _b32toString(_getVal(_NAME_SLOT));
    }

    function decimals() external view returns (uint8 decimals_) {
        return uint8(uint256(_getVal(_DECIMALS_SLOT)));
    }

    function file(bytes32 what, bytes32 data) external auth {
        if      (what == "name")     _setVal(_NAME_SLOT, data);
        else if (what == "decimals") _setVal(_DECIMALS_SLOT, data);
        else if (what == "price")    _poke(uint256(data));
        else    revert("MaseerPrice/file-unrecognized-param");
        emit    File(what, data);
    }

    function _poke(uint256 read_) internal {
        _setVal(_PRICE_SLOT, bytes32(read_));
        emit PriceUpdate(read_, block.timestamp);
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
