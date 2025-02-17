// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOneProxyTest is MaseerTestBase {

    function setUp() public {

    }

    function testProxyAuth() public {
        MaseerGate _testGate = new MaseerGate();
        MaseerProxy _testProxy = new MaseerProxy(address(_testGate));

        assertEq(_testProxy.impl(), address(_testGate));
        assertEq(_testProxy.wardsProxy(address(this)), 1);
        assertEq(_testProxy.wardsProxy(address(_testGate)), 0);
        assertEq(_testProxy.wardsProxy(address(_testProxy)), 0);
        assertEq(_testProxy.wardsProxy(address(maseerOne)), 0);
        assertEq(_testProxy.wardsProxy(address(0)), 0);
        assertEq(_testProxy.wardsProxy(alice), 0);
    }

    function testProxyRely() public {
        MaseerGate _testGate = new MaseerGate();
        MaseerProxy _testProxy = new MaseerProxy(address(_testGate));

        assertEq(_testProxy.impl(), address(_testGate));
        assertEq(_testProxy.wardsProxy(address(this)), 1);

        // Deployer can rely new auth
        _testProxy.relyProxy(carol);

        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 1);

        // Auth can rely others
        vm.prank(carol);
        _testProxy.relyProxy(bob);

        assertEq(_testProxy.wardsProxy(bob), 1);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 1);

        // alice is not authorized to rely
        vm.expectRevert(MaseerProxy.NotAuthorized.selector);
        vm.prank(alice);
        _testProxy.relyProxy(alice);
    }

    function testProxyDeny() public {
        MaseerGate _testGate = new MaseerGate();
        MaseerProxy _testProxy = new MaseerProxy(address(_testGate));

        _testProxy.relyProxy(alice);
        _testProxy.relyProxy(bob);
        _testProxy.relyProxy(carol);
        assertEq(_testProxy.wardsProxy(alice), 1);
        assertEq(_testProxy.wardsProxy(bob), 1);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 1);

        // Auth can deny deployer
        vm.prank(alice);
        _testProxy.denyProxy(address(this));

        assertEq(_testProxy.wardsProxy(alice), 1);
        assertEq(_testProxy.wardsProxy(bob), 1);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 0);

        // Auth can deny themselves
        vm.prank(bob);
        _testProxy.denyProxy(bob);

        assertEq(_testProxy.wardsProxy(alice), 1);
        assertEq(_testProxy.wardsProxy(bob), 0);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 0);

        // Auth can deny others
        vm.prank(carol);
        _testProxy.denyProxy(alice);

        assertEq(_testProxy.wardsProxy(alice), 0);
        assertEq(_testProxy.wardsProxy(bob), 0);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 0);

        // alice is no longer authorized to deny
        vm.expectRevert(MaseerProxy.NotAuthorized.selector);
        vm.prank(alice);
        _testProxy.denyProxy(carol);

        assertEq(_testProxy.wardsProxy(alice), 0);
        assertEq(_testProxy.wardsProxy(bob), 0);
        assertEq(_testProxy.wardsProxy(carol), 1);
        assertEq(_testProxy.wardsProxy(address(this)), 0);
    }

    function testProxyImplementation() public {
        MaseerGate _testGate = new MaseerGate();
        MaseerProxy _testProxy = new MaseerProxy(address(_testGate));

        assertEq(_testProxy.impl(), address(_testGate));

        MaseerGate(address(_testProxy)).setOpenMint(block.timestamp);

        assertEq(MaseerGate(address(_testProxy)).openMint(), block.timestamp);

        MaseerGate(address(_testProxy)).setHaltMint(block.timestamp + 1 days);

        assertEq(MaseerGate(address(_testProxy)).haltMint(), block.timestamp + 1 days);
        assertEq(MaseerGate(address(_testProxy)).mintable(), true);

        MaseerGate(address(_testProxy)).setBpsin(10000);

        assertEq(MaseerGate(address(_testProxy)).bpsin(), 10000);

        MaseerGate(address(_testProxy)).setBpsout(10000);

        assertEq(MaseerGate(address(_testProxy)).bpsout(), 10000);

        MaseerGate(address(_testProxy)).setCooldown(1 days);

        assertEq(MaseerGate(address(_testProxy)).cooldown(), 1 days);

        MaseerGate(address(_testProxy)).pauseMarket();

        assertEq(MaseerGate(address(_testProxy)).openMint(), 0);
        assertEq(MaseerGate(address(_testProxy)).haltMint(), 0);

        assertEq(MaseerGate(address(_testProxy)).mintable(), false);

        MaseerGate(address(_testProxy)).rely(alice);
        assertEq(MaseerGate(address(_testProxy)).wards(alice), 1);

        MaseerGate(address(_testProxy)).deny(address(this));
        assertEq(MaseerGate(address(_testProxy)).wards(address(this)), 0);

        vm.prank(alice);
        MaseerGate(address(_testProxy)).rely(bob);

        assertEq(MaseerGate(address(_testProxy)).wards(bob), 1);

    }
}
