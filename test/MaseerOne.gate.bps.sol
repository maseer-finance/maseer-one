// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneGateBPSTest is MaseerTestBase {

    function setUp() public {

    }

    function testBPSInZero() public {
        uint256 _bps = 0;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 1e6;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), _price);
    }

    function testBPSOutZero() public {
        uint256 _bps = 0;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 1e6;
        assertEq(act.bpsout(), _bps);
        assertEq(act.burncost(_price), _price);
    }

    function testBPSInOneExpectedPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 2974 * 1e4;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), 29742974);
    }

    function testBPSInOneExpectedPriceWithExtra() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        // Oracle price is 29.740001
        uint256 _price = 2974 * 1e4 + 1;
        assertEq(act.bpsin(), _bps);
        // Calculated price is 29742975.0001. Round up is ok
        assertEq(act.mintcost(_price), 29742976);
    }

    function testBPSOutOneExpectedPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 2974 * 1e4;
        assertEq(act.bpsout(), _bps);
        // Unit - 1 bps == 29737026.297370263 Rounding up is ok
        assertEq(act.burncost(_price), 29737027);
    }

    function testBPSInOne() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 1e6;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), 1000100);
    }

    function testBPSOutOne() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 1e6;
        assertEq(act.bpsout(), _bps);
        assertEq(act.burncost(_price), 999901);
    }

    function testBPSInOneLowPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 113;
        assertEq(act.bpsin(), _bps);
        // Round up on unit cost even when bps is low.
        assertEq(act.mintcost(_price), 114);
    }

    function testBPSOutOneLowPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 113;
        assertEq(act.bpsout(), _bps);

        // Price is the same as the unit cost.
        // This is acceptable because the proposed fee is less than one price unit.
        assertEq(act.burncost(_price), 113);
    }

    function testBPSInFiftyLowPrice() public {
        uint256 _bps = 50;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 113;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), 114);
    }

    function testBPSOutFiftyLowPrice() public {
        uint256 _bps = 50;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 113;
        assertEq(act.bpsout(), _bps);
        // Price is the same as the unit cost.
        // This is acceptable because the proposed fee is less than one price unit.
        assertEq(act.burncost(_price), 113);
    }

    function testBPSIn200LowPrice() public {
        uint256 _bps = 200;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 113;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), 116);
    }

    function testBPSOut200LowPrice() public {
        uint256 _bps = 200;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 113;
        assertEq(act.bpsout(), _bps);
        assertEq(act.burncost(_price), 111);
    }

    function testBPSInOneHighPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsin(_bps);

        uint256 _price = 1e70;
        assertEq(act.bpsin(), _bps);
        assertEq(act.mintcost(_price), 10001000000000000000000000000000000000000000000000000000000000000000000);
    }

    function testBPSOutOneHighPrice() public {
        uint256 _bps = 1;

        vm.prank(actAuth);
        act.setBpsout(_bps);

        uint256 _price = 1e70;
        assertEq(act.bpsout(), _bps);
        assertEq(act.burncost(_price), 9999000099990000999900009999000099990000999900009999000099990000999901);
    }
}
