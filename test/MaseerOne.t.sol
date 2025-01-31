// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

//import {console} from "forge-std/Test.sol";
import "./MaseerTestBase.t.sol";

contract MaseerOneTest is MaseerTestBase {

    function setUp() public {
        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
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
        assertEq(maseerOne.DOMAIN_SEPARATOR(),
                 _calculateDomainSeparator(NAME, block.chainid, address(maseerOne)));
    }

    function testNonces() public view {
        assertEq(maseerOne.nonces(address(this)), 0);
    }

    function testPip() public view {
        assertEq(maseerOne.pip(), pipProxy);
        assertEq(MaseerProxy(maseerOne.pip()).impl(), pipImpl);
    }

    function testAct() public view {
        assertEq(maseerOne.act(), actProxy);
        assertEq(MaseerProxy(maseerOne.act()).impl(), actImpl);
    }

    function testCop() public view {
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), copImpl);
    }

    function testFlo() public view {
        assertEq(maseerOne.flo(), floProxy);
        assertEq(MaseerProxy(maseerOne.flo()).impl(), floImpl);
    }

    function testUSDTOnline() public view {
        assertEq(IERC20(maseerOne.gem()).name(), "Tether USD");
        assertEq(IERC20(maseerOne.gem()).symbol(), "USDT");
        assertEq(IERC20(maseerOne.gem()).decimals(), 6);
    }

}
