// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {MaseerGuardOZ} from "../src/MaseerGuardOZ.sol";
import {MockGuardSourceOZ} from "./Mocks/MockGuardSourceOZ.sol";

contract MaseerGuardOZTest is Test {

    MaseerGuardOZ public guard;
    MockGuardSourceOZ public source;

    address public alice;
    address public banned;

    function setUp() public {
        source = new MockGuardSourceOZ();
        guard  = new MaseerGuardOZ(address(source));

        alice  = makeAddr("alice");
        banned = makeAddr("banned");

        source.ban(banned);
    }

    function testGoodActor() public view {
        assertEq(guard.pass(alice), true);
    }

    function testBadActor() public view {
        assertEq(guard.pass(banned), false);
    }

    function testBanAndUnban() public {
        address user = makeAddr("user");
        assertEq(guard.pass(user), true);

        source.ban(user);
        assertEq(guard.pass(user), false);

        source.unban(user);
        assertEq(guard.pass(user), true);
    }

    function testFuzzPass(address user) public view {
        // No one is banned except `banned`
        if (user == banned) {
            assertEq(guard.pass(user), false);
        } else {
            assertEq(guard.pass(user), true);
        }
    }

    function testSourceAddress() public view {
        assertEq(guard.source(), address(source));
    }
}
