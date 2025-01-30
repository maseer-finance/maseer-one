// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneTest is MaseerTestBase {

    MaseerGate public maseerGate;

    function setUp() public {

        maseerGate = new MaseerGate();
    }

    function testOpen() public {
        maseerGate.setOpen(block.timestamp + 1 days);
        assertEq(maseerGate.open(), block.timestamp + 1 days);
    }

    function testHalt() public {
        maseerGate.setHalt(block.timestamp + 1 days);
        assertEq(maseerGate.halt(), block.timestamp + 1 days);
    }

    function testLive() public {
        maseerGate.setOpen(block.timestamp - 1 days);
        maseerGate.setHalt(block.timestamp + 1 days);
        assertEq(maseerGate.live(), true);
    }

    function testPauseMarket() public {
        maseerGate.setOpen(block.timestamp - 1 days);
        maseerGate.setHalt(block.timestamp + 1 days);
        assertEq(maseerGate.live(), true);

        maseerGate.pauseMarket();

        assertEq(maseerGate.open(), 0);
        assertEq(maseerGate.halt(), 0);
        assertEq(maseerGate.live(), false);
    }

    function testBpsin() public {
        assertEq(maseerGate.bpsin(), 0);

        maseerGate.setBpsin(10000);
        assertEq(maseerGate.bpsin(), 10000);
    }

    function testBpsout() public {
        assertEq(maseerGate.bpsout(), 0);

        maseerGate.setBpsout(10000);
        assertEq(maseerGate.bpsout(), 10000);
    }
}
