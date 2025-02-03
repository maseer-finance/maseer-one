// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

//import {console} from "forge-std/Test.sol";
import "./MaseerTestBase.t.sol";

contract MaseerOneOperationsTest is MaseerTestBase {

    function setUp() public {

        vm.prank(actAuth);
        act.setOpen(block.timestamp);
        vm.prank(actAuth);
        act.setHalt(block.timestamp + 1 days);
        vm.prank(actAuth);
        act.setBpsin(50);
        vm.prank(actAuth);
        act.setBpsout(50);
        vm.prank(actAuth);
        act.setDelay(5 days);
        vm.prank(actAuth);
        act.setCap(1_000_000 * 1e18);

        vm.prank(pipAuth);
        pip.poke(10 * 1e6);

        _mintUSDT(alice, 1_000_000 * 1e6);
        _mintUSDT(bob, 1_000_000 * 1e6);
        _mintUSDT(carol, 1_000_000 * 1e6);
    }

    function testOpen() public view {
        assertEq(maseerOne.open(), true);
    }

    function testNextOpen() public view {
        assertEq(maseerOne.nextOpen(), block.timestamp);
    }

    function testNextHalt() public view {
        assertEq(maseerOne.nextHalt(), block.timestamp + 1 days);
    }

    function testMint() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        assertEq(usdt.balanceOf(alice),  1_000_000 * 1e6);

        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        assertTrue(_amt > 0);
        assertEq(maseerOne.totalSupply(), _amt);
        assertEq(maseerOne.balanceOf(alice), _amt);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6);

        vm.prank(bob);
        usdt.approve(address(maseerOne), 100_000 * 1e6);
        assertEq(usdt.balanceOf(bob),  1_000_000 * 1e6);

        vm.prank(bob);
        _amt = maseerOne.mint(100_000 * 1e6);
        assertTrue(_amt > 0);
        assertEq(maseerOne.totalSupply(), _amt * 2);
        assertEq(maseerOne.balanceOf(bob), _amt);
        assertEq(usdt.balanceOf(bob), 900_000 * 1e6);
    }

    function testBurn() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);

        vm.prank(alice);
        uint256 _claim = maseerOne.burn(_amt);
        assertTrue(_claim > 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6);
        assertEq(maseerOne.totalPending(), _claim);
        assertEq(maseerOne.pendingExit(alice), _claim);
        assertEq(maseerOne.pendingTime(alice), block.timestamp + maseerOne.claimDelay());
    }

    function testExit() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        vm.prank(alice);
        uint256 _claim = maseerOne.burn(_amt);

        uint256 _exitTime = block.timestamp + maseerOne.claimDelay();

        vm.warp(block.timestamp + maseerOne.claimDelay() + 1);

        vm.prank(alice);
        uint256 _out = maseerOne.exit();
        assertTrue(_out > 0);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.pendingExit(alice), 0);
        assertEq(maseerOne.pendingTime(alice), _exitTime);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6 + _claim);
    }

}
