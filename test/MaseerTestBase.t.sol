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
    function approve(address spender, uint256 amount) external;
    function owner() external view returns (address);
    function issue(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract MaseerTestBase is Test {

    uint256 public constant WAD = 1e18;

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    string public NAME = "MaseerOne";
    string public SYMBOL = "M1";

    address public pipImpl;
    address public pipProxy;
    address public actImpl;
    address public actProxy;
    address public copImpl;
    address public copProxy;
    address public floImpl;
    address public floProxy;

    MaseerPrice   public pip;
    MaseerGate    public act;
    MaseerGuard   public cop;
    MaseerConduit public flo;

    address public alice;
    address public bob;
    address public carol;
    address public david;

    IUSDT  public usdt = IUSDT(USDT);
    IERC20 public weth = IERC20(WETH);
    IERC20 public dai  = IERC20(DAI);

    MaseerOne public maseerOne;
    address   public maseerOneAddr;

    constructor() {
        alice = makeAddr("alice");
        bob   = makeAddr("bob");
        carol = makeAddr("carol");
        david = makeAddr("david");

        pipImpl = address(new MaseerPrice());
        pip = MaseerPrice(address(new MaseerProxy(pipImpl)));
        pipProxy = address(pip);

        actImpl = address(new MaseerGate());
        act = MaseerGate(address(new MaseerProxy(actImpl)));
        actProxy = address(act);

        copImpl = address(new MaseerGuard(USDT));
        cop = MaseerGuard(address(new MaseerProxy(copImpl)));
        copProxy = address(cop);

        floImpl = address(new MaseerConduit());
        flo = MaseerConduit(address(new MaseerProxy(floImpl)));
        floProxy = address(flo);

        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, copProxy, floProxy, NAME, SYMBOL);
        maseerOneAddr = address(maseerOne);
    }

    function testUSDTMintHelper() internal {
        _mintUSDT(alice, 1000);
        assertEq(usdt.balanceOf(alice), 1000);
    }

    function _mintTokens(address to, uint256 amount) internal {
        uint256 _bal = maseerOne.balanceOf(to);
        uint256 _tot = maseerOne.totalSupply();
        deal(address(maseerOne), to, amount, true);
        assertEq(maseerOne.balanceOf(to), _bal + amount, "Mint failed - balance");
        assertEq(maseerOne.totalSupply(), _tot + amount, "Mint failed - totalSupply");
    }

    function _mintUSDT(address to, uint256 amount) internal {
        address _owner = usdt.owner();
        uint256 _balance = usdt.balanceOf(to);

        vm.prank(_owner);
        usdt.issue(amount);
        vm.prank(_owner);
        usdt.transfer(to, amount);

        assertEq(usdt.balanceOf(to), _balance + amount, "Mint failed");
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
