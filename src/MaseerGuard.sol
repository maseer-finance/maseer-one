// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaseerImplementation} from "./MaseerImplementation.sol";

interface GuardSource {
    function getBlackListStatus(address usr) external view returns (bool);
}

contract MaseerGuard is MaseerImplementation {

    address public immutable source;

    // Allocating slots 0-49
    uint256[50] private __gap;

    constructor(address source_) {
        source = source_;
    }

    /**
     * @dev         Checks whether a given user address is not blacklisted.
     * @param  usr  The address of the user to check.
     * @return bool Returns `true` if the user can pass, otherwise `false`.
     */
    function pass(address usr) external view returns (bool) {
        return !GuardSource(source).getBlackListStatus(usr);
    }
}
