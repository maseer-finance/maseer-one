// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

import {MaseerImplementation} from "../src/MaseerImplementation.sol";

contract MaseerConduitTest is MaseerTestBase {

    MaseerConduit public maseerConduit;

    function setUp() public {
        maseerConduit = MaseerConduit(flo);
    }

    function testWards() public {
        assertEq(maseerConduit.wards(floAuth), 1);
        assertEq(maseerConduit.wards(alice), 0);

        vm.prank(floAuth);
        maseerConduit.rely(alice);
        vm.prank(floAuth);
        maseerConduit.deny(floAuth);

        assertEq(maseerConduit.wards(floAuth), 0);
        assertEq(maseerConduit.wards(alice), 1);

        vm.prank(alice);
        maseerConduit.rely(floAuth);

        assertEq(maseerConduit.wards(floAuth), 1);
    }

    function testCan() public {
        assertEq(maseerConduit.can(alice), 0);

        vm.prank(floAuth);
        maseerConduit.hope(alice);

        assertEq(maseerConduit.can(alice), 1);

        vm.prank(floAuth);
        maseerConduit.nope(alice);

        assertEq(maseerConduit.can(alice), 0);
    }

    function testBud() public {
        assertEq(maseerConduit.bud(alice), 0);

        vm.prank(floAuth);
        maseerConduit.kiss(alice);

        assertEq(maseerConduit.bud(alice), 1);

        vm.prank(floAuth);
        maseerConduit.diss(alice);

        assertEq(maseerConduit.bud(alice), 0);
    }

    function testMove() public {

        uint256 amt;
        uint256 bal = 100_000 * 1e6;

        vm.prank(floAuth);
        maseerConduit.hope(alice);
        vm.prank(floAuth);
        maseerConduit.kiss(bob);

        // Sanity check 0 initial balances
        assertEq(IUSDT(USDT).balanceOf(address(maseerConduit)), 0);
        assertEq(IUSDT(USDT).balanceOf(alice), 0);
        assertEq(IUSDT(USDT).balanceOf(bob), 0);

        // Move 0 USDT
        vm.expectEmit();
        emit MaseerConduit.Move(USDT, bob, 0);
        vm.prank(alice);
        amt = maseerConduit.move(USDT, bob);
        vm.stopPrank();

        assertEq(amt, 0);
        assertEq(IUSDT(USDT).balanceOf(address(maseerConduit)), 0);
        assertEq(IUSDT(USDT).balanceOf(alice), 0);
        assertEq(IUSDT(USDT).balanceOf(bob), 0);

        // Put bal USDT into the conduit
        _mintUSDT(address(maseerConduit), bal);

        // Move bal USDT
        vm.expectEmit();
        emit MaseerConduit.Move(USDT, bob, bal);
        vm.prank(alice);
        amt = maseerConduit.move(USDT, bob);
        vm.stopPrank();

        assertEq(amt, bal);
        assertEq(IUSDT(USDT).balanceOf(address(maseerConduit)), 0);
        assertEq(IUSDT(USDT).balanceOf(alice), 0);
        assertEq(IUSDT(USDT).balanceOf(bob), bal);
    }

    function testMoveFailNotBud() public {

        // alice is a valid operator but carol is not a valid destination
        vm.prank(floAuth);
        maseerConduit.hope(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerConduit.InvalidAddress.selector, carol));
        vm.prank(alice);
        maseerConduit.move(USDT, carol);
    }

    function testMoveFailNotCan() public {

        // carol is a valid destination but alice is not a valid operator
        vm.prank(floAuth);
        maseerConduit.kiss(carol);

        vm.expectRevert(abi.encodeWithSelector(MaseerConduit.NotOperator.selector, alice));
        vm.prank(alice);
        maseerConduit.move(USDT, carol);
    }

    function testMoveFailNotAuth() public {

        // alice is not authorized to modify permissions

        vm.expectRevert();
        vm.prank(alice);
        maseerConduit.rely(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, alice));
        vm.prank(alice);
        maseerConduit.deny(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, alice));
        vm.prank(alice);
        maseerConduit.hope(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, alice));
        vm.prank(alice);
        maseerConduit.nope(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, alice));
        vm.prank(alice);
        maseerConduit.kiss(alice);

        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, alice));
        vm.prank(alice);
        maseerConduit.diss(alice);
    }

    function testMoveWETH() public {

        uint256 amt;
        uint256 bal = 100_000 * 1e18;

        deal(WETH, address(maseerConduit), bal);
        deal(DAI, address(maseerConduit), bal);

        vm.prank(floAuth);
        maseerConduit.hope(address(this));
        vm.prank(floAuth);
        maseerConduit.kiss(bob);

        assertEq(IERC20(WETH).balanceOf(address(maseerConduit)), bal);
        assertEq(IERC20(WETH).balanceOf(bob), 0);
        assertEq(IERC20(DAI).balanceOf(address(maseerConduit)), bal);
        assertEq(IERC20(DAI).balanceOf(bob), 0);

        vm.expectEmit();
        emit MaseerConduit.Move(WETH, bob, bal);
        amt = maseerConduit.move(WETH, bob);

        assertEq(amt, bal);
        assertEq(IERC20(WETH).balanceOf(address(maseerConduit)), 0);
        assertEq(IERC20(WETH).balanceOf(bob), bal);
        assertEq(IERC20(DAI).balanceOf(address(maseerConduit)), bal);
        assertEq(IERC20(DAI).balanceOf(bob), 0);

        vm.expectEmit();
        emit MaseerConduit.Move(DAI, bob, bal);
        amt = maseerConduit.move(DAI, bob);

        assertEq(amt, bal);
        assertEq(IERC20(WETH).balanceOf(address(maseerConduit)), 0);
        assertEq(IERC20(WETH).balanceOf(bob), bal);
        assertEq(IERC20(DAI).balanceOf(address(maseerConduit)), 0);
        assertEq(IERC20(DAI).balanceOf(bob), bal);
    }

}
