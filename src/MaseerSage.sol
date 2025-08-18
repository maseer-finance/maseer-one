// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2025 Maseer LTD
//
// This file is subject to the Business Source License 1.1.
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at:
// https://github.com/maseer-finance/maseer-one/blob/master/LICENSE
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma solidity ^0.8.28;

interface One {
    function capacity() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mintable() external view returns (bool);
    function mintcost() external view returns (uint256);
    function burnable() external view returns (bool);
    function burncost() external view returns (uint256);
    function navprice() external view returns (uint256);
}

contract MaseerSage {

    uint256 public constant  WAD = 1e18;
    address public immutable ONE;

    constructor(address _one) {
        ONE = _one;
    }

    function gap() public view returns (uint256) {
        return One(ONE).capacity() - One(ONE).totalSupply();
    }

    function usdtGap() public view returns (uint256) {
        uint256 mintPrice = One(ONE).mintcost();
        return _wmul(gap(), mintPrice);
    }

    function peekMint(uint256 _amt) public view returns (uint256) {
        if (
            !One(ONE).mintable()     ||  // Minting is not open
            One(ONE).navprice() == 0     // Price is zero
        ) return 0;

        uint256 unit = One(ONE).mintcost();
        if (
            _amt < unit               || // Dust threshold
           _amt > _wmul(gap(), unit)    // USDT gap
        ) return 0;
        
        return _wdiv(_amt, unit);
    }

    function peekRedeem(uint256 _amt) public view returns (uint256) {
        if (
            !One(ONE).burnable() ||  // Burning is not open
            _amt < WAD               // Dust threshold
        ) return 0;

        uint256 unit = One(ONE).burncost();

        return _wmul(_amt, unit);
    }

    function _wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD) / y;
    }

    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }

}
