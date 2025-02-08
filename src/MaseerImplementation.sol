// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract MaseerImplementation {

    bytes32 internal constant _WARD_SLOT = keccak256("maseer.wards");

    error NotAuthorized(address usr);
    error UnrecognizedParam(bytes32 param);

    modifier auth() {
        if (uint256(_getVal(keccak256(abi.encode(_WARD_SLOT, msg.sender)))) != 1) revert NotAuthorized(msg.sender);
        _;
    }

    function rely(address usr) external auth {
        _rely(usr);
    }

    function deny(address usr) external auth {
        _deny(usr);
    }

    function wards(address usr) external view returns (uint256) {
        return uint256(_getVal(keccak256(abi.encode(_WARD_SLOT, usr))));
    }

    function _rely(address usr) internal {
        _setVal(keccak256(abi.encode(_WARD_SLOT, usr)), bytes32(uint256(1)));
    }

    function _deny(address usr) internal {
        _setVal(keccak256(abi.encode(_WARD_SLOT, usr)), bytes32(uint256(0)));
    }

    function _setVal(bytes32 slot, bytes32 val) internal {
        assembly {
            sstore(slot, val)
        }
    }

    function _setVal(bytes32 slot, uint256 val) internal {
        assembly {
            sstore(slot, val)
        }
    }

    function _setVal(bytes32 slot, address val) internal {
        assembly {
            sstore(slot, val)
        }
    }

    function _getVal(bytes32 slot) internal view returns (bytes32 val) {
        assembly {
            val := sload(slot)
        }
    }

    function _uint256Slot(bytes32 slot) internal view returns (uint256) {
        return uint256(_getVal(slot));
    }

    function _addressSlot(bytes32 slot) internal view returns (address) {
        return address(uint160(uint256(_getVal(slot))));
    }

    function _stringSlot(bytes32 slot) internal view returns (string memory) {
        return _b32toString(_getVal(slot));
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
