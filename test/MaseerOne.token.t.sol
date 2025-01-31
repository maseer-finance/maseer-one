// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneTokenTest is MaseerTestBase {

    function setUp() public {
        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
    }

    // TODO: General ERC20 tests
    // TODO: Test can't send to zero address
    // TODO: Test can't send to self
}
