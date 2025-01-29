// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

//import {console} from "forge-std/Test.sol";
import "./MaseerTestBase.t.sol";

contract MaseerOneTest is MaseerTestBase {

    function setUp() public {

        pip = address(new MaseerPrice());
        pipProxy = address(new MaseerProxy(pip));
        act = address(new MaseerGate());
        actProxy = address(new MaseerProxy(act));
        cop = address(new MaseerGuard(USDT));
        copProxy = address(new MaseerProxy(cop));

        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, NAME, SYMBOL);
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
        assertEq(MaseerProxy(maseerOne.pip()).impl(), pip);
    }

    function testAct() public view {
        assertEq(maseerOne.act(), actProxy);
        assertEq(MaseerProxy(maseerOne.act()).impl(), act);
    }

    function testCop() public view {
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), cop);
    }

    function testUSDTOnline() public view {
        assertEq(IERC20(maseerOne.gem()).name(), "Tether USD");
        assertEq(IERC20(maseerOne.gem()).symbol(), "USDT");
        assertEq(IERC20(maseerOne.gem()).decimals(), 6);
    }

}
