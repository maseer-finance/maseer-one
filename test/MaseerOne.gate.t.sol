// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneGateTest is MaseerTestBase {

    function setUp() public {

    }

    function testGate() public view {
        assertEq(maseerOne.act(), actProxy);
    }

    function testFuzzPriceDeltas(uint256 price, uint256 bpsin, uint256 bpsout) public {
        price = bound(price, 1, 1e30);
        bpsin = bound(bpsin, 0, 10_000);
        bpsout = bound(bpsout, 0, 10_000);

        vm.prank(pipBud);
        pip.poke(price);
        assertEq(maseerOne.navprice(), price);

        vm.prank(actAuth);
        act.setBpsin(bpsin);
        vm.prank(actAuth);
        act.setBpsout(bpsout);

        assertGe(maseerOne.mintcost(), maseerOne.burncost());
        assertGe(maseerOne.mintcost(), maseerOne.navprice());
        assertLe(maseerOne.burncost(), maseerOne.navprice());
        assertEq(maseerOne.mintcost(), act.mintcost(price));
        assertEq(maseerOne.burncost(), act.burncost(price));
    }
}
