// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneTest is MaseerTestBase {

    MaseerGate public maseerGate;

    function setUp() public {
        maseerGate = act;
    }

    function testOpenMint() public {
        vm.prank(actAuth);
        maseerGate.setOpenMint(block.timestamp + 1 days);
        assertEq(maseerGate.openMint(), block.timestamp + 1 days);
    }

    function testHaltMint() public {
        vm.prank(actAuth);
        maseerGate.setHaltMint(block.timestamp + 1 days);
        assertEq(maseerGate.haltMint(), block.timestamp + 1 days);
    }

    function testMintable() public {
        vm.prank(actAuth);
        maseerGate.setOpenMint(block.timestamp - 1 days);
        vm.prank(actAuth);
        maseerGate.setHaltMint(block.timestamp + 1 days);
        assertEq(maseerGate.mintable(), true);
    }

    function testOpenBurn() public {
        vm.prank(actAuth);
        maseerGate.setOpenBurn(block.timestamp + 1 days);
        assertEq(maseerGate.openBurn(), block.timestamp + 1 days);
    }

    function testHaltBurn() public {
        vm.prank(actAuth);
        maseerGate.setHaltBurn(block.timestamp + 1 days);
        assertEq(maseerGate.haltBurn(), block.timestamp + 1 days);
    }

    function testBurnable() public {
        vm.prank(actAuth);
        maseerGate.setOpenBurn(block.timestamp - 1 days);
        vm.prank(actAuth);
        maseerGate.setHaltBurn(block.timestamp + 1 days);
        assertEq(maseerGate.burnable(), true);
    }

    function testPauseMarket() public {
        vm.prank(actAuth);
        maseerGate.setOpenMint(block.timestamp - 1 days);
        vm.prank(actAuth);
        maseerGate.setHaltMint(block.timestamp + 1 days);
        assertEq(maseerGate.mintable(), true);
        vm.prank(actAuth);
        maseerGate.setOpenBurn(block.timestamp - 1 days);
        vm.prank(actAuth);
        maseerGate.setHaltBurn(block.timestamp + 1 days);
        assertEq(maseerGate.burnable(), true);

        vm.prank(actAuth);
        maseerGate.pauseMarket();

        assertEq(maseerGate.openMint(), 0);
        assertEq(maseerGate.haltMint(), 0);
        assertEq(maseerGate.mintable(), false);
        assertEq(maseerGate.openMint(), 0);
        assertEq(maseerGate.haltMint(), 0);
        assertEq(maseerGate.burnable(), false);
    }

    function testBpsin() public {
        assertEq(maseerGate.bpsin(), 0);
        vm.prank(actAuth);
        maseerGate.setBpsin(10000);
        assertEq(maseerGate.bpsin(), 10000);
    }

    function testBpsout() public {
        assertEq(maseerGate.bpsout(), 0);
        vm.prank(actAuth);
        maseerGate.setBpsout(10000);
        assertEq(maseerGate.bpsout(), 10000);
    }

    function testFile() public {

        assertEq(maseerGate.openMint(), 0);
        vm.prank(actAuth);
        maseerGate.file("openmint", block.timestamp + 1 days);
        assertEq(maseerGate.openMint(), block.timestamp + 1 days);

        assertEq(maseerGate.haltMint(), 0);
        vm.prank(actAuth);
        maseerGate.file("haltmint", block.timestamp + 1 days);
        assertEq(maseerGate.haltMint(), block.timestamp + 1 days);

        assertEq(maseerGate.openBurn(), 0);
        vm.prank(actAuth);
        maseerGate.file("openburn", block.timestamp + 1 days);
        assertEq(maseerGate.openBurn(), block.timestamp + 1 days);

        assertEq(maseerGate.haltBurn(), 0);
        vm.prank(actAuth);
        maseerGate.file("haltburn", block.timestamp + 1 days);
        assertEq(maseerGate.haltBurn(), block.timestamp + 1 days);

        assertEq(maseerGate.bpsin(), 0);
        vm.prank(actAuth);
        maseerGate.file("bpsin", 10000);
        assertEq(maseerGate.bpsin(), 10000);

        assertEq(maseerGate.bpsout(), 0);
        vm.prank(actAuth);
        maseerGate.file("bpsout", 10000);
        assertEq(maseerGate.bpsout(), 10000);

        assertEq(maseerGate.cooldown(), 0);
        vm.prank(actAuth);
        maseerGate.file("cooldown", 1 days);
        assertEq(maseerGate.cooldown(), 1 days);

        assertEq(maseerGate.capacity(), 0);
        vm.prank(actAuth);
        maseerGate.file("capacity", 1_000_000 * 1e18);
        assertEq(maseerGate.capacity(), 1_000_000 * 1e18);

        vm.expectRevert();
        vm.prank(actAuth);
        maseerGate.file("invalid", 1337);

    }

    function testSetTerms() public {
        assertEq(maseerGate.terms(), "");
        vm.prank(actAuth);
        maseerGate.setTerms("test");
        assertEq(maseerGate.terms(), "test");
    }

    function testFuzzTerms(string memory terms) public {
        vm.prank(actAuth);
        maseerGate.setTerms(terms);
        assertEq(maseerGate.terms(), terms);
    }
}
