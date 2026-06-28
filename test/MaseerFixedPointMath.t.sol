// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerFixedPointMathTest is MaseerTestBase {
    function testWdivMatchesProductionFloorMath() public pure {
        // Old half-up helpers rounded this quotient up by 1.
        assertEq(_wdiv(2, 3), 666666666666666666);
    }

    function testWmulMatchesProductionFloorMath() public pure {
        // Old half-up helpers rounded this sub-wad product up to 1.
        assertEq(_wmul(1, WAD / 2), 0);
    }
}
