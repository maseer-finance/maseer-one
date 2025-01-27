// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MaseerOne} from "../src/MaseerOne.sol";

contract CounterTest is Test {
    MaseerOne public maseerOne;

    function setUp() public {
        maseerOne = new MaseerOne();
        maseerOne.setNumber(0);
    }

    function test_Increment() public {
        maseerOne.increment();
        assertEq(maseerOne.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        maseerOne.setNumber(x);
        assertEq(maseerOne.number(), x);
    }
}
