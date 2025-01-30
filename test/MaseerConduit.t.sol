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

        vm.prank(alice);
        maseerConduit.rely(address(this));

        assertEq(maseerConduit.wards(address(this)), 1);
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

    function testMove() public {

        uint256 amt;
        uint256 bal = 100_000 * 1e6;

        maseerConduit.hope(alice);
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
        maseerConduit.hope(alice);

        vm.expectRevert(bytes("MaseerConduit/invalid-address"));
        vm.prank(alice);
        maseerConduit.move(USDT, carol);
    }

    function testMoveFailNotCan() public {

        // carol is a valid destination but alice is not a valid operator
        maseerConduit.kiss(carol);

        vm.expectRevert(bytes("MaseerConduit/not-operator"));
        vm.prank(alice);
        maseerConduit.move(USDT, carol);
    }

    function testMoveFailNotAuth() public {

        // alice is not authorized to modify permissions

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.rely(alice);

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.deny(alice);

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.hope(alice);

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.nope(alice);

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.kiss(alice);

        vm.expectRevert(bytes("MaseerConduit/not-authorized"));
        vm.prank(alice);
        maseerConduit.diss(alice);
    }

    function testMoveWETH() public {

        uint256 amt;
        uint256 bal = 100_000 * 1e18;

        deal(WETH, address(maseerConduit), bal);
        deal(DAI, address(maseerConduit), bal);

        maseerConduit.hope(address(this));
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
