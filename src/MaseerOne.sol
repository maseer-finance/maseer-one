// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface Cop {
    function pass() external returns (bool);
}

interface Pip {
    function read() external returns (uint256);
}

import {MaseerToken} from "./MaseerToken.sol";

contract MaseerOne is MaseerToken {

    address immutable public gem;  // Purchase token
    address immutable public pip;  // Oracle price feed
    address immutable public cop;  // Compliance feed

    uint256                      public totalPending;
    mapping (address => uint256) public pendingClaim;
    mapping (address => uint256) public pendingTime;

    error Unavailable();

    constructor(
        address gem_,
        address pip_,
        address cop_,
        string memory name_,
        string memory symbol_
    ) MaseerToken(name_, symbol_) {
        gem = gem_;
        pip = pip_;
        cop = cop_;
    }

    modifier pass() {
        if (!Cop(cop).pass()) {
            revert Unavailable();
        }
        _;
    }

    function mint(uint256 amt_) external pass {
        // TODO: Oracle price check
        // pip.read

        // TODO: Minimum one unit to prevent dust?
        // require amt_ > pip.read

        // TODO: Calculate the mint amount
        // amt = amt_ / price

        // TODO: Transfer tokens in
        Gem(gem).transferFrom(msg.sender, address(this), amt_);

        // TODO: Mint the tokens
        // _mint(msg.sender, amt_);

        // TODO: Emit contract event
    }

    function redeem(uint256 amt_) external pass {
        // TODO: Check if the burn is allowed
        // modifier cop.pass

        // TODO: Oracle price check
        // pip.read

        // TODO: Add user to the pending redemptions
        // pendingClaim[msg.sender] += amt_
        // TODO: Consider whether to allow multiple redemption periods. Increases complexity and cost
        // pendingTime[msg.sender] = block.timestamp + 1 days

        // TODO: Transfer tokens in
        transferFrom(msg.sender, address(this), amt_);

        // TODO: Burn the tokens
        // _burn(msg.sender, amt_);

        // TODO: Emit contract event

    }

    function claim() external pass {
        // TODO: check if the claim is allowed
        // modifier cop.pass

        // TODO: Check if the claim is past the redemption period
        // require block.timestamp > pendingTime[msg.sender]

        // TODO: Check claimable amount
        uint256 amt = pendingClaim[msg.sender];

        // TODO: Check internal balance
        // require balanceOf(address.this) > amt --> revert "Insufficient Balance Available"

        // TODO: Decrement the pending redemptions
        // pendingClaim[msg.sender] -= amt;

        // TODO: Transfer the tokens
        Gem(gem).transferFrom(address(this), msg.sender, amt);

        // TODO: Emit claim

    }

    function settle() external {
        // TODO: Can probably be called by anyone?

        // TODO: get the gem balance and subtract the pending redemptions
        // uint256 amt = Gem(gem).balanceOf(address(this)) - totalPending;

        // TODO: send the remaining balance to the output conduit
        // IERC20(gem).transferFrom(address(this), outputConduit, amt);

        // TODO: Emit settle
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
}
