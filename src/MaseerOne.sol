// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface Cop {
    function pass() external returns (bool);
}

interface Pip {
    function read() external returns (uint256);
}

interface Act {
    function live() external returns (bool);
}

import {MaseerToken} from "./MaseerToken.sol";

contract MaseerOne is MaseerToken {

    address immutable public gem;  // Purchase token
    address immutable public pip;  // Oracle price feed
    address immutable public act;  // Market timing feed
    address immutable public cop;  // Compliance feed

    uint256                      public totalPending;
    mapping (address => uint256) public pendingClaim;
    mapping (address => uint256) public pendingTime;

    event ContractCreated(
        address indexed creator,
        uint256 indexed price,
        uint256 indexed amount
    );
    event ContractRedeemed(
        address indexed redeemer,
        uint256 indexed price,
        uint256 indexed amount
    );
    event ClaimProcessed(
        address indexed claimer,
        uint256 indexed amount
    );
    event Settled(
        uint256 indexed amount
    );

    error UnauthorizedUser();
    error MarketClosed();
    error ClaimableAfter(uint256 time);
    error NoPendingClaim();
    error DustThreshold(uint256 min);

    constructor(
        address gem_,
        address pip_,
        address act_,
        address cop_,
        string memory name_,
        string memory symbol_
    ) MaseerToken(name_, symbol_) {
        gem = gem_;
        pip = pip_;
        act = act_;
        cop = cop_;
    }

    modifier pass() {
        if (!Cop(cop).pass()) { revert UnauthorizedUser(); }
        _;
    }

    modifier live() {
        if (!Act(act).live()) { revert MarketClosed(); }
        _;
    }

    function mint(uint256 amt_) external live {
        // Oracle price check
        uint256 _price = Pip(pip).read();

        // Assert minimum purchase amount of one unit to avoid dust
        if (amt_ < _price) {
            revert DustThreshold(_price);
        }

        // Calculate the mint amount
        // TODO: divdown
        uint256 _out = amt_ / _price;

        // Transfer tokens in
        Gem(gem).transferFrom(msg.sender, address(this), amt_);

        // Mint the tokens
        _mint(msg.sender, _out);

        // Emit contract event
        emit ContractCreated(msg.sender, _price, _out);
    }

    function redeem(uint256 amt_) external live pass {

        // Oracle price check
        uint256 _price = Pip(pip).read();

        // Calculate the redemption amount
        // TODO: round down
        uint256 _out = amt_ * _price;

        // Add to the total pending redemptions
        totalPending += _out;

        // Add to the user's pending redemptions
        pendingClaim[msg.sender] += _out;

        // Bump the redemption time
        // TODO: Consider whether to allow multiple redemption periods. Increases complexity and cost
        // TODO: Consider whether redemption delay needs to be configurable. Increases complexity and cost
        pendingTime[msg.sender] = block.timestamp + 5 days;

        // Burn the tokens
        _burn(msg.sender, amt_);

        // Emit contract event
        emit ContractRedeemed(msg.sender, _price, _out);
    }

    function claim() external pass {

        uint256 _time = pendingTime[msg.sender];

        // Check if the claim is past the redemption period
        if (_time > block.timestamp) {
            revert ClaimableAfter(pendingTime[msg.sender]);
        }
        if (_time == 0) {
            revert NoPendingClaim();
        }

        // Check claimable amounts
        uint256 _amt = pendingClaim[msg.sender];
        uint256 _bal = Gem(gem).balanceOf(address(this));

        // Check internal balance
        uint256 _out = _min(_amt, _bal);

        // Decrement the user's pending redemptions
        pendingClaim[msg.sender] -= _out;

        // Transfer the tokens
        Gem(gem).transferFrom(address(this), msg.sender, _out);

        // Emit claim
        emit ClaimProcessed(msg.sender, _out);
    }

    function settle() external returns (uint256 amt) {
        // TODO: Can probably be called by anyone?

        // Get the gem balance and subtract the pending redemptions
        uint256 _bal = Gem(gem).balanceOf(address(this));

        // Return 0 if the balance is reserved for pending claims
        if (_bal < totalPending) { return 0; }

        // Calculate the balance after pending redemptions
        uint256 _out = _bal - totalPending;

        // Send the remaining balance to the output conduit
        // TODO: Create output conduit
        Gem(gem).transferFrom(address(this), address(1337), _out);

        // Emit settle
        emit Settled(_out);
    }


    // Token overrides for compliance

    function approve(address guy) external override pass returns (bool) {
        return super.approve(guy, type(uint256).max);
    }

    function approve(address guy, uint wad) public override pass returns (bool) {
        return super.approve(guy, wad);
    }

    function transfer(address dst, uint wad) external override pass returns (bool) {
        return super.transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public override pass returns (bool) {
        return super.transferFrom(src, dst, wad);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override pass {
        // TODO: Check if the transfer is allowed
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    // Internal utility functions

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }
}
