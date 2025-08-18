// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";
import {MaseerSage} from "../src/MaseerSage.sol";

contract MaseerSageTest is MaseerTestBase {

    MaseerSage public maseerSage;

    function setUp() public {
        maseerSage = new MaseerSage(maseerOneAddr);
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
        act.setCooldown(5 days);
        vm.prank(actAuth);
        act.setCapacity(1_000_000 * 1e18); // 1M Cana total supply

        vm.prank(pipBud);
        pip.poke(10 * 1e6); // 10 USDT per token

        _mintUSDT(alice, 1_000_000 * 1e6);

        _mintTokens(alice, 1000 * 1e18);

        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(totalSupply, 1000 * 1e18);
    }

    function testConstructor() public view {
        assertEq(maseerSage.ONE(), maseerOneAddr);
    }

    function testGap() public view {
        assertEq(maseerSage.gap(), maseerOne.capacity() - maseerOne.totalSupply());
    }

    function testUsdtGap() public view {
        uint256 usdtPrice = pip.read();
        uint256 mintPrice = act.mintcost(usdtPrice);
        uint256 gap = maseerOne.capacity() - maseerOne.totalSupply();

        assertEq(maseerSage.usdtGap(), gap * mintPrice / WAD);
    }

    function testPeekMint() public {
        uint256 amt = 100 * 1e6;
        uint256 peekMint = maseerSage.peekMint(amt);
        _mintUSDT(alice, amt);
        vm.startPrank(alice);
        usdt.approve(address(maseerOne), amt);
        uint256 actualMint = maseerOne.mint(amt);
        vm.stopPrank();

        assertEq(peekMint, actualMint);
    }

    function testPeekMintZeroPrice() public {
        vm.prank(pipBud);
        pip.poke(0);

        assertEq(maseerSage.peekMint(1), 0);
    }

    function testPeekMintAtCapacity() public {
        uint256 totalSupply = maseerOne.totalSupply();
        vm.prank(actAuth);
        act.file("capacity", totalSupply);

        assertEq(maseerSage.peekMint(1), 0);
    }

    function testPeekMintAtUSDTCapacity() public view {
        uint256 usdtGap = maseerSage.usdtGap();

        assertEq(maseerSage.peekMint(usdtGap + 1), 0);
    }

    function testPeekMintNotMintable() public {
        vm.prank(actAuth);
        act.setOpenMint(block.timestamp + 100);
        assertFalse(maseerOne.mintable());

        assertEq(maseerSage.peekMint(1), 0);
    }

    function testPeekMintDusty() public view {
        assertEq(maseerSage.peekMint(1), 0);
    }

    function testPeekRedeem() public {
        uint256 amt = 100 * 1e18;
        uint256 peekRedeem = maseerSage.peekRedeem(amt);
        vm.prank(alice);
        uint256 id = maseerOne.redeem(amt);

        assertEq(maseerOne.redemptionAddr(id), alice);

        assertEq(peekRedeem, maseerOne.redemptionAmount(id));
    }

    function testPeekRedeemZeroPrice() public {
        vm.prank(pipBud);
        pip.poke(0);

        assertEq(maseerSage.peekRedeem(1), 0);
    }

    function testPeekRedeemDusty() public view {
        assertEq(maseerSage.peekRedeem(WAD - 1), 0);
    }

    function testPeekRedeemNoBurning() public {
        vm.prank(actAuth);
        act.setOpenBurn(block.timestamp + 100);
        assertFalse(maseerOne.burnable());

        assertEq(maseerSage.peekRedeem(1), 0);
    }
}
