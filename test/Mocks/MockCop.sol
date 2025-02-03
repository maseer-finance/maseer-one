// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MockCop {

    mapping(address => uint256) public wards;

    bool internal _pass = true;

    function setPass(bool pass_) external {
        _pass = pass_;
    }

    function pass() external view returns (bool) {
        return _pass;
    }
}
