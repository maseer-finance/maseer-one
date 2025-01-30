// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerGuardTest is MaseerTestBase {

    MaseerGuard public maseerGuard;

    // List of bad actors at https://github.com/ultrasoundmoney/ofac-ethereum-addresses
    address badActor = 0x08723392Ed15743cc38513C4925f5e6be5c17243;

    function setUp() public {

        maseerGuard = new MaseerGuard(USDT);
    }

    function testGoodActor() public {
        address goodActor = makeAddr("alice");
        assertEq(maseerGuard.pass(goodActor), true);
    }

    function testBadActor() public view{
        assertEq(maseerGuard.pass(badActor), false);
    }
}
