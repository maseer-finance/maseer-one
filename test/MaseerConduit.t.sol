// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerConduitTest is MaseerTestBase {

    MaseerConduit public maseerConduit;

    function setUp() public {
        maseerConduit = new MaseerConduit();
    }

    function testWards() public {
        assertEq(maseerConduit.wards(address(this)), 1);
        assertEq(maseerConduit.wards(alice), 0);

        maseerConduit.rely(alice);
        maseerConduit.deny(address(this));

        assertEq(maseerConduit.wards(address(this)), 0);
        assertEq(maseerConduit.wards(alice), 1);
    }

    function testCan() public {
        assertEq(maseerConduit.can(alice), 0);

        maseerConduit.hope(alice);

        assertEq(maseerConduit.can(alice), 1);

        maseerConduit.nope(alice);

        assertEq(maseerConduit.can(alice), 0);
    }

    function testBud() public {
        assertEq(maseerConduit.bud(alice), 0);

        maseerConduit.kiss(alice);

        assertEq(maseerConduit.bud(alice), 1);

        maseerConduit.diss(alice);

        assertEq(maseerConduit.bud(alice), 0);
    }

}
