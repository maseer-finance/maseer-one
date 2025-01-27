// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {MaseerToken} from "./MaseerToken.sol";

contract MaseerOne is MaseerToken {

    constructor(
        string memory name_,
        string memory symbol_
    ) MaseerToken(name_, symbol_) {

    }

    function mint(uint256 amt) external {
        // TODO: Check if the mint is allowed

        // TODO: Oracle price check

        // TODO: Mint the tokens

        // TODO: Emit contract event
    }

    function redeem(uint256 amt) external {
        // TODO: Check if the burn is allowed

        // TODO: Oracle price check

        // TODO: Add user to the pending redemptions

        // TODO: Burn the tokens

        // TODO: Emit contract event

    }

    function claim() external {
        // TODO: check if the claim is allowed

        // TODO: Check claimable amount

        // TODO: Check internal balance

        // TODO: Decrement the pending redemptions

        // TODO: Transfer the tokens

        // TODO: Emit claim

    }


    // Token overrides for compliance

    function approve(address guy) external override returns (bool) {
        // TODO: Check if the approval is allowed
        return super.approve(guy, type(uint256).max);
    }

    function approve(address guy, uint wad) public override returns (bool) {
        // TODO: Check if the approval is allowed
        return super.approve(guy, wad);
    }

    function transfer(address dst, uint wad) external override returns (bool) {
        // TODO: Check if the transfer is allowed
        return super.transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public override returns (bool) {
        // TODO: Check if the transfer is allowed
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
    ) public override {
        // TODO: Check if the transfer is allowed
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    // TODO: Oracle price
    // TODO: Redemption period
    // TODO: Output conduit
    // TODO: Pending redemption count

}
