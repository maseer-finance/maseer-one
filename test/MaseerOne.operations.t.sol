// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

//import {console} from "forge-std/Test.sol";
import "./MaseerTestBase.t.sol";

contract MaseerOneOperationsTest is MaseerTestBase {

    function setUp() public {

        vm.prank(actAuth);
        act.setOpenMint(block.timestamp);
        vm.prank(actAuth);
        act.setHaltMint(block.timestamp + 1 days);
        vm.prank(actAuth);
        act.setOpenBurn(block.timestamp);
        vm.prank(actAuth);
        act.setHaltBurn(block.timestamp + 1 days);
        vm.prank(actAuth);
        act.setBpsin(50); // 0.5%
        vm.prank(actAuth);
        act.setBpsout(50); // 0.5%
        vm.prank(actAuth);
        act.setDelay(5 days);
        vm.prank(actAuth);
        act.setCap(1_000_000 * 1e18); // 1M Cana total supply

        vm.prank(pipAuth);
        pip.poke(10 * 1e6); // 10 USDT per token

        _mintUSDT(alice, 1_000_000 * 1e6);
        _mintUSDT(bob, 1_000_000 * 1e6);
        _mintUSDT(carol, 1_000_000 * 1e6);
    }

    function testMintable() public view {
        assertEq(maseerOne.mintable(), true);
    }

    function testBurnable() public view {
        assertEq(maseerOne.burnable(), true);
    }

    function testNextOpenMint() public view {
        assertEq(maseerOne.nextOpenMint(), block.timestamp);
    }

    function testNextHaltMint() public view {
        assertEq(maseerOne.nextHaltMint(), block.timestamp + 1 days);
    }

    function testNextOpenBurn() public view {
        assertEq(maseerOne.nextOpenBurn(), block.timestamp);
    }

    function testNextHaltBurn() public view {
        assertEq(maseerOne.nextHaltBurn(), block.timestamp + 1 days);
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
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.unsettled(), 100_000 * 1e6);

        vm.prank(bob);
        usdt.approve(address(maseerOne), 100_000 * 1e6);
        assertEq(usdt.balanceOf(bob),  1_000_000 * 1e6);

        vm.prank(bob);
        _amt = maseerOne.mint(100_000 * 1e6);
        assertTrue(_amt > 0);
        assertEq(maseerOne.totalSupply(), _amt * 2);
        assertEq(maseerOne.balanceOf(bob), _amt);
        assertEq(usdt.balanceOf(bob), 900_000 * 1e6);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.unsettled(), 200_000 * 1e6);
    }

    function testBurn() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        maseerOne.settle();
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.pendingExit(alice), 0);
        assertEq(maseerOne.pendingTime(alice), 0);

        vm.prank(alice);
        uint256 _claim = maseerOne.burn(_amt);
        assertTrue(_claim > 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6);
        assertEq(maseerOne.totalPending(), _claim);
        assertEq(maseerOne.pendingExit(alice), _claim);
        assertEq(maseerOne.pendingTime(alice), block.timestamp + maseerOne.claimDelay());
        assertEq(maseerOne.obligated(), _claim);

        _mintUSDT(address(maseerOne), _claim);
        assertEq(usdt.balanceOf(address(maseerOne)), _claim);
        assertEq(maseerOne.obligated(), 0);
        assertEq(maseerOne.unsettled(), 0);
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

    function testSettle() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        maseerOne.mint(100_000 * 1e6);

        uint256 _bal = usdt.balanceOf(maseerOneAddr);
        assertTrue(_bal > 0);

        vm.prank(bob);
        maseerOne.settle();

        assertEq(usdt.balanceOf(maseerOneAddr), 0);
        assertEq(usdt.balanceOf(maseerOne.flo()), _bal);
    }

    function testConduitFlow() public {

        address offramp = makeAddr("offramp");
        address agent   = makeAddr("agent");

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        maseerOne.mint(100_000 * 1e6);
        uint256 _bal = usdt.balanceOf(maseerOneAddr);
        vm.prank(bob);
        maseerOne.settle();

        vm.prank(floAuth);
        flo.kiss(offramp);
        vm.prank(floAuth);
        flo.hope(agent);

        vm.prank(agent);
        flo.move(USDT, offramp);

        assertEq(usdt.balanceOf(offramp), _bal);
        assertEq(usdt.balanceOf(maseerOneAddr), 0);
        assertEq(usdt.balanceOf(agent), 0);
        assertEq(usdt.balanceOf(maseerOne.flo()), 0);
    }

}
