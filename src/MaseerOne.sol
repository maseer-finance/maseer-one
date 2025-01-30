// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface Cop {
    function pass(address usr) external view returns (bool);
}

interface Pip {
    function read() external view returns (uint256);
}

interface Act {
    function open()  external view returns (uint256);
    function halt()  external view returns (uint256);
    function live()  external view returns (bool);
    function delay() external view returns (uint256);
}

import {MaseerToken} from "./MaseerToken.sol";

contract MaseerOne is MaseerToken {

    address immutable public gem;  // Purchase token
    address immutable public pip;  // Oracle price feed
    address immutable public act;  // Market timing feed
    address immutable public cop;  // Compliance feed
    address immutable public flo;  // Output conduit

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
        address indexed conduit,
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
        address flo_,
        string memory name_,
        string memory symbol_
    ) MaseerToken(name_, symbol_) {
        gem = gem_;
        pip = pip_;
        act = act_;
        cop = cop_;
        flo = flo_;
    }

    modifier pass() {
        if (!Cop(cop).pass(msg.sender)) { revert UnauthorizedUser(); }
        _;
    }

    modifier live() {
        if (!Act(act).live()) { revert MarketClosed(); }
        _;
    }

    function mint(uint256 amt_) external live returns (uint256 _out) {
        // Oracle price check
        uint256 _price = Pip(pip).read();

        // Assert minimum purchase amount of one unit to avoid dust
        if (amt_ < _price) {
            revert DustThreshold(_price);
        }

        // Calculate the mint amount
        // TODO: divdown
        _out = amt_ / _price;

        // Transfer tokens in
        _safeTransferFrom(gem, msg.sender, address(this), amt_);

        // Mint the tokens
        _mint(msg.sender, _out);

        // Emit contract event
        emit ContractCreated(msg.sender, _price, _out);
    }

    function redeem(uint256 amt_) external live pass returns (uint256 _claim) {

        // Oracle price check
        uint256 _price = Pip(pip).read();

        // Calculate the redemption amount
        // TODO: round down
        _claim = amt_ * _price;

        // Add to the total pending redemptions
        totalPending += _claim;

        // Add to the user's pending redemptions
        pendingClaim[msg.sender] += _claim;

        // Bump the redemption time
        // TODO: Consider whether to allow multiple redemption periods. Increases complexity and cost
        pendingTime[msg.sender] = block.timestamp + Act(act).delay();

        // Burn the tokens
        _burn(msg.sender, amt_);

        // Emit contract event
        emit ContractRedeemed(msg.sender, _price, _claim);
    }

    function claim() external pass returns (uint256 _out) {

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

        // Check internal balance
        uint256 _bal = Gem(gem).balanceOf(address(this));

        // User can claim the amount owed or current available balance
        _out = _min(_amt, _bal);

        // Decrement the user's pending redemptions
        pendingClaim[msg.sender] -= _out;

        // Emit claim
        emit ClaimProcessed(msg.sender, _out);

        // Transfer the tokens
        _safeTransferFrom(gem, address(this), msg.sender, _out);
    }

    function settle() external returns (uint256 amt) {

        // Get the gem balance and subtract the pending redemptions
        uint256 _bal = Gem(gem).balanceOf(address(this));

        // Return 0 if the balance is reserved for pending claims
        if (_bal < totalPending) { return 0; }

        // Calculate the balance after pending redemptions
        uint256 _out = _bal - totalPending;

        // Send the remaining balance to the output conduit
        _safeTransferFrom(gem, address(this), flo, _out);

        // Emit settle
        emit Settled(flo, _out);
    }

    // View functions

    function open() external view returns (bool) {
        return Act(act).live();
    }

    function nextOpen() external view returns (uint256) {
        return Act(act).live() ? 0 : Act(act).open();
    }

    function nextHalt() external view returns (uint256) {
        return Act(act).live() ? 0 : Act(act).halt();
    }

    function canPass(address _usr) external view returns (bool) {
        return Cop(cop).pass(_usr);
    }

    function claimDelay() external view returns (uint256) {
        return Act(act).delay();
    }

    // Token overrides for compliance

    function approve(address usr) external override pass returns (bool) {
        return super.approve(usr, type(uint256).max);
    }

    function approve(address usr, uint wad) public override pass returns (bool) {
        return super.approve(usr, wad);
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

    function _safeTransferFrom(address _token, address _from, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transferFrom.selector, _from, _to, _amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MaserrConduit/transfer-failed");
    }
}
