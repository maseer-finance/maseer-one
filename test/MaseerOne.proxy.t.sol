// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneProxyTest is MaseerTestBase {

    function setUp() public {

        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
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
}
