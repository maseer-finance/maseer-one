// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, console}  from "forge-std/Test.sol";
import {IERC20}         from "forge-std/interfaces/IERC20.sol";
import {MockPip}        from "./Mocks/MockPip.sol";
import {MockCop}        from "./Mocks/MockCop.sol";

import {MaseerOne}      from "../src/MaseerOne.sol";
import {MaseerPrice}    from "../src/MaseerPrice.sol";
import {MaseerGuard}    from "../src/MaseerGuard.sol";
import {MaseerGate}     from "../src/MaseerGate.sol";
import {MaseerTreasury} from "../src/MaseerTreasury.sol";
import {MaseerConduit}  from "../src/MaseerConduit.sol";
import {MaseerProxy}    from "../src/MaseerProxy.sol";

import {OFAC}           from "./fixtures/OFAC.sol";


interface IUSDT {
    function transferFrom(address from, address to, uint256 amount) external; // non-standard
    function transfer(address to, uint256 amount) external; // non-standard
    function approve(address spender, uint256 amount) external;
    function owner() external view returns (address);
    function issue(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
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
    address public admImpl;
    address public admProxy;
    address public copImpl;
    address public copProxy;
    address public floImpl;
    address public floProxy;

    MaseerPrice    public pip;
    MaseerGate     public act;
    MaseerTreasury public adm;
    MaseerGuard    public cop;
    MaseerConduit  public flo;

    address public alice;
    address public bob;
    address public carol;
    address public david;
    address public enemy;
    address public issuer;
    address public bank;
    address public pipAuth;
    address public actAuth;
    address public admAuth;
    address public copAuth;
    address public floAuth;
    address public proxyAuth;

    IUSDT  public usdt = IUSDT(USDT);
    IERC20 public weth = IERC20(WETH);
    IERC20 public dai  = IERC20(DAI);

    MaseerOne public maseerOne;
    address   public maseerOneAddr;

    OFAC      public ofac;

    constructor() {

        ofac  = new OFAC();

        alice  = makeAddr("alice");
        bob    = makeAddr("bob");
        carol  = makeAddr("carol");
        david  = makeAddr("david");
        enemy  = ofac.ofac(0);
        issuer = makeAddr("issuer");
        bank   = makeAddr("bank");

        pipAuth = makeAddr("pipAuth");
        actAuth = makeAddr("actAuth");
        admAuth = makeAddr("admAuth");
        copAuth = makeAddr("copAuth");
        floAuth = makeAddr("floAuth");
        proxyAuth = makeAddr("proxyAuth");

        pipImpl = address(new MaseerPrice());
        pip = MaseerPrice(address(new MaseerProxy(pipImpl)));
        pipProxy = address(pip);
        pip.rely(pipAuth);
        pip.deny(address(this));
        MaseerProxy(pipProxy).relyProxy(proxyAuth);
        MaseerProxy(pipProxy).denyProxy(address(this));

        actImpl = address(new MaseerGate());
        act = MaseerGate(address(new MaseerProxy(actImpl)));
        actProxy = address(act);
        act.rely(actAuth);
        act.deny(address(this));
        MaseerProxy(actProxy).relyProxy(proxyAuth);
        MaseerProxy(actProxy).denyProxy(address(this));

        admImpl = address(new MaseerTreasury());
        adm = MaseerTreasury(address(new MaseerProxy(admImpl)));
        admProxy = address(adm);
        adm.rely(admAuth);
        adm.bestow(issuer);
        adm.deny(address(this));
        MaseerProxy(admProxy).relyProxy(proxyAuth);
        MaseerProxy(admProxy).denyProxy(address(this));

        copImpl = address(new MaseerGuard(USDT));
        cop = MaseerGuard(address(new MaseerProxy(copImpl)));
        cop.rely(copAuth);
        cop.deny(address(this));
        copProxy = address(cop);
        // No wards on cop
        MaseerProxy(copProxy).relyProxy(proxyAuth);
        MaseerProxy(copProxy).denyProxy(address(this));

        floImpl = address(new MaseerConduit());
        flo = MaseerConduit(address(new MaseerProxy(floImpl)));
        floProxy = address(flo);
        flo.rely(floAuth);
        flo.deny(address(this));
        MaseerProxy(floProxy).relyProxy(proxyAuth);
        MaseerProxy(floProxy).denyProxy(address(this));

        maseerOne = new MaseerOne(USDT, pipProxy, actProxy, admProxy, copProxy, floProxy, NAME, SYMBOL);
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

    function _bytes32toString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 length = 0;
        while (length < 32 && _bytes32[length] != 0) {
            length++;
        }

        bytes memory bytesArray = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytesArray[i] = _bytes32[i];
        }

        return string(bytesArray);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }

    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (WAD / 2)) / WAD;
    }

    function _wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * WAD) + (y / 2)) / y;
    }
}
