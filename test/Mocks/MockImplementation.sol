// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../src/MaseerImplementation.sol";

contract MockImplementation is MaseerImplementation {

    bytes32 public uint256Slot = keccak256("maseer.test.uint256.slot");
    bytes32 public addressSlot = keccak256("maseer.test.address.slot");
    bytes32 public boolSlot    = keccak256("maseer.test.bool.slot");
    bytes32 public bytes32Slot = keccak256("maseer.test.bytes32.slot");
    bytes32 public stringSlot  = keccak256("maseer.test.string.slot");

    function setUint256Val(uint256 val) external {
        _setVal(uint256Slot, val);
    }

    function getUint256Val() external view returns (uint256) {
        return _uint256Slot(uint256Slot);
    }

    function setAddressVal(address val) external {
        _setVal(addressSlot, val);
    }

    function getAddressVal() external view returns (address) {
        return _addressSlot(addressSlot);
    }

    function setBoolVal(bool val) external {
        _setVal(boolSlot, val);
    }

    function getBoolVal() external view returns (bool) {
        return _boolSlot(boolSlot);
    }

    function setBytes32Val(bytes32 val) external {
        _setVal(bytes32Slot, val);
    }

    function getBytes32Val() external view returns (bytes32) {
        return _getVal(bytes32Slot);
    }

    function setStringVal(string memory val) external {
        _setVal(stringSlot, val);
    }

    function getStringVal() external view returns (string memory) {
        return _stringSlot(stringSlot);
    }
}
