// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MaseerConduit {

    // Slot 0
    mapping (address => uint256) public wards;
    // Slot 1
    mapping (address => uint256) public can;
    // Slot 2
    mapping (address => uint256) public bud;
    // Allocate Slots 3-50
    uint256[48] private __gap;

    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth() {
        require (wards[msg.sender] == 1, "MaseerConduit/not-authorized");
        _;
    }
    function hope(address usr) external auth { can[usr] = 1; }
    function nope(address usr) external auth { can[usr] = 0; }
    modifier operator() {
        require (can[msg.sender] == 1, "MaseerConduit/not-operator");
        _;
    }
    function kiss(address usr) external auth { bud[usr] = 1; }
    function diss(address usr) external auth { bud[usr] = 0; }
    modifier buds(address usr) {
        require (bud[usr] == 1, "MaseerConduit/invalid-address");
        _;
    }

    event Move(
        address indexed token,
        address indexed to,
        uint256 indexed amount
    );

    constructor() {
        wards[msg.sender] = 1;
    }

    function move(address _token, address _to) external operator buds(_to) {
        require(_token != address(0), "MaseerConduit/no-token");
        uint256 _bal = Gem(_token).balanceOf(address(this));
        _safeTransferFrom(_token, address(this), _to, _bal);
        emit Move(_token, _to, _bal);
    }

    function _safeTransferFrom(address token, address _from, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(Gem.transferFrom.selector, _from, _to, _amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MaserrConduit/transfer-failed");
    }
}
