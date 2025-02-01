// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneTokenTest is MaseerTestBase {

    function setUp() public {
        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
    }

    function testTransferUnit() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);
        assertEq(maseerOne.balanceOf(alice), amt);
        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(maseerOne.totalSupply(), amt);

        vm.prank(alice);
        maseerOne.transfer(bob, amt);

        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(maseerOne.balanceOf(bob), amt);
        assertEq(maseerOne.totalSupply(), totalSupply);
    }

    function testTransferFromUnit() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);
        assertEq(maseerOne.balanceOf(alice), amt);
        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(maseerOne.totalSupply(), amt);

        vm.prank(alice);
        maseerOne.approve(bob, amt);

        vm.prank(bob);
        maseerOne.transferFrom(alice, bob, amt / 2);

        assertEq(maseerOne.balanceOf(alice), amt / 2);
        assertEq(maseerOne.balanceOf(bob), amt / 2);
        assertEq(maseerOne.totalSupply(), totalSupply);
        assertEq(maseerOne.allowance(alice, bob), amt / 2);

        // Alice isn't approved for transferFrom
        vm.expectRevert();
        vm.prank(alice);
        maseerOne.transferFrom(alice, bob, amt / 2);

        assertEq(maseerOne.balanceOf(alice), amt / 2);
        assertEq(maseerOne.balanceOf(bob), amt / 2);
        assertEq(maseerOne.totalSupply(), totalSupply);

        vm.prank(bob);
        maseerOne.transferFrom(alice, carol, amt / 2);

        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(maseerOne.balanceOf(bob), amt / 2);
        assertEq(maseerOne.balanceOf(carol), amt / 2);
        assertEq(maseerOne.totalSupply(), totalSupply);
        assertEq(maseerOne.allowance(alice, bob), 0);
    }

    function testFuzzTransfer(address to, address from, uint256 amt) public {
        uint256 toBal = maseerOne.balanceOf(to);
        uint256 fromBal = maseerOne.balanceOf(from);

        _mintTokens(from, amt);
        assertEq(maseerOne.balanceOf(from), fromBal + amt);
        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(maseerOne.totalSupply(), amt);

        // Don't send to the contract
        if (to == address(maseerOne)) {
            vm.expectRevert(MaseerOne.TransferToContract.selector);
            vm.prank(from);
            maseerOne.transfer(to, amt);
            return;
        }

        // Don't send to unauthorized user
        if (!maseerOne.canPass(to) || !maseerOne.canPass(from)) {
            vm.expectRevert(MaseerOne.UnauthorizedUser.selector);
            vm.prank(from);
            maseerOne.transfer(to, amt);
            return;
        }

        vm.prank(from);
        maseerOne.transfer(to, amt);

        if (from == to) {
            assertEq(maseerOne.balanceOf(from), amt);
            assertEq(maseerOne.balanceOf(to), amt);
            assertEq(maseerOne.totalSupply(), totalSupply);
        } else {
            assertEq(maseerOne.balanceOf(from), 0);
            assertEq(maseerOne.balanceOf(to), toBal + amt);
            assertEq(maseerOne.totalSupply(), totalSupply);
        }
    }

    function testFuzzTransferFrom(address to, address from, uint256 amt) public {
        uint256 toBal = maseerOne.balanceOf(to);
        uint256 fromBal = maseerOne.balanceOf(from);

        _mintTokens(from, amt);
        assertEq(maseerOne.balanceOf(from), fromBal + amt);
        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(maseerOne.totalSupply(), amt);

        if (!maseerOne.canPass(from) || !maseerOne.canPass(to)) {

            if (!maseerOne.canPass(from)) { vm.expectRevert(MaseerOne.UnauthorizedUser.selector); }
            vm.prank(from);
            maseerOne.approve(from, amt);

            if (to == address(maseerOne)) {
                vm.expectRevert(MaseerOne.TransferToContract.selector);
            } else {
                vm.expectRevert(MaseerOne.UnauthorizedUser.selector);
            }
            vm.prank(to);
            maseerOne.transferFrom(from, to, amt);
            return;
        }

        vm.prank(from);
        maseerOne.approve(to, amt);

        if (to == address(maseerOne)) {
            vm.expectRevert(MaseerOne.TransferToContract.selector);
            vm.prank(to);
            maseerOne.transferFrom(from, to, amt);
            return;
        }

        vm.prank(to);
        maseerOne.transferFrom(from, to, amt);

        if (from == to) {
            assertEq(maseerOne.balanceOf(from), amt);
            assertEq(maseerOne.balanceOf(to), amt);
            assertEq(maseerOne.totalSupply(), totalSupply);
        } else {
            assertEq(maseerOne.balanceOf(from), 0);
            assertEq(maseerOne.balanceOf(to), toBal + amt);
            assertEq(maseerOne.totalSupply(), totalSupply);
        }
    }

    // TODO: General ERC20 tests
    // TODO: Test can't send to zero address
    // TODO: Test can't send to self
}
