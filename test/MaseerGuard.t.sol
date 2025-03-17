// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerGuardTest is MaseerTestBase {

    MaseerGuard public maseerGuard;

    function setUp() public {

        maseerGuard = new MaseerGuard(USDT);
    }

    function testGoodActor() public view {
        assertEq(maseerGuard.pass(alice), true);
    }

    function testBadActor() public view{
        uint256 _len = ofac.length();
        for (uint256 i = 0; i < _len; i++) {
            assertEq(maseerGuard.pass(ofac.ofac(i)), false);
        }
    }
}
