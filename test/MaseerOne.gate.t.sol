// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneGateTest is MaseerTestBase {

    function setUp() public {

    }

    function testGate() public view {
        assertEq(maseerOne.act(), actProxy);
    }
}
