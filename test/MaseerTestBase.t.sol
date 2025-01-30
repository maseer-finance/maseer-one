// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20}        from "forge-std/interfaces/IERC20.sol";

import {MaseerOne}     from "../src/MaseerOne.sol";
import {MaseerPrice}   from "../src/MaseerPrice.sol";
import {MaseerGuard}   from "../src/MaseerGuard.sol";
import {MaseerGate}    from "../src/MaseerGate.sol";
import {MaseerConduit} from "../src/MaseerConduit.sol";
import {MaseerProxy}   from "../src/MaseerProxy.sol";


interface IUSDT {
    function transferFrom(address from, address to, uint256 amount) external; // non-standard
    function transfer(address to, uint256 amount) external; // non-standard
    function owner() external view returns (address);
    function issue(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract MaseerTestBase is Test {

    uint256 public constant WAD = 1e18;

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    string public NAME = "MaseerOne";
    string public SYMBOL = "M1";

    address public pip;
    address public pipProxy;
    address public act;
    address public actProxy;
    address public cop;
    address public copProxy;
    address public flo;
    address public floProxy;

    address public alice;
    address public bob;

    MaseerOne public maseerOne;

    constructor() {
        alice = makeAddr("alice");
        bob   = makeAddr("bob");

        pip = address(new MaseerPrice());
        pipProxy = address(new MaseerProxy(pip));
        act = address(new MaseerGate());
        actProxy = address(new MaseerProxy(act));
        cop = address(new MaseerGuard(USDT));
        copProxy = address(new MaseerProxy(cop));
        flo = address(new MaseerConduit());
        floProxy = address(new MaseerProxy(flo));
    }

    function testUSDTMintHelper() internal {
        _mintUSDT(alice, 1000);
        assertEq(IERC20(USDT).balanceOf(alice), 1000);
    }

    function _mintUSDT(address to, uint256 amount) internal {
        address _owner = IUSDT(USDT).owner();
        uint256 _balance = IUSDT(USDT).balanceOf(to);
        vm.prank(_owner);
        IUSDT(USDT).issue(amount);
        IUSDT(USDT).transfer(to, amount);
        vm.stopPrank();
        assertEq(IUSDT(USDT).balanceOf(to), _balance + amount, "Mint failed");
    }

    function _calculateDomainSeparator(string memory name, uint256 chainid, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            chainid,
            token
        ));
    }
}
