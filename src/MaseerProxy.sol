// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2025 Maseer LTD
//
// This file is subject to the Business Source License 1.1.
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at:
// https://github.com/Maseer-LTD/maseer-one/blob/master/LICENSE
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma solidity ^0.8.28;

contract MaseerProxy {

    bytes32 private constant _IMPL_WARD = keccak256("maseer.wards");
    bytes32 private constant _IMPL_SLOT = keccak256("maseer.proxy.implementation");
    bytes32 private constant _WARD_SLOT = keccak256("maseer.proxy.wards");

    function wardsProxy(address usr) external view returns (uint256) {
        return _getAuth(usr);
    }
    function relyProxy(address usr) external proxyAuth { _setAuth(usr, 1); emit RelyProxy(usr); }
    function denyProxy(address usr) external proxyAuth { _setAuth(usr, 0); emit DenyProxy(usr); }

    event RelyProxy(address indexed usr);
    event DenyProxy(address indexed usr);
    event Implementation(address indexed impl);

    error NotAuthorized();
    error NoImplementation();

    modifier proxyAuth() {
        if (_getAuth(msg.sender) != 1) revert NotAuthorized();
        _;
    }

    constructor(address _impl) {
        _setAuth(msg.sender, 1);
        _rely(msg.sender);
        _setImpl(_impl);
    }

    function file(address _impl) external proxyAuth {
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
        if (_impl == address(0)) revert NoImplementation();
        if (_impl.code.length == 0) revert NoImplementation();
        bytes32 _slot = _IMPL_SLOT;
        assembly {
            sstore(_slot, _impl)
        }
        emit Implementation(_impl);
    }

    function _getImpl() internal view returns (address) {
        bytes32 slot = _IMPL_SLOT;
        address _impl;
        assembly {
            _impl := sload(slot)
        }
        return _impl;
    }

    function _setAuth(address usr, uint256 val) internal {
        bytes32 _slot = keccak256(abi.encode(_WARD_SLOT, usr));
        assembly {
            sstore(_slot, val)
        }
    }

    function _getAuth(address usr) internal view returns (uint256) {
        bytes32 _slot = keccak256(abi.encode(_WARD_SLOT, usr));
        uint256 _val;
        assembly {
            _val := sload(_slot)
        }
        return _val;
    }

    function _rely(address usr) internal {
        bytes32 slot = keccak256(abi.encode(_IMPL_WARD, usr));
        assembly {
            sstore(slot, 1)
        }
    }
}
