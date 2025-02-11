// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract MockUSDT {

    uint256                                           public totalSupply;
    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    string                                            public name;
    string                                            public symbol;
    uint8                                    constant public decimals = 6;

    uint256                                  constant internal WAD = 1e18;

    address public owner;
    mapping (address => bool) public blacklist;

    constructor() {
        name   = "Tether USD";
        symbol = "USDT";
        owner  = msg.sender;
    }

    function getBlackListStatus(address usr) external view returns (bool) {
        return blacklist[usr];
    }

    function setBlackListStatus(address usr, bool status) external {
        blacklist[usr] = status;
    }

    function mint(address usr, uint256 wad) public {
        require(msg.sender == owner, "MockUSDT: only owner can mint");
        _mint(usr, wad);
    }

    function approve(address usr) public virtual returns (bool) {
        return approve(usr, type(uint256).max);
    }

    function approve(address usr, uint256 wad) public returns (bool) {
        allowance[msg.sender][usr] = wad;
        return true;
    }

    function transfer(address dst, uint256 wad) public {
        balanceOf[msg.sender] -= wad;
        unchecked {
            balanceOf[dst] += wad;
        }
        // No return from USDT
    }

    function transferFrom(address src, address dst, uint256 wad) public
    {
        uint256 _allowance = allowance[src][msg.sender];
        if (_allowance != type(uint256).max) {
            allowance[src][msg.sender] = _allowance - wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        // No return from USDT
    }

    function _mint(address usr, uint256 wad) internal {
        totalSupply += wad;
        // Cannot overflow
        unchecked {
            balanceOf[usr] += wad;
        }
    }
}
