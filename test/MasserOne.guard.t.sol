// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

import "./fixtures/OFAC.sol";

contract MaseerOneGuardTest is MaseerTestBase {


    function setUp() public {

    }

    function testBadActors() public view {
        // Run through the list of bad actors and ensure they are blocked
        uint256 _len = ofac.length();
        for (uint256 i = 0; i < _len; i++) {
            assertEq(maseerOne.canPass(ofac.ofac(i)), false);
        }
    }

    function testGoodActors() public view {
        // Ensure that the good actors are allowed to pass
        assertEq(maseerOne.canPass(alice), true);
        assertEq(maseerOne.canPass(bob),   true);
        assertEq(maseerOne.canPass(carol), true);
        assertEq(maseerOne.canPass(david), true);
    }
}
