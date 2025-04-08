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

contract MaseerPrice is MaseerImplementation{

    bytes32 internal constant _NAME_SLOT     = keccak256("maseer.price.name");
    bytes32 internal constant _PRICE_SLOT    = keccak256("maseer.price.price");
    bytes32 internal constant _DECIMALS_SLOT = keccak256("maseer.price.decimals");

    // Slot 0
    bytes32 private _emptySlot;
    // Slot 1
    mapping (address => uint256) public bud;
    // Allocate slots 2-49
    uint256[48] private __gap;

    event File(bytes32 indexed what, bytes32 data);
    event Poke(uint256 indexed price, uint256 indexed timestamp);

    function kiss(address usr) external auth { bud[usr] = 1; }
    function diss(address usr) external auth { bud[usr] = 0; }
    modifier buds() {
        if (bud[msg.sender] != 1) revert NotAuthorized(msg.sender);
        _;
    }

    constructor() {
        _rely(msg.sender);
    }

    function read() external view returns (uint256) {
        return _uint256Slot(_PRICE_SLOT);
    }

    function poke(uint256 read_) public buds {
        _poke(read_);
    }

    function pause() external auth {
        _poke(0);
    }

    function name() external view returns (string memory) {
        return _stringSlot(_NAME_SLOT);
    }

    function decimals() external view returns (uint8 decimals_) {
        return uint8(_uint256Slot(_DECIMALS_SLOT));
    }

    function paused() external view returns (bool) {
        return (_uint256Slot(_PRICE_SLOT) == 0) ? true : false;
    }

    function file(bytes32 what, bytes32 data) external auth {
        if      (what == "price")    _poke(uint256(data));
        else if (what == "name")     _setVal(_NAME_SLOT, data);
        else if (what == "decimals" && uint256(data) <= 18) _setVal(_DECIMALS_SLOT, data);
        else    revert UnrecognizedParam(data);
        emit    File(what, data);
    }

    function _poke(uint256 read_) internal {
        _setVal(_PRICE_SLOT, bytes32(read_));
        emit Poke(read_, block.timestamp);
    }

}
