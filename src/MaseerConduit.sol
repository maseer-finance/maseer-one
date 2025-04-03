// SPDX-License-Identifier: BUSL-1.1
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
    error InvalidAddress(address);
    error NotOperator(address);

    function hope(address usr) external auth { can[usr] = 1; }
    function nope(address usr) external auth { can[usr] = 0; }
    modifier operator() {
        if (can[msg.sender] != 1) revert NotOperator(msg.sender);
        _;
    }
    function kiss(address usr) external auth { bud[usr] = 1; }
    function diss(address usr) external auth { bud[usr] = 0; }
    modifier buds(address usr) {
        if (bud[usr] != 1) revert InvalidAddress(usr);
        _;
    }

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
