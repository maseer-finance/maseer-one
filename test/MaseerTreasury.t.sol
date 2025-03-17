// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

import {MaseerImplementation} from "../src/MaseerImplementation.sol";
import {MaseerTreasury} from "../src/MaseerTreasury.sol";


contract MaseerTreasuryTest is MaseerTestBase {

    function setUp() public {

    }

    function testAdminNotIssuer() public view {
       assertEq(adm.issuer(admAuth), false);
    }

    function testBestow() public {
        vm.prank(admAuth);
        adm.bestow(bob);
        assertEq(adm.issuer(bob), true);
    }

    function testMultipleBestowals() public {
        vm.prank(admAuth);
        adm.bestow(bob);
        assertEq(adm.issuer(bob), true);

        vm.prank(admAuth);
        adm.bestow(carol);
        assertEq(adm.issuer(bob), true);
        assertEq(adm.issuer(carol), true);
    }

    function testDepose() public {

        vm.prank(admAuth);
        adm.bestow(bob);

        vm.prank(admAuth);
        adm.depose(bob);
        assertEq(adm.issuer(bob), false);
    }
}
