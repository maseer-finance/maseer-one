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

interface Gem {
    function transfer(address usr, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
    function decimals() external view returns (uint8);
    function approve(address usr, uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address src, address dst) external view returns (uint256);
}

interface One {
    function gem() external view returns (address);
    function flo() external view returns (address);
    function mint(uint256 wad) external returns (uint256);
    function mintcost() external view returns (uint256);
    function canPass(address usr) external view returns (bool);
}

contract MaseerPrecommit {

    address public   immutable gem;
    address public   immutable one;
    uint256 internal immutable MIN;

    uint256                   public deals;
    mapping (uint256 => Deal) public deal;

    struct Deal {
        address usr;
        uint256 amt;
    }

    error TransferFailed();
    error InsufficientAllowance();
    error InsufficientAmount();
    error NotAuthorized();

    modifier pass() {
        if (!One(one).canPass(msg.sender)) revert NotAuthorized();
        _;
    }

    constructor(address _one) {
        gem = One(_one).gem();
        MIN = 1000 * 10**uint256(Gem(gem).decimals());
        one = _one;
        Gem(gem).approve(_one, type(uint256).max);
    }

    function pact(uint256 _amt) external pass {
        if (_amt < MIN) revert InsufficientAmount();
        if (Gem(gem).allowance(msg.sender, address(this)) < _amt) revert InsufficientAllowance();

        deal[deals++] = Deal({
            usr: msg.sender,
            amt: _amt
        });
    }

    function exec(uint256 _idx) external pass {
        Deal memory c = deal[_idx];
        if (c.amt == 0) revert InsufficientAmount();
        deal[_idx].amt = 0;

        _safeTransferFrom(gem, c.usr, address(this), c.amt);
        uint256 out = One(one).mint(c.amt);
        _safeTransfer(one, c.usr, out);
    }

    function exit() external pass {
        _safeTransfer(gem, One(one).flo(), Gem(gem).balanceOf(address(this)));
    }

    function amt(uint256 _idx) external view returns (uint256) {
        return deal[_idx].amt;
    }

    function usr(uint256 _idx) external view returns (address) {
        return deal[_idx].usr;
    }

    function min() external view returns (uint256) {
        return MIN;
    }

    function _safeTransfer(address _token, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transfer.selector, _to, _amt));
        if (!success || (data.length > 0 && abi.decode(data, (bool)) == false)) revert TransferFailed();
    }

    function _safeTransferFrom(address _token, address _from, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transferFrom.selector, _from, _to, _amt));
        if (!success || (data.length > 0 && abi.decode(data, (bool)) == false)) revert TransferFailed();
    }
}
