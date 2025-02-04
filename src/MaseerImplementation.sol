// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract MaseerImplementation {

    bytes32 internal constant _WARD_SLOT = keccak256("maseer.wards");

    modifier auth() {
        require(uint256(_getVal(keccak256(abi.encode(_WARD_SLOT, msg.sender)))) == 1, "MaseerAuth/not-authorized");
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

    function _getVal(bytes32 slot) internal view returns (bytes32 val) {
        assembly {
            val := sload(slot)
        }
    }
}
