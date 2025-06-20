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

import {MaseerImplementation} from "./MaseerImplementation.sol";

contract MaseerTreasury is MaseerImplementation {

    // Allocating slots 0-49
    uint256[50] private __gap;

    bytes32 internal constant _ISSUER_SLOT   = keccak256("maseer.treasury.issuer");

    event Bestow(address indexed usr);
    event Depose(address indexed usr);

    function bestow(address usr) external auth {
        _setIssuer(usr, 1);
        emit Bestow(usr);
    }

    function depose(address usr) external auth {
        _setIssuer(usr, 0);
        emit Depose(usr);
    }

    function issuer(address usr) external view returns (bool) {
        return _getIssuer(usr) == 1;
    }

    function _setIssuer(address usr, uint256 val) internal {
        bytes32 slot = keccak256(abi.encode(_ISSUER_SLOT, usr));
        _setVal(slot, val);
    }

    function _getIssuer(address usr) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(_ISSUER_SLOT, usr));
        return _uint256Slot(slot);
    }
}
