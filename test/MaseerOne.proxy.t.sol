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

    function testPipUpgrade() public {
        address newPipImpl = address(new MockPip());
        vm.prank(proxyAuth);
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
        vm.prank(proxyAuth);
        MaseerProxy(actProxy).file(newActImpl);
        assertEq(maseerOne.act(), actProxy);
        assertEq(MaseerProxy(maseerOne.act()).impl(), newActImpl);

        // Ensure that the new implementation wards are preserved
        vm.prank(actAuth);
        act.setOpenMint(block.timestamp - 2 days);
        assertEq(act.openMint(), block.timestamp - 2 days);
    }

    function testCop() public view {
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), copImpl);
    }

    function testCopUpgrade() public {
        address newCopImpl = address(new MockCop());
        vm.prank(proxyAuth);
        MaseerProxy(copProxy).file(newCopImpl);
        assertEq(maseerOne.cop(), copProxy);
        assertEq(MaseerProxy(maseerOne.cop()).impl(), newCopImpl);

        // Ensure that the new implementation wards are preserved
        vm.prank(copAuth);
        cop.rely(bob);
        assertEq(cop.wards(bob), 1);

        // Ensure new functions on the implementation work
        assertEq(cop.pass(carol), true);
        vm.prank(bob);
        MockCop(copProxy).blacklist(carol, true);
        assertEq(cop.pass(carol), false);
    }

    function testFlo() public view {
        assertEq(maseerOne.flo(), floProxy);
        assertEq(MaseerProxy(maseerOne.flo()).impl(), floImpl);
    }

    function testFloUpgrade() public {
        address newFloImpl = address(new MaseerConduit());
        vm.prank(proxyAuth);
        MaseerProxy(floProxy).file(newFloImpl);
        assertEq(maseerOne.flo(), floProxy);
        assertEq(MaseerProxy(maseerOne.flo()).impl(), newFloImpl);
    }

    function testAdm() public view {
        assertEq(maseerOne.adm(), admProxy);
        assertEq(MaseerProxy(maseerOne.adm()).impl(), admImpl);
    }

    function testAdmUpgrade() public {
        address newAdmImpl = address(new MaseerTreasury());
        vm.prank(proxyAuth);
        MaseerProxy(admProxy).file(newAdmImpl);
        assertEq(maseerOne.adm(), admProxy);
        assertEq(MaseerProxy(maseerOne.adm()).impl(), newAdmImpl);
    }
}
