// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneTokenTest is MaseerTestBase {

    function setUp() public {

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

    function testTransferToContractFail() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);

        vm.expectRevert(MaseerOne.TransferToContract.selector);
        vm.prank(alice);
        maseerOne.transfer(address(maseerOne), amt);
    }

    function testTransferFromToContractFail() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);

        vm.prank(alice);
        maseerOne.approve(alice, amt);

        vm.expectRevert(MaseerOne.TransferToContract.selector);
        vm.prank(alice);
        maseerOne.transferFrom(alice, address(maseerOne), amt);
    }

    function testTransferToZeroAddressFail() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);

        // address(0) fails on the guard check
        vm.expectRevert(
            abi.encodeWithSelector(MaseerOne.UnauthorizedUser.selector, address(0))
        );
        vm.prank(alice);
        maseerOne.transfer(address(0), amt);
    }

    function testTransferFromToZeroAddressFail() public {
        uint256 amt = 1000 * 1e18;

        _mintTokens(alice, amt);

        vm.prank(alice);
        maseerOne.approve(alice, amt);

        // address(0) fails on the guard check
        vm.expectRevert(
            abi.encodeWithSelector(MaseerOne.UnauthorizedUser.selector, address(0))
        );
        vm.prank(alice);
        maseerOne.transferFrom(alice, address(0), amt);
    }

    function testFuzzTransfer(address to, address from, uint256 amt) public {
        uint256 toBal = maseerOne.balanceOf(to);
        uint256 fromBal = maseerOne.balanceOf(from);

        _mintTokens(from, amt);
        assertEq(maseerOne.balanceOf(from), fromBal + amt);
        uint256 totalSupply = maseerOne.totalSupply();
        assertEq(maseerOne.totalSupply(), amt);

        // Don't send to unauthorized user
        if (!maseerOne.canPass(to) || !maseerOne.canPass(from)) {
            vm.expectPartialRevert(MaseerOne.UnauthorizedUser.selector);
            vm.prank(from);
            maseerOne.transfer(to, amt);
            return;
        }

        // Don't send to the contract
        if (to == address(maseerOne)) {
            vm.expectRevert(MaseerOne.TransferToContract.selector);
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

            if (!maseerOne.canPass(from)) vm.expectRevert(abi.encodeWithSelector(MaseerOne.UnauthorizedUser.selector, from));
            vm.prank(from);
            maseerOne.approve(from, amt);

            vm.expectPartialRevert(MaseerOne.UnauthorizedUser.selector);
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

    function testPermit() public {

        uint256 _amt = 1000 * 1e18;
        uint256 _pKey = 1337;
        address _leet = vm.addr(_pKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _pKey,
            keccak256(abi.encodePacked(
                    "\x19\x01",
                    maseerOne.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                            _leet,
                            bob,
                            _amt,
                            maseerOne.nonces(_leet),
                            block.timestamp
                        )
                    )
                )
            )
        );

        maseerOne.permit(_leet, bob, _amt, block.timestamp, v, r, s);

        assertEq(maseerOne.allowance(_leet, bob), _amt);
        assertEq(maseerOne.nonces(_leet), 1);
    }

    // TODO: General ERC20 tests
}
