// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneGateBPSTest is MaseerTestBase {

    function setUp() public {

    }

    function testBasicConduitFlow() public {
        _mintUSDT(alice, 100 * 1e6);
        address _offramp = makeAddr("offramp");
        vm.prank(floAuth);
        flo.kiss(_offramp);
        vm.prank(floAuth);
        flo.hope(bob);

        vm.prank(alice);
        usdt.transfer(maseerOneAddr, 100 * 1e6);

        assertEq(usdt.balanceOf(maseerOneAddr), 100 * 1e6);
        assertEq(usdt.balanceOf(alice), 0);

        assertEq(maseerOne.unsettled(), 100 * 1e6);

        vm.prank(carol);
        maseerOne.settle();

        assertEq(maseerOne.unsettled(), 0);
        assertEq(usdt.balanceOf(maseerOneAddr), 0);

        assertEq(usdt.balanceOf(address(flo)), 100 * 1e6);
        assertEq(usdt.balanceOf(_offramp), 0);

        vm.prank(bob);
        flo.move(address(usdt), _offramp, 100 * 1e6);

        assertEq(usdt.balanceOf(_offramp), 100 * 1e6);
        assertEq(usdt.balanceOf(address(flo)), 0);
    }
}
