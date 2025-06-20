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

interface Gem {
    function transfer(address dst, uint256 wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MaseerConduit is MaseerImplementation {

    // Slot 0
    bytes32 private _emptySlot;
    // Slot 1
    mapping (address => uint256) public can;
    // Slot 2
    mapping (address => uint256) public bud;
    // Allocate Slots 3-49
    uint256[48] private __gap;

    error ZeroAddress();
    error TransferFailed();

    function hope(address usr) external auth { can[usr] = 1; }
    function nope(address usr) external auth { can[usr] = 0; }
    modifier operator() {
        if (can[msg.sender] != 1) revert NotAuthorized(msg.sender);
        _;
    }
    function kiss(address usr) external auth { bud[usr] = 1; }
    function diss(address usr) external auth { bud[usr] = 0; }
    modifier buds(address usr) {
        if (bud[usr] != 1) revert NotAuthorized(usr);
        _;
    }

    event Hope(address indexed usr);
    event Nope(address indexed usr);
    event Kiss(address indexed usr);
    event Diss(address indexed usr);
    event Move(
        address indexed token,
        address indexed to,
        uint256 indexed amount
    );

    constructor() {
        _rely(msg.sender);
    }

    function move(address _token, address _to) external operator buds(_to) returns (uint256 _amt) {
        if (_token == address(0)) revert ZeroAddress();
        _amt = Gem(_token).balanceOf(address(this));
        _move(_token, _to, _amt);
    }

    function move(address _token, address _to, uint256 _amt) external operator buds(_to) returns (uint256) {
        if (_token == address(0)) revert ZeroAddress();
        _move(_token, _to, _amt);
        return _amt;
    }

    function _move(address _token, address _to, uint256 _amt) internal {
        _safeTransfer(_token, _to, _amt);
        emit Move(_token, _to, _amt);
    }

    function _safeTransfer(address _token, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transfer.selector, _to, _amt));
        if (!success || (data.length > 0 && abi.decode(data, (bool)) == false)) revert TransferFailed();
    }
}
