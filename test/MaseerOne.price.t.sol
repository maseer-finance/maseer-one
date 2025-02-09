// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

import {MaseerImplementation} from "../src/MaseerImplementation.sol";
import {MaseerPrice} from "../src/MaseerPrice.sol";

contract MaseerOnePriceTest is MaseerTestBase {

    function setUp() public {

    }

    function testPause() public {
        assertTrue(pip.paused());

        vm.prank(pipAuth);
        pip.poke(1);

        // Not paused if price is anything other than 0
        assertTrue(!pip.paused());

        vm.prank(pipAuth);
        pip.pause();

        assertTrue(pip.paused());
        assertEq(pip.read(), 0);
    }

    function testPriceName() public {
        assertEq(pip.name(), "");

        vm.prank(pipAuth);
        pip.file("name", "CANAUSDT");

        assertEq(pip.name(), "CANAUSDT");

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, bob));
        pip.file("name", "URHACKED");

        assertEq(pip.name(), "CANAUSDT");
    }

    function testPriceRead() public {
        assertEq(pip.read(), 0);

        // Example where price is $30.24
        // 1 CANA = 30.24 USDT
        // 30.24 * 10^6 = 30_240000
        vm.prank(pipAuth);
        pip.poke(30240000);

        assertEq(pip.read(), 30240000);

        // bob is not authorized to update the price
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, bob));
        pip.poke(1337);
        assertEq(pip.read(), 30240000);

        // update price via file
        vm.prank(pipAuth);
        pip.file("price", bytes32(uint256(30240001)));

        assertEq(pip.read(), 30240001);
    }

    function testFuzzPriceUpdate(uint256 _price, uint256 _rand) public {

        // Fail 10% of the time
        bool _nope = (_rand % 10 == 0);
        if (_nope) {
            vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.NotAuthorized.selector, address(this)));
            pip.poke(_price);
            return;
        }

        vm.prank(pipAuth);
        pip.poke(_price);

        assertEq(pip.read(), _price);

        vm.prank(pipAuth);
        pip.poke(0);
        assertEq(pip.read(), 0);

        vm.prank(pipAuth);
        pip.file("price", bytes32(_price));

        assertEq(pip.read(), _price);
    }

    function testFuzzNameUpdate(bytes32 _name) public {

        vm.prank(pipAuth);
        pip.file("name", _name);

        assertEq(pip.name(), _bytes32toString(_name));
    }

    function testFuzzDecimalsUpdate(uint256 _decimals) public {

        _decimals = bound(_decimals, 0, 20);

        if (_decimals > 18) {
            vm.expectRevert(abi.encodeWithSelector(MaseerImplementation.UnrecognizedParam.selector, bytes32(_decimals)));
            vm.prank(pipAuth);
            pip.file("decimals", bytes32(_decimals));
            return;
        }

        vm.prank(pipAuth);
        pip.file("decimals", bytes32(_decimals));

        assertEq(pip.decimals(), _decimals);
    }
}
