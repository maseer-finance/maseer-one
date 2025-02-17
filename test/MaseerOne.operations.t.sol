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
        act.setCooldown(5 days);
        vm.prank(actAuth);
        act.setCapacity(1_000_000 * 1e18); // 1M Cana total supply

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
        assertEq(act.nextOpenMint(), block.timestamp);
    }

    function testNextHaltMint() public view {
        assertEq(act.nextHaltMint(), block.timestamp + 1 days);
    }

    function testNextOpenBurn() public view {
        assertEq(act.nextOpenBurn(), block.timestamp);
    }

    function testNextHaltBurn() public view {
        assertEq(act.nextHaltBurn(), block.timestamp + 1 days);
    }

    function testMint() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        assertEq(usdt.balanceOf(alice),  1_000_000 * 1e6);

        vm.expectEmit();
        emit MaseerOne.ContractCreated(alice, 10050000, 9950248756218905472637);
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

    function testMintFail() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        assertEq(usdt.balanceOf(alice),  1_000_000 * 1e6);

        vm.expectRevert(abi.encodeWithSelector(MaseerOne.DustThreshold.selector, maseerOne.mintcost()));
        vm.prank(alice);
        maseerOne.mint(9 * 1e6);

        vm.expectRevert(abi.encodeWithSelector(MaseerOne.DustThreshold.selector, maseerOne.mintcost()));
        vm.prank(alice);
        maseerOne.mint(0);
    }

    function testRedeem() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        maseerOne.settle();
        assertEq(maseerOne.totalPending(), 0);
        assertEq(_amt, _wdiv(100_000 * 1e6, maseerOne.mintcost()));

        vm.expectEmit();
        emit MaseerOne.ContractRedemption(0, alice, 99007452736);
        vm.prank(alice);
        uint256 _id = maseerOne.redeem(_amt);
        assertTrue(_id == 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6);
        assertEq(maseerOne.totalPending(), maseerOne.redemptionAmount(_id));
        assertEq(maseerOne.redemptionAddr(_id), address(alice));
        assertEq(maseerOne.redemptionDate(_id), block.timestamp + maseerOne.cooldown());
        assertEq(maseerOne.redemptionAmount(_id), _wmul(_amt, maseerOne.burncost()));
        assertEq(maseerOne.obligated(), maseerOne.redemptionAmount(_id));

        // Put tokens back into the contract to settle the claim
        _mintUSDT(address(maseerOne), maseerOne.redemptionAmount(_id));
        assertEq(usdt.balanceOf(address(maseerOne)), maseerOne.redemptionAmount(_id));
        assertEq(maseerOne.obligated(), 0);
        assertEq(maseerOne.unsettled(), 0);
    }

    function testExit() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        vm.prank(alice);
        uint256 _id = maseerOne.redeem(_amt);

        uint256 _exitTime = block.timestamp + maseerOne.cooldown();

        vm.warp(block.timestamp + maseerOne.cooldown() + 1);

        vm.expectEmit();
        emit MaseerOne.ClaimProcessed(_id, alice, 99007452736);
        vm.prank(alice);
        uint256 _out = maseerOne.exit(_id);
        assertTrue(_out > 0);
        assertEq(maseerOne.redemptionAmount(_id), 0);
        assertEq(maseerOne.redemptionAddr(_id), address(alice));
        assertEq(maseerOne.redemptionDate(_id), _exitTime);
        assertEq(maseerOne.obligated(), 0);
        assertEq(maseerOne.unsettled(), usdt.balanceOf(address(maseerOne)));
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6 + _out);
    }

    function testSettle() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        maseerOne.mint(100_000 * 1e6);

        uint256 _bal = usdt.balanceOf(maseerOneAddr);
        assertTrue(_bal > 0);

        vm.expectEmit();
        emit MaseerOne.Settled(maseerOne.flo(), _bal);
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

        assertEq(usdt.balanceOf(maseerOneAddr), 0);
        assertEq(usdt.balanceOf(maseerOne.flo()), _bal);

        vm.prank(floAuth);
        flo.kiss(offramp);
        vm.prank(floAuth);
        flo.hope(agent);

        vm.prank(agent);
        uint256 _amt = flo.move(USDT, offramp, 10);
        assertEq(_amt, 10);
        assertEq(usdt.balanceOf(offramp), 10);
        assertEq(usdt.balanceOf(maseerOneAddr), 0);
        assertEq(usdt.balanceOf(agent), 0);
        assertEq(usdt.balanceOf(maseerOne.flo()), _bal - 10);

        vm.prank(agent);
        flo.move(USDT, offramp);

        assertEq(usdt.balanceOf(offramp), _bal);
        assertEq(usdt.balanceOf(maseerOneAddr), 0);
        assertEq(usdt.balanceOf(agent), 0);
        assertEq(usdt.balanceOf(maseerOne.flo()), 0);
    }

    function testDestroy() public {
        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 out = maseerOne.mint(100_000 * 1e6);
        assertEq(maseerOne.totalSupply(), out);

        vm.expectEmit();
        emit MaseerOne.Destroyed(alice, 10 * WAD);
        vm.prank(alice);
        maseerOne.destroy(10 * WAD);

        assertEq(maseerOne.totalSupply(), out - 10 * WAD);
        assertEq(maseerOne.balanceOf(alice), out - 10 * WAD);
    }

}
