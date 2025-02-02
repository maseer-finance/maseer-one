// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneProxyTest is MaseerTestBase {

    function setUp() public {

    }

    function testPip() public view {
        assertEq(maseerOne.pip(), pipProxy);
        assertEq(MaseerProxy(maseerOne.pip()).impl(), pipImpl);
    }

    function testUpgradePip() public {
        address newPipImpl = address(new MaseerPrice());
        MaseerProxy(pipProxy).file(newPipImpl);
        assertEq(maseerOne.pip(), pipProxy);
        assertEq(MaseerProxy(maseerOne.pip()).impl(), newPipImpl);
    }

    function testAct() public view {
        assertEq(maseerOne.act(), actProxy);
        assertEq(MaseerProxy(maseerOne.act()).impl(), actImpl);
    }

    function testActUpgrade() public {
        address newActImpl = address(new MaseerGate());
        MaseerProxy(actProxy).file(newActImpl);
        assertEq(maseerOne.act(), actProxy);
        assertEq(MaseerProxy(maseerOne.act()).impl(), newActImpl);
    }

    function testCop() public view {
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), copImpl);
    }

    function testCopUpgrade() public {
        address newCopImpl = address(new MaseerGuard(USDT));
        MaseerProxy(copProxy).file(newCopImpl);
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), newCopImpl);
    }

    function testFlo() public view {
        assertEq(maseerOne.flo(), floProxy);
        assertEq(MaseerProxy(maseerOne.flo()).impl(), floImpl);
    }

    function testFloUpgrade() public {
        address newFloImpl = address(new MaseerConduit());
        MaseerProxy(floProxy).file(newFloImpl);
        assertEq(maseerOne.flo(), floProxy);
        assertEq(MaseerProxy(maseerOne.flo()).impl(), newFloImpl);
    }

    // TODO: Test proxy interactions
    // TODO: Test proxy upgrade
}
