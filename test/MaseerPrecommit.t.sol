// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";
import {MaseerPrecommit} from "../src/MaseerPrecommit.sol";

contract MaseerPrecommitTest is MaseerTestBase {

    MaseerPrecommit public maseerPrecommit;

    struct UserCommit {
        address usr;
        uint256 amt;
    }

    function setUp() public {
        maseerPrecommit = new MaseerPrecommit(maseerOneAddr);
    }

    function testPrecommit() public {
        _mintUSDT(alice, 100_000 * 1e6);

        vm.prank(alice);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);

        // alice approves maseerPrecommit to spend 1000 USDT
        vm.prank(alice);
        maseerPrecommit.pact(1000 * 1e6);

        assertEq(maseerPrecommit.deals(), 1);
        assertEq(maseerPrecommit.usr(0), alice);
        assertEq(maseerPrecommit.amt(0), 1000 * 1e6);
    }

    function testPrecommitMin() public view {
        assertEq(maseerPrecommit.min(), 1000 * 1e6);
    }

    function test_failPrecommitZeroAmt() public {
        _mintUSDT(alice, 100_000 * 1e6);

        vm.prank(alice);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);

        // alice approves maseerPrecommit to spend 1000 USDT
        vm.expectRevert(MaseerPrecommit.InsufficientAmount.selector);
        vm.prank(alice);
        maseerPrecommit.pact(0);
    }

    function test_failPrecommitInsufficientAllowance() public {
        _mintUSDT(alice, 100_000 * 1e6);

        vm.prank(alice);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);

        // alice approves maseerPrecommit to spend 1000 USDT
        vm.expectRevert(MaseerPrecommit.InsufficientAllowance.selector);
        vm.prank(bob);
        maseerPrecommit.pact(1000 * 1e6);
    }

    function test_failPrecommitPactUnauthorizedUser() public {

        assertEq(maseerOne.canPass(enemy), false);

        _mintUSDT(enemy, 100_000 * 1e6);

        vm.prank(enemy);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);

        vm.expectRevert(MaseerPrecommit.NotAuthorized.selector);
        vm.prank(enemy);
        maseerPrecommit.pact(1000 * 1e6);
    }

    function test_failPrecommitExecUnauthorizedUser() public {
        _mintUSDT(alice, 100_000 * 1e6);

        vm.prank(alice);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);

        // alice approves maseerPrecommit to spend 1000 USDT
        vm.prank(alice);
        maseerPrecommit.pact(1000 * 1e6);

        vm.expectRevert(MaseerPrecommit.NotAuthorized.selector);
        vm.prank(enemy);
        maseerPrecommit.exec(0);
    }

    function test_failPrecommitExitUnauthorizedUser() public {
        vm.expectRevert(MaseerPrecommit.NotAuthorized.selector);
        vm.prank(enemy);
        maseerPrecommit.exit();
    }

    function testPrecommitExec() public {

        // open market
        vm.prank(actAuth);
        act.setOpenMint(block.timestamp);
        vm.prank(actAuth);
        act.setHaltMint(block.timestamp);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);
        vm.prank(pipBud);
        pip.poke(10 * 1e6); // 10 USDT per token (no fee)


        // Config user balances
        _mintUSDT(alice, 100_000 * 1e6);
        assertEq(maseerOne.balanceOf(alice), 0);
        vm.prank(alice);
        usdt.approve(address(maseerPrecommit), 1000 * 1e6);
        vm.prank(alice);
        maseerPrecommit.pact(1000 * 1e6);

        maseerPrecommit.exec(0);

        assertEq(usdt.balanceOf(address(maseerPrecommit)), 0);
        assertEq(maseerOne.balanceOf(alice), 100 * 1e18);
    }

    function test_failPrecommitExec() public {

        // execute a precommit that doesn't exist
        vm.expectRevert(MaseerPrecommit.InsufficientAmount.selector);
        maseerPrecommit.exec(1);
    }

    function testPrecommitMany() public {
        uint256 n = 100;

        UserCommit[] memory users = new UserCommit[](n);

        for (uint256 i = 0; i < n; i++) {
            address _usr = makeAddr(string(abi.encode(i)));
            uint256 _amt = bound((uint256(block.number) + i), 1000, 100000) * 1e6;
            _mintUSDT(_usr, _amt);
            vm.prank(_usr);
            usdt.approve(address(maseerPrecommit), _amt);

            users[i] = UserCommit({
                usr: _usr,
                amt: _amt
            });
        }

        for (uint256 i = 0; i < n; i++) {
            vm.prank(users[i].usr);
            maseerPrecommit.pact(users[i].amt);
        }

        assertEq(maseerPrecommit.deals(), n);

        for (uint256 i = 0; i < n; i++) {
            assertEq(maseerPrecommit.usr(i), users[i].usr);
            assertEq(maseerPrecommit.amt(i), users[i].amt);
        }
    }

    function testPrecommitExecMany() public {
        uint256 n = 100;

        UserCommit[] memory users = new UserCommit[](n);

        for (uint256 i = 0; i < n; i++) {
            address _usr = makeAddr(string(abi.encode(i)));
            uint256 _amt = bound((uint256(block.number) + i), 1000, 100000) * 1e6;
            _mintUSDT(_usr, _amt);
            vm.prank(_usr);
            usdt.approve(address(maseerPrecommit), _amt);

            users[i] = UserCommit({
                usr: _usr,
                amt: _amt
            });
        }

        for (uint256 i = 0; i < n; i++) {
            vm.prank(users[i].usr);
            maseerPrecommit.pact(users[i].amt);
        }

        // open market
        vm.prank(actAuth);
        act.setOpenMint(block.timestamp);
        vm.prank(actAuth);
        act.setHaltMint(block.timestamp);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);
        vm.prank(pipBud);
        pip.poke(10 * 1e6); // 10 USDT per token (no fee)

        for (uint256 i = 0; i < n; i++) {
            maseerPrecommit.exec(i);
        }

        uint256 supply;
        for (uint256 i = 0; i < n; i++) {
            assertEq(usdt.balanceOf(users[i].usr), 0);
            assertEq(maseerOne.balanceOf(users[i].usr), users[i].amt * 1e11);
            supply += users[i].amt * 1e11;
        }

        assertEq(maseerOne.totalSupply(), supply);
    }

    function testPrecommitExit() public {

        // Whoops someone sent USDT to the contract
        _mintUSDT(address(maseerPrecommit), 1000 * 1e6);

        assertEq(usdt.balanceOf(address(maseerPrecommit)), 1000 * 1e6);

        maseerPrecommit.exit();

        assertEq(usdt.balanceOf(address(maseerPrecommit)), 0);
        assertEq(usdt.balanceOf(address(maseerOne.flo())), 1000 * 1e6);

    }
}
