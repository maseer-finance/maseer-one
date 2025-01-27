// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MaseerOne} from "../src/MaseerOne.sol";

contract CounterTest is Test {
    MaseerOne public maseerOne;

    function setUp() public {
        maseerOne = new MaseerOne("MaseerOne", "M1");
    }

    function testName() public {
        assertEq(maseerOne.name(), "MaseerOne");
    }

    function testSymbol() public {
        assertEq(maseerOne.symbol(), "M1");
    }

    function testDecimals() public {
        assertEq(maseerOne.decimals(), 18);
    }

    function testTotalSupply() public {
        assertEq(maseerOne.totalSupply(), 0);
    }

    function testBalanceOf() public {
        assertEq(maseerOne.balanceOf(address(this)), 0);
    }

    function testAllowance() public {
        assertEq(maseerOne.allowance(address(this), address(this)), 0);
    }

    function testDomainSeparator() public {
        assertEq(maseerOne.DOMAIN_SEPARATOR(), bytes32(0x5ab14e15c20450fbc9d7535f051e9e913e03b79d61309455cc299c496fecb73b));
    }

    function testNonces() public {
        assertEq(maseerOne.nonces(address(this)), 0);
    }
}
