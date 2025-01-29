// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface GuardSource {
    function getBlackListStatus(address usr) external view returns (bool);
}

contract MaseerGuard {

    address public immutable source;

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
