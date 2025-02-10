// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaseerTestBase.t.sol";
import "./Mocks/MockImplementation.sol";

contract MaseerImplementationTest is MaseerTestBase {

    MockImplementation public mock;


    function setUp() public {

        mock = new MockImplementation();
    }

    function testSetBytes32Val() public {
        bytes32 val = keccak256("maseer.test.bytes32.val");
        mock.setBytes32Val(val);
        assertEq(mock.getBytes32Val(), val);
    }

    function testSetUint256Val() public {
        uint256 val = 1234;
        mock.setUint256Val(val);
        assertEq(mock.getUint256Val(), val);
    }

    function testSetAddressVal() public {
        address val = address(0x1234);
        mock.setAddressVal(val);
        assertEq(mock.getAddressVal(), val);
    }

    function testSetBoolVal() public {
        bool val = true;
        mock.setBoolVal(val);
        assertEq(mock.getBoolVal(), val);
    }

    function testSetStringVal() public {
        string memory val = "maseer.test.string.val";
        mock.setStringVal(val);
        assertEq(mock.getStringVal(), val);
    }
}
