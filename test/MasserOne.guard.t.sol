// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

import "./fixtures/OFAC.sol";

contract MaseerOneGuardTest is MaseerTestBase {

    OFAC ofac;

    function setUp() public {
        ofac = new OFAC();
    }

    function testBadActors() public view {

        uint256 _len = ofac.length();
        for (uint i = 0; i < _len; i++) {
            assertEq(maseerOne.canPass(ofac.ofac(i)), false);
        }
    }

    function testGoodActors() public view {
        assertEq(maseerOne.canPass(alice), true);
        assertEq(maseerOne.canPass(bob),   true);
        assertEq(maseerOne.canPass(carol), true);
    }
}
