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

        vm.prank(pipBud);
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
        emit MaseerOne.ContractCreated(alice, 10050000, 9950248756218905472636);
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

    function testMintLowPrice() public {
        // Set the price to 0.000001 USDT
        vm.prank(pipBud);
        pip.poke(1);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        assertEq(usdt.balanceOf(alice),  1_000_000 * 1e6);

        uint256 _mintCost = maseerOne.mintcost();
        assertEq(_mintCost, 2);

        // results in 5e28 tokens minted
        vm.expectEmit();
        emit MaseerOne.ContractCreated(alice, _mintCost, 100_000 * 1e6 * 1e18 / _mintCost);
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

    function testFuzzMint(address usr, uint256 price, uint256 amt, uint256 bpsin) public {
        if (!cop.pass(usr)) return;
        price = bound(price, 1, 1e40); // Wide price range
        bpsin = bound(bpsin, 0, 10000); // 0% to 100%

        vm.prank(pipBud);
        pip.poke(price);
        vm.prank(actAuth);
        act.setBpsin(bpsin);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);

        uint256 _mintCost = maseerOne.mintcost();
        amt   = bound(amt, _mintCost, 1e50); // Wide amount range

        uint256 _bal = usdt.balanceOf(usr);
        _mintUSDT(usr, amt - _bal);

        vm.prank(usr);
        usdt.approve(address(maseerOne), amt);
        assertEq(usdt.balanceOf(usr),  amt);

        uint256 _expected = amt * 1e18 / _mintCost;

        vm.expectEmit();
        emit MaseerOne.ContractCreated(usr, _mintCost, _expected);
        vm.prank(usr);
        uint256 _amt = maseerOne.mint(amt);
        assertTrue(_amt > 0);
        assertEq(maseerOne.totalSupply(), _amt);
        assertEq(maseerOne.totalSupply(), _expected);
        assertEq(maseerOne.balanceOf(usr), _amt);
        assertEq(usdt.balanceOf(usr), 0);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.unsettled(), amt);
    }

    function testRedeem() public {

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        maseerOne.settle();
        assertEq(maseerOne.totalPending(), 0);
        assertEq(_amt, (100_000 * 1e6 * WAD) / maseerOne.mintcost());

        vm.expectEmit();
        emit MaseerOne.ContractRedemption(0, 99007452736, block.timestamp + maseerOne.cooldown(), alice);
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

    function testFuzzRedeem(address usr, uint256 price, uint256 amt, uint256 bpsin) public {
        if (!cop.pass(usr)) return;
        price = bound(price, 1, 1e30); // Wide price range
        bpsin = bound(bpsin, 0, 10000); // 0% to 100%

        vm.prank(pipBud);
        pip.poke(price);
        vm.prank(actAuth);
        act.setBpsin(bpsin);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);

        uint256 _burncost = maseerOne.burncost();
        amt = bound(amt, _burncost, 1e40); // Wide amount range

        console.log("amt1: %s", amt);
        console.log("totalSupply: %s", maseerOne.totalSupply());

        uint256 _preUSDT = usdt.balanceOf(usr);
        uint256 _preONE = maseerOne.balanceOf(usr);
        deal(address(maseerOne), usr, amt - _preONE, true);
        assertEq(maseerOne.balanceOf(usr),  amt);

        console.log("amt2: %s", amt);
        console.log("totalSupply: %s", maseerOne.totalSupply());


        uint256 _expected = amt * maseerOne.burncost() / WAD;

        if (_expected == 0) return;

        vm.expectEmit();
        emit MaseerOne.ContractRedemption(0, _expected, block.timestamp + maseerOne.cooldown(), usr);
        vm.prank(usr);
        uint256 _id = maseerOne.redeem(amt);
        assertTrue(_id == 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(usr), 0);
        assertEq(usdt.balanceOf(usr), _preUSDT);
        assertEq(maseerOne.totalPending(), maseerOne.redemptionAmount(_id));
        assertEq(maseerOne.redemptionAddr(_id), address(usr));
        assertEq(maseerOne.redemptionDate(_id), block.timestamp + maseerOne.cooldown());
        assertEq(maseerOne.redemptionAmount(_id), _expected);
        assertEq(maseerOne.obligated(), maseerOne.redemptionAmount(_id));
    }

    function testRedeemLowPrice() public {

        // Set the price to 0.000001 USDT
        vm.prank(pipBud);
        pip.poke(1);
        vm.prank(actAuth);
        act.setCapacity(type(uint256).max);

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);
        maseerOne.settle();
        assertEq(maseerOne.totalPending(), 0);
        assertEq(_amt, (100_000 * 1e6 * WAD) / maseerOne.mintcost());

        uint256 _redeemCost = maseerOne.burncost();
        assertEq(_redeemCost, 1);

        vm.expectEmit();
        emit MaseerOne.ContractRedemption(0, _amt / WAD, block.timestamp + maseerOne.cooldown(), alice);
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

    function testMintAndRedeemZeroBPS() public {
        vm.prank(actAuth);
        act.setBpsin(0); // 0%
        vm.prank(actAuth);
        act.setBpsout(0); // 0%

        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 _amt = maseerOne.mint(100_000 * 1e6);

        assertEq(maseerOne.mintcost(), maseerOne.navprice());
        assertEq(maseerOne.burncost(), maseerOne.navprice());
        assertEq(maseerOne.totalSupply(), _amt);
        assertEq(maseerOne.balanceOf(alice), _amt);
        uint256 _expectedAmt = 100_000 * 1e6 / maseerOne.mintcost() * WAD;
        assertEq(_amt, _expectedAmt);

        uint256 _expectedOut = _amt * maseerOne.burncost() / WAD;

        vm.expectEmit();
        emit MaseerOne.ContractRedemption(0, _expectedOut, block.timestamp + maseerOne.cooldown(), alice);
        vm.prank(alice);
        uint256 _id = maseerOne.redeem(_amt);
        assertTrue(_id == 0);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.balanceOf(alice), 0);
        assertEq(usdt.balanceOf(alice), 900_000 * 1e6);
        assertEq(maseerOne.totalPending(), maseerOne.redemptionAmount(_id));
        assertEq(maseerOne.redemptionAddr(_id), address(alice));
        assertEq(maseerOne.redemptionDate(_id), block.timestamp + maseerOne.cooldown());
        assertEq(maseerOne.redemptionAmount(_id), _expectedOut);
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

    function testIssue() public {
        vm.prank(admAuth);
        adm.bestow(bank);

        uint256 amt = 100_000 * 1e18;
        uint256 sup = maseerOne.totalSupply();

        vm.prank(bank);
        maseerOne.issue(amt);

        assertEq(maseerOne.totalSupply(), sup + amt);
        assertEq(maseerOne.balanceOf(bank), amt);

    }

    function testSmelt() public {
        vm.prank(alice);
        usdt.approve(address(maseerOne), 1_000_000 * 1e6);
        vm.prank(alice);
        uint256 out = maseerOne.mint(100_000 * 1e6);
        assertEq(maseerOne.totalSupply(), out);

        vm.expectEmit();
        emit MaseerOne.Smelted(alice, 10 * WAD);
        vm.prank(alice);
        maseerOne.smelt(10 * WAD);

        assertEq(maseerOne.totalSupply(), out - 10 * WAD);
        assertEq(maseerOne.balanceOf(alice), out - 10 * WAD);
    }

    function testTreasurySmeltFromEnemy() public {

        // Give enemy some tokens
        _mintTokens(enemy, 1000 * 1e18);
        assertEq(maseerOne.balanceOf(enemy), 1000 * 1e18);
        assertEq(maseerOne.totalSupply(), 1000 * 1e18);

        // Ensure admin can burn directly from enemy account
        vm.prank(issuer);
        maseerOne.smelt(enemy, 100 * 1e18);

        assertEq(maseerOne.balanceOf(enemy), 900 * 1e18);

        vm.prank(issuer);
        maseerOne.smelt(enemy, 900 * 1e18);

        assertEq(maseerOne.balanceOf(enemy), 0);
        assertEq(maseerOne.totalSupply(), 0);
    }

    function testTreasurySmeltFromContract() public {

        // Give carol some tokens
        _mintTokens(carol, 1000 * 1e18);

        // WHOOPS! carol sent tokens to the oracle!
        vm.prank(carol);
        maseerOne.transfer(address(pip), 100 * 1e18);

        assertEq(maseerOne.balanceOf(carol), 900 * 1e18);
        assertEq(maseerOne.balanceOf(address(pip)), 100 * 1e18);

        vm.prank(issuer);
        maseerOne.smelt(address(pip), 100 * 1e18);

        assertEq(maseerOne.balanceOf(carol), 900 * 1e18);
        assertEq(maseerOne.balanceOf(address(pip)), 0);
        assertEq(maseerOne.totalSupply(), 900 * 1e18);
    }

    function test_failSmeltUnauthorizedUser() public {

        // Give bob some tokens
        _mintTokens(bob, 1000 * 1e18);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MaseerOne.UnauthorizedUser.selector, alice));
        maseerOne.smelt(bob, 100 * 1e18);
    }

}
