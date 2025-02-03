// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";

contract MaseerOnePriceTest is MaseerTestBase {

    function setUp() public {

    }

    function testPriceName() public {
        assertEq(pip.name(), "");

        vm.prank(pipAuth);
        pip.file("name", "CANAUSDT");

        assertEq(pip.name(), "CANAUSDT");
    }

    function testPriceRead() public {
        assertEq(pip.read(), 0);

        // Example where price is $30.24
        // 1 CANA = 30.24 USDT
        // 30.24 * 10^6 = 30240000
        vm.prank(pipAuth);
        pip.poke(30240000);

        assertEq(pip.read(), 30240000);
    }

    function testFuzzPriceUpdate(uint256 _price, uint256 _rand) public {

        bool _ok = (_rand % 2 == 0);

        if (!_ok) {
            vm.expectRevert("MaseerPrice/not-authorized");
            pip.poke(_price);
            return;
        }

        vm.prank(pipAuth);
        pip.poke(_price);

        assertEq(pip.read(), _price);
    }

    function testFuzzNameUpdate(bytes32 _name) public {

        vm.prank(pipAuth);
        pip.file("name", _name);

        assertEq(pip.name(), _bytes32toString(_name));
    }
}
