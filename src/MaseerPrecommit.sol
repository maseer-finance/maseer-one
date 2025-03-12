// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface Gem {
    function transfer(address usr, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
    function approve(address usr, uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address src, address dst) external view returns (uint256);
}

interface One {
    function gem() external view returns (address);
    function mint(uint256 wad) external returns (uint256);
    function canPass(address usr) external view returns (bool);
}

contract MaseerPrecommit {

    address public immutable gem;
    address public immutable one;

    uint256                        public commits;
    mapping (uint256 => Precommit) public commit;

    struct Precommit {
        address usr;
        uint256 amt;
    }

    error TransferFailed();
    error InsufficientAllowance();
    error InsufficientAmount();
    error NotAuthorized();

    constructor(address _one) {
        gem = One(_one).gem();
        one = _one;
        Gem(gem).approve(_one, type(uint256).max);
    }

    function precommit(uint256 _amt) external {
        if (_amt == 0) revert InsufficientAmount();
        if (Gem(gem).allowance(msg.sender, address(this)) < _amt) revert InsufficientAllowance();
        if (!One(one).canPass(msg.sender)) revert NotAuthorized();

        commit[commits++] = Precommit({
            usr: msg.sender,
            amt: _amt
        });
    }

    function exec(uint256 _idx) external {
        Precommit memory c = commit[_idx];
        if (c.amt == 0) revert InsufficientAmount();
        commit[_idx].amt = 0;

        _safeTransferFrom(gem, c.usr, address(this), c.amt);
        uint256 out = One(one).mint(c.amt);
        _safeTransfer(one, c.usr, out);
    }

    function amt(uint256 _idx) external view returns (uint256) {
        return commit[_idx].amt;
    }

    function usr(uint256 _idx) external view returns (address) {
        return commit[_idx].usr;
    }

    function _safeTransfer(address _token, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transfer.selector, _to, _amt));
        if (!success || (data.length > 0 && abi.decode(data, (bool)) == false)) revert TransferFailed();
    }

    function _safeTransferFrom(address _token, address _from, address _to, uint256 _amt) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(Gem.transferFrom.selector, _from, _to, _amt));
        if (!success || (data.length > 0 && abi.decode(data, (bool)) == false)) revert TransferFailed();
    }
}
