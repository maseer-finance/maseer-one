// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneMarketTest is MaseerTestBase {

    function setUp() public {
        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
    }

    // TODO: Test market operations
}
