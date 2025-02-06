// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../src/MaseerImplementation.sol";

contract MockCop is MaseerImplementation {

    mapping(address => bool) internal _blackList;

    function blacklist(address _usr, bool pass_) external {
        _blackList[_usr] = pass_;
    }

    function pass(address _usr) external view returns (bool) {
        return !_blackList[_usr];
    }
}
