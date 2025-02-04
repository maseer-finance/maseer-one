// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transfer(address usr, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address usr, uint wad) external returns (bool);
    function decimals() external view returns (uint8);
}

interface Cop {
    function pass(address usr) external view returns (bool);
}

interface Pip {
    function read() external view returns (uint256);
}

interface Act {
    function open()   external view returns (uint256);
    function halt()   external view returns (uint256);
    function bpsin()  external view returns (uint256);
    function bpsout() external view returns (uint256);
    function delay()  external view returns (uint256);
    function cap()    external view returns (uint256);
    function live()   external view returns (bool);
}

import {MaseerToken} from "./MaseerToken.sol";

contract MaseerOne is MaseerToken {

    address immutable public gem;  // Purchase token
    address immutable public pip;  // Oracle price feed
    address immutable public act;  // Market timing feed
    address immutable public cop;  // Compliance feed
    address immutable public flo;  // Output conduit

    uint256                      public totalPending;
    mapping (address => uint256) public pendingExit;
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

    error UnauthorizedUser(address usr);
    error TransferToContract();
    error TransferToZeroAddress();
    error MarketClosed();
    error InvalidPrice();
    error ExceedsCap();
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

    modifier pass(address usr_) {
        if (!_canPass(usr_)) revert UnauthorizedUser(usr_);
        _;
    }

    modifier bell() {
        if (!_isLive()) revert MarketClosed();
        _;
    }

    function mint(uint256 amt) external bell pass(msg.sender) returns (uint256 _out) {

        // Oracle price check
        uint256 _unit = _read();

        // Revert if the price is zero
        if (_unit == 0) revert InvalidPrice();

        // Adjust the price for minting
        _unit = _adjustMintPrice(_unit, _bpsin());

        // Assert minimum purchase amount of one unit to avoid dust
        if (amt < _unit) {
            revert DustThreshold(_unit);
        }

        // Calculate the mint amount
        _out = _wdiv(amt, _unit);

        // Revert if the total supply after mint exceeds the cap
        if (totalSupply + _out > _cap()) revert ExceedsCap();

        // Transfer tokens in
        _safeTransferFrom(gem, msg.sender, address(this), amt);

        // Mint the tokens
        _mint(msg.sender, _out);

        // Emit contract event
        emit ContractCreated(msg.sender, _unit, _out);
    }

    function burn(uint256 amt) external bell pass(msg.sender) returns (uint256 _exit) {

        // Oracle price check
        uint256 _unit = _read();

        // Revert if the price is zero
        if (_unit == 0) revert InvalidPrice();

        // Adjust the price for redemption
        _unit = _adjustBurnPrice(_unit, _bpsout());

        // Calculate the redemption amount
        _exit = _wmul(amt, _unit);

        // Add to the total pending redemptions
        totalPending += _exit;

        // Add to the user's pending redemptions
        pendingExit[msg.sender] += _exit;

        // Bump the user's redemption time
        pendingTime[msg.sender] = block.timestamp + _delay();

        // Burn the tokens
        _burn(msg.sender, amt);

        // Emit contract event
        emit ContractRedeemed(msg.sender, _unit, _exit);
    }

    function exit() external pass(msg.sender) returns (uint256 _out) {

        uint256 _time = pendingTime[msg.sender];

        // Check if the claim is past the redemption period
        if (_time > block.timestamp) revert ClaimableAfter(pendingTime[msg.sender]);
        if (_time == 0) revert NoPendingClaim();

        // Check claimable amounts
        uint256 _amt = pendingExit[msg.sender];

        // User can claim the amount owed or current available balance
        _out = _min(_amt, _gemBalance());

        // Decrement the total pending redemptions
        totalPending -= _out;

        // Decrement the user's pending redemptions
        pendingExit[msg.sender] -= _out;

        // Transfer the tokens
        _safeTransfer(gem, msg.sender, _out);

        // Emit claim
        emit ClaimProcessed(msg.sender, _out);
    }

    function settle() external pass(msg.sender) returns (uint256 _out) {

        // Get the gem balance
        uint256 _bal = _gemBalance();

        // Return 0 if the balance is reserved for pending claims
        if (_bal < totalPending) return 0;

        // Calculate the balance after pending redemptions
        _out = _bal - totalPending;

        // Send the remaining balance to the output conduit
        _safeTransfer(gem, flo, _out);

        // Emit settle
        emit Settled(flo, _out);
    }

    // View functions

    function open() external view returns (bool) {
        return _isLive();
    }

    function nextOpen() external view returns (uint256) {
        uint256 _open = Act(act).open();
        return _open >= block.timestamp ? _open : 0;
    }

    function nextHalt() external view returns (uint256) {
        uint256 _halt = Act(act).halt();
        return _halt >= block.timestamp ? _halt : 0;
    }

    function canPass(address usr) external view returns (bool) {
        return _canPass(usr);
    }

    function claimDelay() external view returns (uint256) {
        return _delay();
    }

    function price() external view returns (uint256) {
        return _read();
    }

    function mintPrice() external view returns (uint256) {
        return _adjustMintPrice(_read(), _bpsin());
    }

    function burnPrice() external view returns (uint256) {
        return _adjustBurnPrice(_read(), _bpsout());
    }

    function cap() external view returns (uint256) {
        return _cap();
    }

    function unsettled() external view returns (uint256) {
        return _gemBalance() - totalPending;
    }

    // Token overrides for compliance

    function approve(address usr) external override pass(msg.sender) pass(usr) returns (bool) {
        return super.approve(usr, type(uint256).max);
    }

    function approve(address usr, uint wad) public override pass(msg.sender) pass(usr) returns (bool) {
        return super.approve(usr, wad);
    }

    function transfer(address dst, uint wad) public override pass(msg.sender) pass(dst) returns (bool) {
        if (dst == address(this)) revert TransferToContract();
        return super.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public override pass(msg.sender) pass(src) pass(dst) returns (bool) {
        if (dst == address(this)) revert TransferToContract();
        return super.transferFrom(src, dst, wad);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) public override pass(msg.sender) pass(owner) pass(spender) {
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    // Internal utility functions

    function _canPass(address _usr) internal view returns (bool) {
        return Cop(cop).pass(_usr);
    }

    function _isLive() internal view returns (bool) {
        return Act(act).live();
    }

    function _delay() internal view returns (uint256) {
        return Act(act).delay();
    }

    function _bpsin() internal view returns (uint256) {
        return Act(act).bpsin();
    }

    function _bpsout() internal view returns (uint256) {
        return Act(act).bpsout();
    }

    function _cap() internal view returns (uint256) {
        return Act(act).cap();
    }

    function _read() internal view returns (uint256) {
        return Pip(pip).read();
    }

    function _gemBalance() internal view returns (uint256) {
        return Gem(gem).balanceOf(address(this));
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }

    function _wmul(uint256 x, uint256 y) internal pure returns (uint z) {
        z = ((x * y) + (WAD / 2)) / WAD;
    }

    function _wdiv(uint256 x, uint256 y) internal pure returns (uint z) {
        z = ((x * WAD) + (y / 2)) / y;
    }

    function _adjustMintPrice(uint256 _price, uint256 _bps) internal pure returns (uint256) {
        return (_price * (10_000 + _bps)) / 10_000; // Round up
    }

    function _adjustBurnPrice(uint256 _price, uint256 _bps) internal pure returns (uint256) {
        return (_price * 10_000) / (10_000 + _bps) + 1; // Round down
    }

    function _safeTransfer(address _token, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transfer.selector, _to, _amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MaseerConduit/transfer-failed");
    }

    function _safeTransferFrom(address _token, address _from, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transferFrom.selector, _from, _to, _amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MaseerOne/transfer-failed");
    }
}
