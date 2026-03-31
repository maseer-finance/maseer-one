// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MockGuardSourceOZ {

    mapping(address => bool) internal _banned;

    function ban(address usr) external {
        _banned[usr] = true;
    }

    function unban(address usr) external {
        _banned[usr] = false;
    }

    function isBanned(address usr) external view returns (bool) {
        return _banned[usr];
    }
}
