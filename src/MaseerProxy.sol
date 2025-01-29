// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MaseerProxy {
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerProxy/not-authorized");
        _;
    }

    address public impl;

    constructor(address _impl) {
        require(_impl != address(0), "MaseerProxy/no-implementation");
        impl = _impl;
        wards[msg.sender] = 1;
    }

    function upgrade(address _impl) external auth {
        require(_impl != address(0), "MaseerProxy/no-implementation");
        impl = _impl;
    }

    fallback() external {
        address _impl = impl;

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
}
