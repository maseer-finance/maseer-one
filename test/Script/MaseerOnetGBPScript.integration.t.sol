// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20}        from "forge-std/interfaces/IERC20.sol";

import {MaseerOne}      from "../../src/MaseerOne.sol";
import {MaseerPrice}    from "../../src/MaseerPrice.sol";
import {MaseerGate}     from "../../src/MaseerGate.sol";
import {MaseerTreasury} from "../../src/MaseerTreasury.sol";
import {MaseerGuardOZ}  from "../../src/MaseerGuardOZ.sol";
import {MaseerProxy}    from "../../src/MaseerProxy.sol";

import "../../script/MaseerOnetGBP.s.sol";

contract MaseerOnetGBPIntegrationTest is Test {

    uint256 public constant WAD = 1e18;

    MaseerOnetGBPScript public script;
    MaseerOne public maseerOne;
    IERC20    public tgbp;
    address   public sigOne;

    address public alice;
    address public bob;
    address public carol;

    function setUp() public {
        script = new MaseerOnetGBPScript();
        script.run();

        maseerOne = script.maseerOne();
        tgbp      = IERC20(script.TGBP());
        sigOne    = script.SIG_ONE();

        alice = makeAddr("alice");
        bob   = makeAddr("bob");
        carol = makeAddr("carol");

        // Seed test accounts with tGBP
        deal(address(tgbp), alice, 1_000_000 * WAD);
        deal(address(tgbp), bob,   1_000_000 * WAD);
        deal(address(tgbp), carol, 1_000_000 * WAD);
    }

    // ---- Market State ----

    function testMintable() public view {
        assertEq(maseerOne.mintable(), true);
    }

    function testBurnable() public view {
        assertEq(maseerOne.burnable(), true);
    }

    function testInitialPrices() public view {
        assertEq(maseerOne.navprice(), 1 * WAD);
        // BPSIN = 0, so mintcost == navprice
        assertEq(maseerOne.mintcost(), 1 * WAD);
        // BPSOUT = 25 bps
        uint256 expectedBurncost = (1 * WAD * (10_000 - 25) + 9_999) / 10_000;
        assertEq(maseerOne.burncost(), expectedBurncost);
    }

    function testFloIsSelf() public view {
        assertEq(maseerOne.flo(), address(maseerOne));
    }

    // ---- Mint ----

    function testMint() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);

        vm.prank(alice);
        uint256 out = maseerOne.mint(mintAmt);

        assertTrue(out > 0);
        assertEq(maseerOne.totalSupply(), out);
        assertEq(maseerOne.balanceOf(alice), out);
        assertEq(tgbp.balanceOf(alice), 1_000_000 * WAD - mintAmt);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.unsettled(), mintAmt);
    }

    function testMintMultipleUsers() public {
        uint256 mintAmt = 50_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 outA = maseerOne.mint(mintAmt);

        vm.prank(bob);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(bob);
        uint256 outB = maseerOne.mint(mintAmt);

        assertEq(outA, outB);
        assertEq(maseerOne.totalSupply(), outA + outB);
        assertEq(maseerOne.unsettled(), mintAmt * 2);
    }

    function testMintFailDust() public {
        vm.prank(alice);
        tgbp.approve(address(maseerOne), WAD);

        // Zero amount should revert
        vm.expectRevert(abi.encodeWithSelector(MaseerOne.DustThreshold.selector, maseerOne.mintcost()));
        vm.prank(alice);
        maseerOne.mint(0);
    }

    function testMintFailMarketClosed() public {
        // Close the market — cache act address to avoid consuming prank
        address actProxy = maseerOne.act();
        vm.prank(sigOne);
        MaseerGate(actProxy).pauseMarket();

        vm.prank(alice);
        tgbp.approve(address(maseerOne), 100 * WAD);

        vm.expectRevert(MaseerOne.MarketClosed.selector);
        vm.prank(alice);
        maseerOne.mint(100 * WAD);
    }

    // ---- Redeem ----

    function testRedeem() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        // Settle first so tGBP goes to self
        maseerOne.settle();

        vm.prank(alice);
        uint256 id = maseerOne.redeem(minted);

        assertEq(id, 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(maseerOne.totalPending(), maseerOne.redemptionAmount(id));
        assertEq(maseerOne.redemptionAddr(id), alice);
        assertEq(maseerOne.redemptionDate(id), block.timestamp + maseerOne.cooldown());

        uint256 expectedClaim = _wmul(minted, maseerOne.burncost());
        assertEq(maseerOne.redemptionAmount(id), expectedClaim);
    }

    function testRedeemFailDust() public {
        vm.prank(alice);
        tgbp.approve(address(maseerOne), 100 * WAD);
        vm.prank(alice);
        maseerOne.mint(100 * WAD);

        vm.expectRevert(abi.encodeWithSelector(MaseerOne.DustThreshold.selector, WAD));
        vm.prank(alice);
        maseerOne.redeem(WAD - 1);
    }

    // ---- Exit ----

    function testExit() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        vm.prank(alice);
        uint256 id = maseerOne.redeem(minted);

        // Warp past cooldown
        vm.warp(block.timestamp + maseerOne.cooldown() + 1);

        uint256 aliceBalBefore = tgbp.balanceOf(alice);

        vm.prank(alice);
        uint256 out = maseerOne.exit(id);

        assertTrue(out > 0);
        assertEq(maseerOne.redemptionAmount(id), 0);
        assertEq(maseerOne.obligated(), 0);
        assertEq(tgbp.balanceOf(alice), aliceBalBefore + out);
    }

    function testExitFailBeforeCooldown() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        vm.prank(alice);
        uint256 id = maseerOne.redeem(minted);

        uint256 claimDate = maseerOne.redemptionDate(id);

        vm.expectRevert(abi.encodeWithSelector(MaseerOne.ClaimableAfter.selector, claimDate));
        vm.prank(alice);
        maseerOne.exit(id);
    }

    // ---- Settle (self-referencing flo) ----

    function testSettleSendsToSelf() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        maseerOne.mint(mintAmt);

        uint256 bal = tgbp.balanceOf(address(maseerOne));
        assertTrue(bal > 0);

        vm.expectEmit();
        emit MaseerOne.Settled(address(maseerOne), bal);
        vm.prank(bob);
        uint256 out = maseerOne.settle();

        // flo == maseerOne, so balance stays the same (self-transfer)
        assertEq(tgbp.balanceOf(address(maseerOne)), bal);
        assertEq(out, bal);
    }

    function testSettleAfterRedeem() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        // Redeem half
        uint256 half = minted / 2;
        vm.prank(alice);
        maseerOne.redeem(half);

        uint256 pending = maseerOne.totalPending();
        uint256 bal = tgbp.balanceOf(address(maseerOne));
        uint256 expectedSettle = bal - pending;

        vm.prank(bob);
        uint256 out = maseerOne.settle();

        // Settle only moves unsettled portion; self-transfer keeps balance intact
        assertEq(out, expectedSettle);
        assertEq(tgbp.balanceOf(address(maseerOne)), bal);
    }

    function testSettleAfterFullRedeem() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        // Redeem everything — with 25 bps fee, pending < balance (fee spread remains)
        vm.prank(alice);
        maseerOne.redeem(minted);

        uint256 bal = tgbp.balanceOf(address(maseerOne));
        uint256 pending = maseerOne.totalPending();
        assertTrue(bal > pending, "fee spread should leave unsettled funds");

        vm.prank(bob);
        uint256 out = maseerOne.settle();

        // Settle returns the fee spread; self-transfer keeps balance intact
        assertEq(out, bal - pending);
        assertEq(tgbp.balanceOf(address(maseerOne)), bal);
    }

    // ---- Full lifecycle ----

    function testMintRedeemExitLifecycle() public {
        uint256 mintAmt = 100_000 * WAD;

        // Mint
        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);
        assertEq(maseerOne.balanceOf(alice), minted);

        // Settle (self-transfer, balance stays)
        vm.prank(bob);
        maseerOne.settle();
        assertEq(tgbp.balanceOf(address(maseerOne)), mintAmt);

        // Redeem
        vm.prank(alice);
        uint256 id = maseerOne.redeem(minted);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(maseerOne.totalSupply(), 0);

        uint256 claimAmt = maseerOne.redemptionAmount(id);
        assertTrue(claimAmt > 0);

        // Warp past cooldown and exit
        vm.warp(block.timestamp + maseerOne.cooldown() + 1);

        uint256 aliceBefore = tgbp.balanceOf(alice);
        vm.prank(alice);
        uint256 out = maseerOne.exit(id);

        assertEq(out, claimAmt);
        assertEq(tgbp.balanceOf(alice), aliceBefore + claimAmt);
        assertEq(maseerOne.redemptionAmount(id), 0);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.obligated(), 0);
    }

    function testMultipleRedemptionsCycle() public {
        uint256 mintAmt = 100_000 * WAD;

        // Alice and Bob both mint
        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 mintedA = maseerOne.mint(mintAmt);

        vm.prank(bob);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(bob);
        uint256 mintedB = maseerOne.mint(mintAmt);

        // Both redeem
        vm.prank(alice);
        uint256 idA = maseerOne.redeem(mintedA);
        vm.prank(bob);
        uint256 idB = maseerOne.redeem(mintedB);

        assertEq(idA, 0);
        assertEq(idB, 1);
        assertEq(maseerOne.totalSupply(), 0);

        // Warp and exit
        vm.warp(block.timestamp + maseerOne.cooldown() + 1);

        vm.prank(alice);
        uint256 outA = maseerOne.exit(idA);
        vm.prank(bob);
        uint256 outB = maseerOne.exit(idB);

        assertTrue(outA > 0);
        assertTrue(outB > 0);
        assertEq(outA, outB);
        assertEq(maseerOne.totalPending(), 0);
    }

    // ---- Smelt (user-level burn) ----

    function testSmelt() public {
        uint256 mintAmt = 100_000 * WAD;

        vm.prank(alice);
        tgbp.approve(address(maseerOne), mintAmt);
        vm.prank(alice);
        uint256 minted = maseerOne.mint(mintAmt);

        uint256 burnAmt = 10 * WAD;

        vm.expectEmit();
        emit MaseerOne.Smelted(alice, burnAmt);
        vm.prank(alice);
        maseerOne.smelt(burnAmt);

        assertEq(maseerOne.totalSupply(), minted - burnAmt);
        assertEq(maseerOne.balanceOf(alice), minted - burnAmt);
    }

    // ---- Helpers ----

    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (WAD / 2)) / WAD;
    }
}
