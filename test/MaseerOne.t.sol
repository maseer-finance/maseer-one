// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MaseerOne} from "../src/MaseerOne.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

// TODO: Use real contracts once available
import {MockPip} from "./Mocks/MockPip.sol";
import {MockCop} from "./Mocks/MockCop.sol";

contract CounterTest is Test {

    string public NAME   = "MaseerOne";
    string public SYMBOL = "M1";

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public cop;
    address public pip;

    MaseerOne public maseerOne;

    function setUp() public {

        pip = address(new MockPip());
        cop = address(new MockCop());

        maseerOne = new MaseerOne(USDT, pip, cop, NAME, SYMBOL);
    }

    function testName() public view {
        assertEq(maseerOne.name(), NAME);
    }

    function testSymbol() public view {
        assertEq(maseerOne.symbol(), SYMBOL);
    }

    function testDecimals() public view {
        assertEq(maseerOne.decimals(), 18);
    }

    function testTotalSupply() public view {
        assertEq(maseerOne.totalSupply(), 0);
    }

    function testBalanceOf() public view {
        assertEq(maseerOne.balanceOf(address(this)), 0);
    }

    function testAllowance() public view {
        assertEq(maseerOne.allowance(address(this), address(this)), 0);
    }

    function testDomainSeparator() public view {
        assertEq(maseerOne.DOMAIN_SEPARATOR(), bytes32(0x773143d08813a4e7fa1a3c9395c3eddaeef465493893f95fd36a4b15bd080c6d));
    }

    function testNonces() public view {
        assertEq(maseerOne.nonces(address(this)), 0);
    }

    function testPip() public view {
        assertEq(maseerOne.pip(), pip);
    }

    function testCop() public view {
        assertEq(maseerOne.cop(), cop);
    }

    function testUSDTOnline() public view {
        assertEq(IERC20(maseerOne.gem()).name(), "Tether USD");
        assertEq(IERC20(maseerOne.gem()).symbol(), "USDT");
        assertEq(IERC20(maseerOne.gem()).decimals(), 6);
    }
}
