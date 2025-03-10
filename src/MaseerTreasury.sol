// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerTreasury is MaseerImplementation {

    // Allocating slots 0-49
    uint256[50] private __gap;

    bytes32 internal constant _ISSUER_SLOT   = keccak256("maseer.treasury.issuer");

    function bestow(address usr) external auth {
        _setIssuer(usr, 1);
    }

    function revoke(address usr) external auth {
        _setIssuer(usr, 0);
    }

    function issuer(address usr) external view returns (bool) {
        return _getIssuer(usr) == 1;
    }

    function _setIssuer(address usr, uint256 val) internal {
        bytes32 slot = keccak256(abi.encode(_ISSUER_SLOT, usr));
        _setVal(slot, val);
    }

    function _getIssuer(address usr) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(_ISSUER_SLOT, usr));
        return _uint256Slot(slot);
    }
}
