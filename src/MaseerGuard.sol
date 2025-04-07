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

interface GuardSource {
    function getBlackListStatus(address usr) external view returns (bool);
}

contract MaseerGuard is MaseerImplementation {

    address public immutable source;

    // Allocating slots 0-49
    uint256[50] private __gap;

    constructor(address source_) {
        source = source_;
    }

    /**
     * @dev         Checks whether a given user address is not blacklisted.
     * @param  usr  The address of the user to check.
     * @return bool Returns `true` if the user can pass, otherwise `false`.
     */
    function pass(address usr) external view returns (bool) {
        return !GuardSource(source).getBlackListStatus(usr);
    }
}
