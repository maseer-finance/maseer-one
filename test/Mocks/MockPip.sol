// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../src/MaseerImplementation.sol";

contract MockPip is MaseerImplementation {

    uint256 internal _price;

    function setPrice(uint256 price_) external {
        _price = price_;
    }

    function read() external view returns (uint256) {
        return _price;
    }
}
