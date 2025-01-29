// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerProxy {

    bytes32 private constant _IMPLEMENTATION_SLOT = keccak256("maseer.proxy.implementation");
    bytes32 private constant _WARDS_SLOT = keccak256("maseer.proxy.wards");

    function wards(address usr) external view returns (uint256) {
        return _getAuth(usr);
    }
    function rely(address usr) external auth { _setAuth(usr, 1); }
    function deny(address usr) external auth { _setAuth(usr, 0); }

    modifier auth() {
        require(_getAuth(msg.sender) == 1, "MaseerProxy/not-authorized");
        _;
    }

    constructor(address _impl) {
        _setImpl(_impl);
        _setAuth(msg.sender, 1);
    }

    function file(address _impl) external auth {
        _setImpl(_impl);
    }

    function impl() external view returns (address) {
        return _getImpl();
    }

    fallback() external {
        address _impl = _getImpl();

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            returndatacopy(ptr, 0, returndatasize())

            switch result
            case 0 { revert(ptr, returndatasize()) }
            default { return(ptr, returndatasize()) }
        }
    }

    function _setImpl(address _impl) internal {
        require(_impl != address(0), "MaseerProxy/no-implementation");
        bytes32 _slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(_slot, _impl)
        }
    }

    function _getImpl() internal view returns (address) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        address _impl;
        assembly {
            _impl := sload(slot)
        }
        return _impl;
    }

    function _setAuth(address usr, uint256 val) internal {
        bytes32 _slot = keccak256(abi.encodePacked(_WARDS_SLOT, usr));
        assembly {
            sstore(_slot, val)
        }
    }

    function _getAuth(address usr) internal view returns (uint256) {
        bytes32 _slot = keccak256(abi.encodePacked(_WARDS_SLOT, usr));
        uint256 _val;
        assembly {
            _val := sload(_slot)
        }
        return _val;
    }
}
